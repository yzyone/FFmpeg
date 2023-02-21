# 使用ffmpeg实现管道输入输出，并连接在代码中

这次记录的问题比较复杂。
`cat test.flv | ffmpeg -i pipe:0 -c copy -f flv - > test2.flv`

上面这条命令可以看懂吧，就是将test.flv，没有进行任何操作，保存到了test2.flv中。不明白的话，跳到最后的知识扩展中，有解释。
然后，我要做的就是在代码中完成前后的操作，即自己读文件，送入ffmpeg，再从ffmpeg中读到输出。

这样做的目的是，我可以自由控制使用ffmpeg处理某些过程，而不是全部过程。

示例代码思路

下面提供代码是我用来测试使用方法是否正确的，所以质量很差。我最终用到的是我们项目上的一套系统代码中的一个单独的节点。只提供单一的节点，没有框架，是无法运行的。所以，这里就只提供一个质量不好的例子了。

因为我们要对接ffmpeg的输入与输出，并不是像system使用的命令那样，执行完就完了。所以我们使用了exec族中的命令，加上fork函数，我们就可以给ffmpeg单独一个输入输出的进程。最后，只要将这个进程的输入输出拿到我们的程序中就行了。

在对接管道的时候，我们使用pipe先建立管道，然后接上ffmpeg的输入输出，就可以把输入输出拿出来了。

整个实现上，父进程负责读文件，向管道pointer_to_sub中去写，子进程提前将pointer_to_sub输出接到标准输入上，这样运行的ffmpeg将接收到数据，并且将标准输出接到管道pointer_to_main上，返回给父进程数据。最后，父进程保存pointer_to_main回来的结果即可。

示例代码

```
#include <unistd.h>
#include <stdlib.h>
#include <sys/time.h>
#include <thread>
#include <string.h>
#include <stdio.h>

std::thread gPipeThd;

void fun()
{
	int pointer_to_main[2];
	int pointer_to_sub[2];
	char buf[PIPE_BUF + 1];
	pid_t pid;

	int bytes_read2 = 0;
	int write_fd = -1;
	char buffer[PIPE_BUF + 1];
	int bytes_sent = 0;
	
	int s1 = pipe(pointer_to_main);
	int s2 = pipe(pointer_to_sub);
	
	gPipeThd = std::thread([pointer_to_sub]() {
		char buffer[PIPE_BUF + 1];
		int bytes_read = 0;
		int data_fd = -1;
		int res = 0;
	
		data_fd = open("/mnt/media/test.flv", O_RDONLY);
	
		if (data_fd == -1)
			return;
	
		bytes_read = read(data_fd, buffer, PIPE_BUF);
		buffer[bytes_read] = '\0';
		while (bytes_read > 0)
		{
			res = write(pointer_to_sub[1], buffer, bytes_read);
			if (res == -1)
			{
				fprintf(stderr, "Write error on pipe\n");
				exit(EXIT_FAILURE);
			}
	
			//bytes_sent += res;
			bytes_read = read(data_fd, buffer, PIPE_BUF);
			buffer[bytes_read] = '\0';
		}
	});
	
	pid = fork();
	if (pid > 0)
	{
		close(pointer_to_sub[0]);
		close(pointer_to_main[1]);
	
		write_fd = open("./1.flv", O_WRONLY | O_CREAT);
		fcntl(pointer_to_main[0], F_SETFL, FNDELAY);
	
		unsigned long long i = 0;
	
		while (write_fd != -1 && waitpid(pid, NULL, WNOHANG) == 0)
		{
			auto tt = new char[5096];
			int ss = read(pointer_to_main[0], buf, sizeof(buf));
			if (ss > 0)
				write(write_fd, buf, ss);
			else
			{
				i++;
			}
			delete[] tt;
		}
	
		close(pointer_to_sub[1]);
		close(pointer_to_main[0]);
	}
	else if (pid == 0)
	{
		sleep(1);
		close(pointer_to_sub[1]);
		close(pointer_to_main[0]);
	
		dup2(pointer_to_sub[0], STDIN_FILENO);
		dup2(pointer_to_main[1], STDOUT_FILENO);
	
		execl("/usr/bin/ffmpeg", "ffmpeg", "-re", "-i", "pipe:0", "-vcodec", "copy", "-an", "-f", "flv", "-", NULL);
		close(pointer_to_sub[0]);
		close(pointer_to_main[1]);
	}
	
	waitpid(pid, NULL, 0);
	if (gPipeThd.joinable())
		gPipeThd,join();
}

int main()
{
	fun();
	return 0;
}
```
代码详解
创建两个管道
pipe函数可以建立管道，pointer_to_main和pointer_to_sub是管道本身，里面的值代表是接口的标识符。0是读端口，1是写端口，即从0取数据，向1写数据。pointer_to_main表示管道里的数据是准备给父进程的，pointer_to_sub相反。

```
	int pointer_to_main[2];
	int pointer_to_sub[2];

	int s1 = pipe(pointer_to_main);
	int s2 = pipe(pointer_to_sub);
```

独立的线程对视频文件进行一个读入
读到数据，通过write写入到pointer_to_sub中。

```
gPipeThd = std::thread([pointer_to_sub]() {
		char buffer[PIPE_BUF + 1];
		int bytes_read = 0;
		int data_fd = -1;
		int res = 0;

		data_fd = open("/mnt/media/test.flv", O_RDONLY);
	
		if (data_fd == -1)
			return;
	
		bytes_read = read(data_fd, buffer, PIPE_BUF);
		buffer[bytes_read] = '\0';
		while (bytes_read > 0)
		{
			res = write(pointer_to_sub[1], buffer, bytes_read);
			if (res == -1)
			{
				fprintf(stderr, "Write error on pipe\n");
				exit(EXIT_FAILURE);
			}
	
			//bytes_sent += res;
			bytes_read = read(data_fd, buffer, PIPE_BUF);
			buffer[bytes_read] = '\0';
		}
	
	});
```
分离线程
使用fork函数，复制一个新的线程出来，该线程保持有之前的所有数据，并独立为另外一个进程。新的进程为子进程，在子进程中fork的返回值是0，在父进程中，fork的返回值是子进程的进程id。可在父进程中kill掉他。
pid=fork();
1
将子进程转为ffmpeg进程
因为在子进程中，我们的任务只是从pointer_to_sub中读数据，向pointer_to_main中写数据。（等同于不需要向pointer_to_sub中写数据，从pointer_to_main中读数据）所以，我们可以将另外两个使用close关掉。
接着，将pointer_to_sub接到标准输入上，pointer_to_main接到标准输出上。如果你不清楚dup2该如何使用，可以跳到知识拓展中看一下，这个有点难理解，我也是查了许多，才自己摸索出来的。
最后，直接通过execl启动ffmpeg即可。关于exec也可以看后面的知识扩展
其实最后面的两行代码完全不会执行的。嘻嘻。

```
	else if (pid == 0)
	{
		sleep(1);
		close(pointer_to_sub[1]);
		close(pointer_to_main[0]);

		dup2(pointer_to_sub[0], STDIN_FILENO);
		dup2(pointer_to_main[1], STDOUT_FILENO);
	
		execl("/usr/bin/ffmpeg", "ffmpeg", "-re", "-i", "pipe:0", "-vcodec", "copy", "-an", "-f", "flv", "-", NULL);
		close(pointer_to_sub[0]);
		close(pointer_to_main[1]);
	}
	
	waitpid(pid, NULL, 0);
	if (gPipeThd.joinable())
		gPipeThd,join();
}
```
在主线程中读出数据，保存在文件中
fcntl(pointer_to_main[0], F_SETFL, FNDELAY)，可以让对pointer_to_main[0]管道口操作的不阻塞，即后面的read函数不阻塞。不过，我这个例子中是可以不加这一行的，后来写的程序中需要有，我在这做测试来着。
waitpid(pid, NULL, WNOHANG) 保证上面的线程还在运行中，相当于设置了一个跳出条件，虽然并不是很恰当，因为这是有时间差的。
后面就没什么了，从pointer_to_main[0]中读到数据，保存到文件里。

```
if (pid > 0)
	{
		close(pointer_to_sub[0]);
		close(pointer_to_main[1]);

		write_fd = open("./1.flv", O_WRONLY | O_CREAT);
		fcntl(pointer_to_main[0], F_SETFL, FNDELAY);
	
		while (write_fd != -1 && waitpid(pid, NULL, WNOHANG) == 0)
		{
			auto tt = new char[5096];
			int ss = read(pointer_to_main[0], buf, sizeof(buf));
			if (ss > 0)
				write(write_fd, buf, ss);
			delete[] tt;
		}
	
		close(pointer_to_sub[1]);
		close(pointer_to_main[0]);
	}
```
知识扩展
shell控制台输出

控制台输入的字符，都会进入标准输入流（标识符是0），显示的字符都经过标准输出流（标识符是1）显示出来。| 操作会连接两个指令，先运行前面的命令，同时，把标准输入接到后面要运行指令上，形成连贯的流水线。最后的 > 是将整体的末尾的标准输出，重定向到文件中。去掉这里的话，就直接显示在控制台了。

sup2的使用

dup2(pointer_to_sub[0], STDIN_FILENO) 目的是将pointer_to_sub输出，给到标准输入上，可以想象为一个向右的箭头。这很容易理解，但是这么理解就错了，我就踩到这个坑了。

dup2(pointer_to_main[1], STDOUT_FILENO) 这一行按照上面的说法就与我们的目的不符了，但是这是正确的。其实这里的连接还隐藏着另外一个功能——dup2(newId, oldId)会先将oldId关掉，然后和newId的口紧紧连在一起。就像oldId是连在别的管道中的，要先拧下来，再接到进的管道口才行。

exec族函数

exec族包括好多个函数的，也比较好搜。我用的这种其实不是很方便，自己写代码的话，可以换一下别的。（我后来也换了别的，更灵活了）

————————————————

版权声明：本文为CSDN博主「xiaonuo911teamo」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/xiaonuo911teamo/article/details/109409908