
# VS2019+msys2编译ffmpeg #

因项目需要，最近在学习音视频相关开发技术。第一步是搭建开发环境，通过参考网上查到的资料结合实际情况，最终将ffmpeg编译通过，并支持x264、x265、fdk-aac。在这里将具体的操作过程记录下来，方便以后参考。

**1、下载VS2019社区版本、下载msys64位版本的可执行文件进行安装。**

    https://www.msys2.org msys2官网
    https://visualstudio.microsoft.com/zh-hans/downloads/ VS2019下载地址

**2、通过vs2019的x86 Native Tools 命令行工具打开msys2，并继承命令行工具的环境变量**

用文本编辑器打开 msys2安装根目录下的msys2_shell.cmd ，将
rem set MSYS2_PATH_TYPE=inherit
改为set MSYS2_PATH_TYPE=inherit，即去掉行首的rem字符并保存。

打开x86 Native Tools 命令行工具，cd到msys2安装根目录下，执行命令
msys2_shell.cmd -mingw32 打开一个mingw32终端，这时候输入cl会有正常提示信息,如果是乱码则将options里的语言设置为GBK即可。

**3、配置编译环境**

安装之前，先替换安装包的源地址，打开msys2的安装目录进入/etc/pacman.d/文件夹下配置3个文件（mirrorlist.mingw32、mirrorlist.mingw64、mirrorlist.msys）

    在mirrorlist.mingw32文件最前面增加：
    Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/i686
    在mirrorlist.mingw64文件最前面增加：
    Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/x86_64
    在mirrorlist.msys文件最前面增加：
    Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/$arch

依次执行下面的命令更新环境

    pacman -S nasm #汇编工具,安装
    pacman -S yasm #汇编工具,安装
    pacman -S make #项目编译工具,必须安装 
    pacman -S cmake #项目编译工具,必须安装 
    pacman -S diffutils #比较工具,ffmpeg configure 生成makefile时会用到,若不安装会警告,最好是安装 
    pacman -S pkg-config #库配置工具,编译支持x264和x265用到 pacman -S git #下载源码用,可以不安装,可自行通过其它方式下载源码
    pacman -S base-devel # 安装基本开发组件
    pacman -S binutils #包含ld等命令

**4、下载并编译x264**

在msys根目录的home目录下新建xsrc目录，使用git下载源码达到本地。在msys2命令行中输入下面的命令克隆代码。

    git clone https://code.videolan.org/videolan/x264.git

下载完成后，cd到x264目录下，执行命令

    CC=cl ./configure --enable-shared

生成makefile 文件

输入命令

    make

等待编译，编译完成后输入命令

    make install

默认安装到msys2根目录的 usr/local 目录下

**5、下载并编译x265**

在xsrc 下执行命令

    git clone https://github.com/videolan/x265.git

下载完成后关闭所有命令行窗口，重新以管理员身份运行x86 Native Tools 命令行工具，打开msys2命令行，cd到x265目录下执行编译命令

    ./make-Makefiles.sh

编译完成后执行安装命令

    nmake install

该命令默认将x265安装到 C:/Program Files (x86)/目录下。将该目录x265中的bin、lib、include 目录拷贝到msys2根目录的usr/local/对应的目录下，并修改lib/pkgconfig 中的 x265.pc，将第一行的prefix路径改为prefix=/usr/local

**6、下载并编译fdk-aac**

在xsrc 下执行命令

    git clone https://github.com/mstorsjo/fdk-aac.git

cd到fdk-aac源码文件夹 ，执行文件autogen.sh

    ./autogen.sh

执行命令生成makefile

    ./configure --enable-shared --enable-static

编译 `make -j6`

安装 `make install`

默认安装到mingw32目录下，将对应的bin、lib、include目录拷贝到/usr/local对应目录下，并修改fdk-aac.pc，将第一行的prefix路径改为prefix=/usr/local。

**7、下载并编译ffmpeg**

在xsrc 下执行命令

    git clone https://github.com/FFmpeg/FFmpeg.git

cd到FFmpeg源码文件夹 ，新建install目录，后面执行make install时，会将生成的库安装到这个目录下。

执行命令，生成makefile文件 

    CC=cl.exe ./configure --prefix=./install --toolchain=msvc --enable-shared --enable-libx264 --enable-gpl --enable-libfdk-aac --enable-nonfree --enable-libx265

./configure -h 可以查看每个配置项的具体含义。这里

    --prefix=./install --toolchain=msvc

//指定安装路径和工具链MSVC --enable-shared //编译为动态库 --enable-libx264 --enable-libx265

//启用支持x264和x265,,解码h264和265会需要用到 --enable-gpl //开启协议,x264,x265必需 --enable-libfdk-aac --enable-nonfree

//aac音频编码,aac必须启用nonfree

如果一切顺利接下来执行 make 开始编译

编译结束后 执行 make install 将生成的文件和依赖安装到install目录下。

**在 ./configure 阶段可能遇到的问题**

a)libx264.lib找不到，这是因为生成的x264库默认命名为libx264.dll.lib，将其改为libx264.lib可解决这个问题。

b)fdk-aac 库文件找不到，这里有两个方法，一个是将/usr/local/lib 目录下的pkgconfig目录移动到mingw32/lib目录下；另一个是将/usr/local/lib/pkgconfig 设置到环境变量中，export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig":$PKG_CONFIG_PATH

c)ERROR: x265 not found using pkg-config
将libx265.lib 改名为x265.lib后配置成功。

总结：

编译ffmpeg时会遇到各种奇奇怪怪的问题，但是只要静下心来慢慢的看日志，查资料总能把问题解决，有志者事竟成，加油！！！。

---

作者：北极星的笔记

链接：https://www.jianshu.com/p/74e4e763ea6e

来源：简书

著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。