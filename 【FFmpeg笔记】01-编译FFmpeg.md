# 【FFmpeg笔记】01-编译FFmpeg #

[FFmpeg开发](https://blog.csdn.net/eieihihi/category_7002653.html)

同时被 2 个专栏收录

5 篇文章1 订阅

已订阅

Android开发

25 篇文章0 订阅

订阅专栏
.

- 一、创建工作目录
- 二、安装git工具
- 三、下载ffmepg源码
- 四、安装NDK
- 五、ffmpeg编译配置
- 六、开始编译
- 七、查看编译结果

**所需材料**

- ubuntu_16.04
- android-ndk-r14b
- ffmpeg 源码

## 一、创建工作目录 ##

我是在桌面创建的 develop 目录。

    bassy@ubuntu:~/Desktop$ mkdir develop
    bassy@ubuntu:~/Desktop$ cd develop
    bassy@ubuntu:~/Desktop/develop$ 

## 二、安装git工具 ##

安装 git，用来下载 ffmepg 源码。

```
bassy@ubuntu:~/Desktop/develop$ sudo apt-get install git
Reading package lists... Done
Building dependency tree       
Reading state information... Done
...
```

## 三、下载ffmepg源码 ##

进入工作目录 develop，使用 git 下载 ffmepg 源码。

```
bassy@ubuntu:~/Desktop/develop$ git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
Cloning into 'ffmpeg'...
remote: Counting objects: 516515, done.
remote: Compressing objects: 100% (114032/114032), done.
^Cceiving objects:   6% (34752/516515), 8.20 MiB | 141.00 KiB/s  
```

当然，如果你觉得下载太慢的话，可以去官网使用迅雷等工具下载，然后解压出来。

下载完成后，如下：

```
bassy@ubuntu:~/Desktop/develop$ cd ffmpeg/
bassy@ubuntu:~/Desktop/develop/ffmpeg$ ll
total 1584
drwxrwxrwx 18 bassy bassy   4096 Jun  6 10:27 ./
drwxrwxr-x  3 bassy bassy   4096 Jun  7 08:08 ../
-rwxrw-rw-  1 bassy bassy  56143 Jun  6 10:26 Changelog*
-rwxrw-rw-  1 bassy bassy  73279 Jun  6 10:26 cmdutils.c*
-rwxrw-rw-  1 bassy bassy  24505 Jun  6 10:26 cmdutils.h*
-rwxrw-rw-  1 bassy bassy  10627 Jun  6 10:26 cmdutils_opencl.c*
drwxrwxrwx 13 bassy bassy   4096 Jun  6 10:26 compat/
-rwxrw-rw-  1 bassy bassy 228905 Jun  6 10:26 configure*
-rwxrw-rw-  1 bassy bassy    418 Jun  6 10:26 CONTRIBUTING.md*
-rwxrw-rw-  1 bassy bassy  18092 Jun  6 10:26 COPYING.GPLv2*
-rwxrw-rw-  1 bassy bassy  35147 Jun  6 10:26 COPYING.GPLv3*
-rwxrw-rw-  1 bassy bassy  26526 Jun  6 10:26 COPYING.LGPLv2.1*
-rwxrw-rw-  1 bassy bassy   7651 Jun  6 10:26 COPYING.LGPLv3*
-rwxrw-rw-  1 bassy bassy    274 Jun  6 10:26 CREDITS*
drwxrwxrwx  4 bassy bassy   4096 Jun  6 10:26 doc/
drwxrwxrwx  2 bassy bassy   4096 Jun  6 10:26 ffbuild/
-rwxrw-rw-  1 bassy bassy 169685 Jun  6 10:26 ffmpeg.c*
-rwxrw-rw-  1 bassy bassy   2412 Jun  6 10:26 ffmpeg_cuvid.c*
-rwxrw-rw-  1 bassy bassy  15057 Jun  6 10:26 ffmpeg_dxva2.c*
-rwxrw-rw-  1 bassy bassy  44795 Jun  6 10:26 ffmpeg_filter.c*
-rwxrw-rw-  1 bassy bassy  19841 Jun  6 10:26 ffmpeg.h*
-rwxrw-rw-  1 bassy bassy 148299 Jun  6 10:26 ffmpeg_opt.c*
-rwxrw-rw-  1 bassy bassy   3064 Jun  6 10:26 ffmpeg_qsv.c*
-rwxrw-rw-  1 bassy bassy   6720 Jun  6 10:26 ffmpeg_vaapi.c*
-rwxrw-rw-  1 bassy bassy   4469 Jun  6 10:26 ffmpeg_vdpau.c*
-rwxrw-rw-  1 bassy bassy   6642 Jun  6 10:26 ffmpeg_videotoolbox.c*
-rwxrw-rw-  1 bassy bassy 132011 Jun  6 10:26 ffplay.c*
-rwxrw-rw-  1 bassy bassy 134506 Jun  6 10:26 ffprobe.c*
-rwxrw-rw-  1 bassy bassy 128352 Jun  6 10:26 ffserver.c*
-rwxrw-rw-  1 bassy bassy  51173 Jun  6 10:26 ffserver_config.c*
-rwxrw-rw-  1 bassy bassy   5814 Jun  6 10:26 ffserver_config.h*
drwxrwxrwx  7 bassy bassy   4096 Jun  6 10:27 .git/
-rwxrw-rw-  1 bassy bassy     50 Jun  6 10:26 .gitattributes*
-rwxrw-rw-  1 bassy bassy    279 Jun  6 10:26 .gitignore*
-rwxrw-rw-  1 bassy bassy    595 Jun  6 10:26 INSTALL.md*
drwxrwxrwx 14 bassy bassy  49152 Jun  6 10:26 libavcodec/
drwxrwxrwx  3 bassy bassy   4096 Jun  6 10:26 libavdevice/
drwxrwxrwx  4 bassy bassy  16384 Jun  6 10:26 libavfilter/
drwxrwxrwx  3 bassy bassy  20480 Jun  6 10:26 libavformat/
drwxrwxrwx  6 bassy bassy   4096 Jun  6 10:26 libavresample/
drwxrwxrwx 12 bassy bassy   4096 Jun  6 10:26 libavutil/
drwxrwxrwx  2 bassy bassy   4096 Jun  6 10:26 libpostproc/
drwxrwxrwx  6 bassy bassy   4096 Jun  6 10:26 libswresample/
drwxrwxrwx  7 bassy bassy   4096 Jun  6 10:26 libswscale/
-rwxrw-rw-  1 bassy bassy   4368 Jun  6 10:26 LICENSE.md*
-rwxrw-rw-  1 bassy bassy  28407 Jun  6 10:26 MAINTAINERS*
-rwxrw-rw-  1 bassy bassy   7142 Jun  6 10:26 Makefile*
drwxrwxrwx  2 bassy bassy   4096 Jun  6 10:26 presets/
-rwxrw-rw-  1 bassy bassy   1893 Jun  6 10:26 README.md*
-rwxrw-rw-  1 bassy bassy      8 Jun  6 10:26 RELEASE*
drwxrwxrwx  7 bassy bassy   4096 Jun  6 10:27 tests/
drwxrwxrwx  2 bassy bassy   4096 Jun  6 10:27 tools/
-rwxrw-rw-  1 bassy bassy    474 Jun  6 10:26 .travis.yml*
```

## 四、安装NDK ##

NDK下载地址： https://dl.google.com/android/repository/android-ndk-r14b-linux-x86_64.zip
下载之后，解压到工作目录 develop 下，如下所示：

```
bassy@ubuntu:~/Desktop/develop$ ll
total 16
drwxrwxr-x  4 bassy bassy 4096 Jun  7 08:29 ./
drwxr-xr-x  5 bassy bassy 4096 Jun  7 08:19 ../
drwxr-xr-x 11 bassy bassy 4096 Mar 15 14:20 android-ndk-r14b/
drwxrwxrwx 18 bassy bassy 4096 Jun  6 10:27 ffmpeg/
```

## 五、ffmpeg编译配置 ##

在 ffmpeg 目录下新建一个文件“ build_android.sh”，并输入如下内容，注意，请根据自己的情况进行适当的修改：

```
#!/bin/bash
NDK=/home/bassy/Desktop/develop/android-ndk-r14b
SYSROOT=$NDK/platforms/android-14/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64

CPU=arm
PREFIX=$(pwd)/android/$CPU
ADDI_CFLAGS="-marm"
TARGET_ARCH="arm"

function build_one
{
./configure \
 --prefix=$PREFIX \
 --disable-shared \
 --enable-static \
 --disable-doc \
 --disable-ffmpeg \
 --disable-ffplay \
 --disable-ffprobe \
 --disable-ffserver \
 --disable-avdevice \
 --disable-doc \
 --disable-symver \
 --cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
 --target-os=android \
 --arch=$TARGET_ARCH\
 --enable-cross-compile \
 --sysroot=$SYSROOT \
 --extra-cflags="-Os -fPIC -DANDROID $ADDI_CFLAGS" \
 --extra-ldflags="$ADDI_LDFLAGS" \
 $ADDITIONAL_CONFIGURE_FLAG
make clean
make
make install
}

build_one
```

 “build_android.sh”文件保存之后，需要赋予可执行权限，如下：

```
bassy@ubuntu:~/Desktop/develop/ffmpeg$ sudo chmod +x build_android.sh 
[sudo] password for bassy: 
bassy@ubuntu:~/Desktop/develop/ffmpeg$ ll *build_*
-rwxrwxr-x 1 bassy bassy 777 Jun  7 08:36 build_android.sh*
```

注意，上面有行代码：“SYSROOT=$NDK/platforms/android-14/arch-arm/”指定了 Android Platform 的版本，这个很重要的，因为它决定了你用它开发的时候所能使用的 Android SDK 的版本。举个例子，如果这里填写的是 android-21，开发时minSdkVersion 填写的是 android-14，会出现很多奇怪的错误。

如果需要编译动态库的话，请修改上面的配置“--disable--shared”改为“--enable-shared”。

如需要编译其它 CPU 架构的话，可查看 https://github.com/RoyGuanyu/build-scripts-of-ffmpeg-x264-for-android-ndk，或者打开ffmpeg 目录下的 configure 文件，看看里面声明的常量值。

更多配置，请用文本查看器打开“(ffmpeg)/configure”文件，里面可以找到对应的说明。以下是其中一部分内容。

```
...

Program options:
  --disable-programs       do not build command line programs
  --disable-ffmpeg         disable ffmpeg build
  --disable-ffplay         disable ffplay build
  --disable-ffprobe        disable ffprobe build
  --disable-ffserver       disable ffserver build

Documentation options:
  --disable-doc            do not build documentation
  --disable-htmlpages      do not build HTML documentation pages
  --disable-manpages       do not build man documentation pages
  --disable-podpages       do not build POD documentation pages
  --disable-txtpages       do not build text documentation pages

Component options:
  --disable-avdevice       disable libavdevice build
  --disable-avcodec        disable libavcodec build
  --disable-avformat       disable libavformat build
  --disable-swresample     disable libswresample build
  --disable-swscale        disable libswscale build

...
```

常用的arch有：

类型    名称
aarch64|arm64    aarch64
arm*|iPad*|iPhone*    arm
mips*|IP*    mips
parisc*|hppa*    parisc
"Power Macintosh"|ppc*|powerpc*    ppc
s390|s390x    s390
sh4|sh    sh4
sun4*|sparc*    sparc
tilegx|tile-gx    tilegx
i[3-6]86*|i86pc|BePC|x86pc|x86_64|x86_32|amd64    x86

常用的target_os有：

target_os
android
freebsd
darwin
mingw32*|mingw64*
win32|win64
cygwin*
*-dos|freedos|opendos
linux

## 六、开始编译 ##

进入在 ffmpeg 目录，执行 “ build_android.sh”，如下：
bassy@ubuntu:~/Desktop/develop/ffmpeg$ sudo ./build_android.sh 
接下来可以去喝杯水，休闲地等它编译……快的话，十多分钟就完成编译了。

```
...
INSTALL    libavutil/lzo.h
INSTALL    libavutil/avconfig.h
INSTALL    libavutil/ffversion.h
INSTALL    libavutil/libavutil.pc
bassy@ubuntu:~/Desktop/develop/ffmpeg$ 
```

## 七、查看编译结果 ##

进入在" ffmpeg/android/arm"可以看到编译结果。

```
bassy@ubuntu:~/Desktop/develop/ffmpeg/android/arm$ ll
total 16
drwxr-xr-x 4 root root 4096 Jun  7 09:03 ./
drwxr-xr-x 3 root root 4096 Jun  7 09:03 ../
drwxr-xr-x 8 root root 4096 Jun  7 09:03 include/
drwxr-xr-x 3 root root 4096 Jun  7 09:03 lib/
bassy@ubuntu:~/Desktop/develop/ffmpeg/android/arm$ ll lib/
total 138992
drwxr-xr-x 3 root root     4096 Jun  7 09:03 ./
drwxr-xr-x 4 root root     4096 Jun  7 09:03 ../
-rw-r--r-- 1 root root 90607318 Jun  7 09:03 libavcodec.a
-rw-r--r-- 1 root root 13182384 Jun  7 09:03 libavfilter.a
-rw-r--r-- 1 root root 33612772 Jun  7 09:03 libavformat.a
-rw-r--r-- 1 root root  1636078 Jun  7 09:03 libavutil.a
-rw-r--r-- 1 root root   377648 Jun  7 09:03 libswresample.a
-rw-r--r-- 1 root root  2886158 Jun  7 09:03 libswscale.a
drwxr-xr-x 2 root root     4096 Jun  7 09:03 pkgconfig/
```

 "include"是头文件，"lib"是静态库，在开发的时候会用到。

- libavcodec encoding/decoding library
- libavfilter graph-based frame editing library
- libavformat I/O and muxing/demuxing library
- libavdevice special devices muxing/demuxing library
- libavutil common utility library
- libswresample audio resampling, format conversion and mixing
- libpostproc post processing library
- libswscale color conversion and scaling library


至此，ffmpeg 的编译已经完成了，直下来将介绍如果编写第一个 ffmpeg 程序。

《使用Android Studio编写第一个ffmpeg程序》 https://mp.csdn.net/console/editor/html/74153201

————————————————

版权声明：本文为CSDN博主「又吹风_Bassy」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/eieihihi/article/details/74152217
