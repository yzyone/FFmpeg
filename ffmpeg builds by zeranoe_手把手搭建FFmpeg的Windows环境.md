
# ffmpeg builds by zeranoe_手把手搭建FFmpeg的Windows环境 #

1.简述

在Windows平台，搭建FFmpeg开发环境，能够帮助我们做各种开发的测试，如推流，拉流，滤镜等。

![](./images/5057beb777a743899e8c25756ca39a4a.jpg)

2.下载源码

(1)登陆FFMPEG官网

官网地址:http://ffmpeg.org/

下载4.2.1版本源码地址：https://ffmpeg.org/releases/ffmpeg-4.2.1.tar.bz2

下载4.2.1编译好的文件：https://ffmpeg.zeranoe.com/builds/

官网截图如下:

![](./images/1ef8dd16060e404bab0be73b57d2d6c5.jpg)

找到适合的源码和编译好的文件。

32位下载地址：

Shared：包含FFMPEG的dll库文件。

地址:https://ffmpeg.zeranoe.com/builds/win32/shared/ffmpeg-4.2.1-win32-shared.zip

Static：包含了FFMPEG的官方文档。

地址：https://ffmpeg.zeranoe.com/builds/win32/static/ffmpeg-4.2.1-win32-static.zip

Dev：包含FFMPEG的lib文件/头文件，以及example范例。

地址：https://ffmpeg.zeranoe.com/builds/win32/dev/ffmpeg-4.2.1-win32-dev.zip

注意：这里以32位版本为例子，其它版本也类似。

3.FFmpeg命令行环境搭建

解压:ffmpeg-4.2.1-win32-shared.zip

(1)拷贝ffmpeg-4.2.1-win32-sharedbin目录的执行文件到C:Windows

![](./images/a7dc9c327751475483e1041568820691.jpg)

(2)拷贝ffmpeg-4.2.1-win32-sharedbin目录的动态库到C:WindowsSysWOW64

WoW64 (Windows On Windows64 [1] )是一个Windows操作系统的子系统，被设计用来处理许多在32-bit Windows和64-bit Windows之间的不同的问题，使得可以在64-bit Windows中运行32-bit程序。

![](./images/4a3c15d8640a4a189c221d36d280edcf.jpg)

(3)打开cmd命令行窗口，输入ffmpeg -version。如果出现如下界面，证明测试成功。

![](./images/640fad53372f4ac2a5cd8b1499a91063.jpg)

4.FFmpeg与QT环境搭建

![](./images/065e96ab1aa44b38b6b80fe1732ed841.jpg)

(1)QT安装

QT官网：https://www.qt.io/

这里以QT 5.10.1版本为例子进行下载。以下2个地址，2选一即可。

下载地址：http://download.qt.io/official_releases/qt/5.10/5.10.1/

直接选择下载地址：http://iso.mirrors.ustc.edu.cn/qtproject/archive/qt/5.10/5.10.1/qt-opensource-windows-x86-5.10.1.exe

选择如下版本：

![](./images/134a18006b2b4886a169e9ce7067dfde.jpg)

下载后，准备安装。

按照安装向导一步步Next(或下一步)。

![](./images/c0785e8fa99641f3a45f54601c19919e.jpg)
![](./images/be90048b0ff2446a87c4caaeaf56e617.jpg)
![](./images/326225b72c364e27b93620ffb6873994.jpg)

可以选择自定义路径或使用默认也可以。

![](./images/2dc6de604014401ca9dbea99ed9089d2.jpg)

勾选如下插件，如果怕漏选，可以全选(可能安装时间会长点，更占用硬盘空间)。

![](./images/c7a53df31f094e5da5aec50a51767cc4.jpg)

同意许可证。

![](./images/2f28cce456a54c35be04a4663ff5cc2a.jpg)
![](./images/452420a1231a451cb02f055c021ad182.jpg)
![](./images/c736d3f5657d43b39534e0cf1b10dd6d.jpg)

等待安装结束

![](./images/962e6f58ee1f445db9d6ddd36098e809.jpg)

5.测试FFmpeg与QT使用

(1)创建QT工程

![](./images/c92da31df876484e80756ca440cc10bc.jpg)

新建工程

![](./images/4d82889ae7254c0fb9bac628addd9723.jpg)

选择Non-Qt Project。根据需求选择C++还是C工程。

![](./images/dfc45941b3454eecbc86fd79e5785f61.jpg)

填写项目名称以及路径，如下所示就创建了一个叫xxx(名字自定义)的工程。

![](./images/d5931b1233a948d0a423faedf0c66690.jpg)
![](./images/7c402fd7ddf84989a4cffcdc6046abff.jpg)

选择编译器

![](./images/ac12c30bfec8448798cf80261a5be026.jpg)

注意：需要使用C时则选择，“Plain C++ Application”

![](./images/d1832aa094f740a2ae412adc8bbb6c97.jpg)

到此步骤结束，就可以创建 一个最基本的工程。

(2)添加FFmpeg库

将从FFmpeg网站上下载下来的ffmpeg-4.2.1-win32-dev拷贝到ffmpeg-version目录下。如下界面：

![](./images/983dae482950455b9b7980d87d5be440.jpg)

在ffmpeg-version.pro里面添加ffmpeg头文件和库文件路径，按照如下代码添加：

![](./images/af0dc02b113f45e2911be320c0f346bd.jpg)

注意：LIBS的多行引用一定要记得带斜杠，否则后续的引用无效。

![](./images/8e9442fcf6cd45c3b5510bc78082e6ad.jpg)

修改main.c文件

使用FFmpeg库，能否生效。

![](./images/83d5af0ccc2545ca82f7daef5e16953d.jpg)

执行程序

![](./images/12265795122f40aeaf8bf514f6c484cc.jpg)

如果能够显示如下打印，证明搭建成功。

![](./images/a7118cb7f1fa4f47820300ed6ca962de.jpg)

到此步骤结束，Windows QT+FFMPEG的开发环境就搭建完毕了。

本篇文章就分析到这里，欢迎大家关注欢迎关注，点赞，转发，收藏，分享，评论区讨论。

后面关于项目知识，后期会更新。欢迎关注微信公众号"记录世界 from antonio"。

相关资源：Windows编译ffmpeg步骤_ffmpegwindows编译,windows编译ffmpeg-编...