# FFmpeg之Pipe：让FFmpeg和Python相得益彰



## 前言

为了把处理完的视频帧写入视频真是让我挠破了头，cv2.VideoWriter没法选择编码器（只能选编码），PyAV没法设置vtag和许多FFmpeg的可用参数。偶然间看到了FFmpeg还有Pipe这种神奇的通信方式，那就赶紧开始吧。

## 正文

可以去看一下我GitHub上完整的代码示例[iBobbyTS/FFmpeg-Pipe-Python](https://github.com/iBobbyTS/FFmpeg-Pipe-Python)。此篇博文只是对关键步骤进行详解，完整脚本以GitHub上的为准

## 读取

1.先定义好命令
command = ['ffmpeg', '-i', 'in_v.mov', '-f', 'rawvideo', '-pix_fmt', 'bgr24', '-']
输出格式-f/-format需要是rawvideo，即完整的RGB或YUV信息；-pix_fmt像素格式为bgr24，可以被转换为numpy.uint8，看自己需求通道顺序，rgb24也可以；输出是-代表管道。

2.通过pipe = subprocess.Popen(command, stdout=sp.PIPE, bufsize=10 ** 8)打开管道，后两个参数不要动。

3.读取brg数据
raw_image = pipe.stdout.read(width * height * 3)
width和height事先定义好，分别是宽和高，*3代表三个通道。需要读取那么多字节

4.转换成NumPy数组
image = numpy.frombuffer(raw_image, dtype='uint8')用NumPy从字节数据里读取数字并返回numpy.uint8类型的数组。旧的numpy.fromstring官方不建议使用，应使用新的numpy.frombuffer。
重复3、4步直到raw_image为空。

5.关闭管道
pipe.terminate()
关闭后FFmpeg会把缓存里的数据释放到视频文件，python脚本结束运行会自动关闭，但管道一直开着，占用系统资源。

## 写入

1.同样先定义命令
command = ['ffmpeg', '-f', 'rawvideo', '-s', '%dx%d' % (width, height), '-pix_fmt', 'bgr24', '-r', '60', '-i', '-', '-c:v', 'libx265', '-pix_fmt', 'yuv420p', 'out_v.mp4']
width和height事先定义好。
我们要从管道里输入的是完整的rgb数据，故设置格式为rawvideo（有些地方另外设置了-c:v rawvideo，我测试的时候没有设没出问题，因为-f rawvideo已经限定编码只能是rawvideo了）；rawvideo是只有颜色数据的，所以需要指定宽高；像素格式是bgr24，如果处理完的图像颜色通道是rgb那就是rgb24；用-r指定输入图像序列的帧率，-i -表示输入是管道。
接下来是输出选项，我想要用libx265编码器，yuv420p像素格式。

2.打开管道
pipe = sp.Popen(command, stdin=sp.PIPE, stderr=sp.PIPE)
同样后两参数不要管，第一个是命令。

3.写入帧
pipe.stdin.write(img.tobytes())
img是前面处理完的图像，形状是(高, 宽, 通道)，如(2160, 3840, 3)。使用NumPy里ndarray的tobytes方法把数组转成二进制数据，送进管道。

4.关闭管道
pipe.terminate()
关闭后FFmpeg会把缓存里的数据释放到视频文件，python脚本结束运行会自动关闭，但管道一直开着，占用系统资源。

## 参考资料

[python ffmpeg pipe交互](https://blog.csdn.net/zuicong5568/article/details/78952195)
[Read and Write Video Frames in Python Using FFMPEG](http://zulko.github.io/blog/2013/09/27/read-and-write-video-frames-in-python-using-ffmpeg/)

————————————————

版权声明：本文为CSDN博主「iBobbyTS」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/iBobbyTS/article/details/113818943