# FFmpeg发送流媒体的命令（UDP，RTP，RTMP）

这两天研究了FFmpeg发送流媒体的命令，在此简单记录一下以作备忘。

## 1.   UDP ##

**1.1. 发送H.264裸流至组播地址**

注：组播地址指的范围是224.0.0.0—239.255.255.255

下面命令实现了发送H.264裸流“chunwan.h264”至地址udp://233.233.233.223:6666

	ffmpeg -re -i chunwan.h264 -vcodec copy -f h264 udp://233.233.233.223:6666

注1：-re一定要加，代表按照帧率发送，否则ffmpeg会一股脑地按最高的效率发送数据。

注2：-vcodec copy要加，否则ffmpeg会重新编码输入的H.264裸流。

**1.2. 播放承载H.264裸流的UDP**

	ffplay -f h264 udp://233.233.233.223:6666

注：需要使用-f说明数据类型是H.264

播放的时候可以加一些参数，比如-max_delay，下面命令将-max_delay设置为100ms：

	ffplay -max_delay 100000 -f h264 udp://233.233.233.223:6666

**1.3. 发送MPEG2裸流至组播地址**

下面的命令实现了读取本地摄像头的数据，编码为MPEG2，发送至地址udp://233.233.233.223:6666。

	ffmpeg -re -i chunwan.h264 -vcodec mpeg2video -f mpeg2video udp://233.233.233.223:6666

**1.4.  播放MPEG2裸流**

指定-vcodec为mpeg2video即可。

	ffplay -vcodec mpeg2video udp://233.233.233.223:6666

## 2.      RTP ##

**2.1. 发送H.264裸流至组播地址。**

下面命令实现了发送H.264裸流“chunwan.h264”至地址rtp://233.233.233.223:6666

	ffmpeg -re -i chunwan.h264 -vcodec copy -f rtp rtp://233.233.233.223:6666>test.sdp

注1：-re一定要加，代表按照帧率发送，否则ffmpeg会一股脑地按最高的效率发送数据。

注2：-vcodec copy要加，否则ffmpeg会重新编码输入的H.264裸流。

注3：最右边的“>test.sdp”用于将ffmpeg的输出信息存储下来形成一个sdp文件。该文件用于RTP的接收。当不加“>test.sdp”的时候，ffmpeg会直接把sdp信息输出到控制台。将该信息复制出来保存成一个后缀是.sdp文本文件，也是可以用来接收该RTP流的。加上“>test.sdp”后，可以直接把这些sdp信息保存成文本。

**2.2. 播放承载H.264裸流的RTP。**

	ffplay test.sdp

## 3.      RTMP ##

**3.1. 发送H.264裸流至RTMP服务器（FlashMedia Server，Red5等）**

面命令实现了发送H.264裸流“chunwan.h264”至主机为localhost，Application为oflaDemo，Path为livestream的RTMP URL。

	ffmpeg -re -i chunwan.h264 -vcodec copy -f flv rtmp://localhost/oflaDemo/livestream

**3.2. 播放RTMP**

	ffplay “rtmp://localhost/oflaDemo/livestream live=1”

注：ffplay播放的RTMP URL最好使用双引号括起来，并在后面添加live=1参数，代表实时流。实际上这个参数是传给了ffmpeg的libRTMP的。

有关RTMP的处理，可以参考文章：ffmpeg处理RTMP流媒体的命令大全

## 4.   测延时 ##

**4.1.测延时**

测延时有一种方式，即一路播放发送端视频，另一路播放流媒体接收下来的流。播放发送端的流有2种方式：FFmpeg和FFplay。

通过FFplay播放是一种众所周知的方法，例如：

	ffplay -f dshow -i video="Integrated Camera"

即可播放本地名称为“Integrated Camera”的摄像头。

此外通过FFmpeg也可以进行播放，通过指定参数“-f sdl”即可。例如：

	ffmpeg -re -i chunwan.h264 -pix_fmt yuv420p –f sdl xxxx.yuv -vcodec copy -f flv rtmp://localhost/oflaDemo/livestream

就可以一边通过SDL播放视频，一边发送视频流至RTMP服务器。

注1：sdl后面指定的xxxx.yuv并不会输出出来。

注2：FFmpeg本身是可以指定多个输出的。本命令相当于指定了两个输出。

播放接收端的方法前文已经提及，在此不再详述。

给我老师的人工智能教程打call！http://blog.csdn.net/jiangjunshow

————————————————

版权声明：本文为CSDN博主「比较清纯」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/hffgjh/article/details/83660291
