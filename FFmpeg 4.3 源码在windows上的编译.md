# FFmpeg 4.3 源码在windows上的编译

[夏曹俊]于 2021-01-03 21:35:27 

[FFmpeg](https://so.csdn.net/so/search?q=FFmpeg&spm=1001.2101.3001.7020)开发环境准备

**学习目标**

  学会配置vs2019+msys2 编译环境

  学会编译x264、x265、fdk-aac、sdl、ffmpeg4.3

**编译目的：**

  获取pdb文件，调试能进入ffmpeg[源码](https://so.csdn.net/so/search?q=源码&spm=1001.2101.3001.7020)


**菜单运行vs2019编译控制台**

使用cl编译源码

**msys2 安装**

修改msys2_shell.[cmd](https://so.csdn.net/so/search?q=cmd&spm=1001.2101.3001.7020) 支持外部环境变量

修改 msys2_shell.cmd 去掉 rem set MSYS2_PATH_TYPE=inherit中的rem 表示去掉注释标记 让msys支持外部[环境变量](https://so.csdn.net/so/search?q=环境变量&spm=1001.2101.3001.7020)，主要为了支持vs2019的编译环境

**msys2 依赖环境安装**

\# 安装的汇编工具 编译x264 和ffmpeg用到，如果不安装，在config是要禁用汇编

```
pacman -S nasm

pacman -S yasm

pacman -S make # 项目编译工具，必须要安装
```

cmake  安装windows版本配置环境变量

```
pacman -S diffutils # 比较工具，ffmpeg configure生成makefile时用到

pacman -S pkg-config # 库配置工具，编译支持x264 和 x265用到

pacman -S git # 从版本库下载源码用到
```


**msys2 依赖环境安装 网络问题**

替换源

`G:\msys64\etc\pacman.d`

**vs2019 编译X264**

用于h264 AVC 视频格式编码

```
CC=cl ./configure --enable-shared

make -j32

make install
```

生成 pkg-config

**vs2019 编译 fdk-aac**

AAC格式音频编码

```
nmake -f Makefile.vc

nmake -f Makefile.vc prefix=.\install install
```

**vs2019 编译x265**

不用msys2 的cmake  命令查看：where cmake

进入目录 x265\build\msys-cl

```
make-Makefiles.sh

nmake install
```


**vs2019 ffmpeg编译**

```
CC=cl.exe ./configure --prefix=./install  \
	--toolchain=msvc --enable-shared --disable-programs --disable-ffplay  \
	--disable-ffmpeg --disable-ffprobe  --enable-libx264 --enable-gpl \
	--enable-libfdk-aac --enable-nonfree --enable-libx265
```


--prefix=./install  --toolchain=msvc #指定安装路径和工具链vs

--enable-shared #编译为动态链接库

\# 不编译工具

--disable-programs --disable-ffplay  --disable-ffmpeg --disable-ffprobe

 --enable-libx264 --enable-libx265  #支持x264 和 x265

--enable-gpl # 支持x264协议，x264 和 x265必备

--enable-libfdk-aac --enable-nonfree # aac音频编码 aac必须包含-enable-nonfree

 

**第一个vs2019 ffmpeg项目**

头文件 include

库文件 lib lib/x86 x64

动态库文件dll bin/x86 x64

调试执行和pdb路径 bin/x86 x64

源码项目路径 src/first_ffmpeg


```
#include <iostream>

using namespace std;

extern "C"{ //指定函数是c语言函数，函数名不包含重载标注

//引用ffmpeg头文件

#include <libavcodec/avcodec.h>

}

//预处理指令导入库

#pragma comment(lib,"avcodec.lib")

 

int main(int argc, char* argv[])

{

  cout << "first ffmpeg" << endl;

  cout << avcodec_configuration() << endl;

  return 0;

}
```