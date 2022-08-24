# 支持 flv+h265 的ffmpeg编译安装

支持 flv+h265 的ffmpeg编译安装

```
一、操作说明
二、编译依赖
	1. h264
	2. h265
	3. 编译ffmpeg
	4. 截屏命令示例
三、问题处理
	1. x264_bit_depth 未定义
	2. fdk-aac 出现has no member named ‘encoderDelay’
```

## 一、操作说明 ##

ffmpeg 官方分支没有支持flv+h265，国内金山云发了补丁版本，地址：

    git clone https://github.com/ksvc/FFmpeg.git -b release/3.4 --depth=1

## 二、编译依赖 ##

**1. h264**

```
   cd ~/ffmpeg_sources
   git clone --depth 1 https://code.videolan.org/videolan/x264.git
   curl -O -L http://anduin.linuxfromscratch.org/BLFS/x264/x264-20200819.tar.xz
   xz -d x264-20200819.tar.xz
   tar -xvf x264-20200819.tar
   mv x264-20200819 x264
   cd x264
   PKG_CONFIG_PATH="$INSTALL_PATH/lib/pkgconfig" 
   ./configure --prefix="$INSTALL_PATH" --bindir="$INSTALL_PATH/bin" --enable-static --enable-shared
   make
   make install
```

**2. h265**

```
   curl -O -L http://anduin.linuxfromscratch.org/BLFS/x265/x265_3.4.tar.gz
   tar -xzvf x265_3.4.tar.gz
   mv x265_3.4 x265
   cd ~/ffmpeg_sources/x265/build/linux
   cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" -DENABLE_SHARED:bool=on ../../source
   make
   make install
```

更多操作可参考：https://blog.csdn.net/xundh/article/details/100760114

**3. 编译ffmpeg**

```
   PATH="$INSTALL_PATH/bin:$PATH" 
   PKG_CONFIG_PATH="$INSTALL_PATH/lib/pkgconfig"
   export PKG_CONFIG_PATH=$INSTALL_PATH/local/lib/pkgconfig:$PKG_CONFIG_PATH
   .
   /configure --prefix="$INSTALL_PATH"  --enable-static --enable-pic \
   
         --enable-encoder=aac --enable-encoder=libx264 --enable-gpl --enable-libx264 --enable-encoder=libx265  --enable-libx265 \
         --enable-decoder=aac --enable-decoder=h264 --enable-decoder=hevc  \
         --enable-demuxer=aac --enable-demuxer=mov --enable-demuxer=mpegts --enable-demuxer=flv --enable-demuxer=h264 --enable-demuxer=hevc --enable-demuxer=hls  \
        --enable-muxer=h264  --enable-muxer=flv --enable-muxer=f4v  --enable-muxer=mp4 \
        --disable-doc --enable-libmp3lame --enable-libfdk_aac --enable-nonfree
   
```

如果不成功，可以尝试在最后添加： --pkg-config="pkg-config --static"

```
# 编译

make
make install

# 最后执行一下

ldconfig
```

**4. 截屏命令示例**

```
 ffmpeg -i "视频地址" -y -f mjpeg  -c:v libx265 -x265-params qp=47  -timeout 15 -s 640x480 -vframes 1  1.jpg
 ffmpeg -i "视频地址" -y -f mjpeg    -timeout 15 -s 640x480 -vframes 1  1.jpg
```

## 三、问题处理 ##

**1. x264_bit_depth 未定义**

```
   libavcodec/libx264.c:892:9: error: ‘x264_bit_depth‘ undeclared (first use in this function)
```

   原因：应该是x264的x264_bit_depth被改为了大写的X264_BIT_DEPTH。
   解决方式：修改libx264.c文件，将此文件中的所有x264_bit_depth替换为X264_BIT_DEPTH，然后重新编译。

**2. fdk-aac 出现has no member named ‘encoderDelay’**

```
   把 avctx->initial_padding = info.encoderDelay; 改为 avctx->initial_padding = info.nDelay;
```

————————————————

版权声明：本文为CSDN博主「编程圈子」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

 原文链接：https://blog.csdn.net/xundh/article/details/125021984