# make安装FFmpeg #

一.环境准备

	yum install autoconf automake bzip2 cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

二.创建下载目录和安装目录

	mkdir /usr/local/ffmpeg_sources mkdir /usr/local/ffmpeg_build

三.ffmpeg安装

1.NASM [下载](./files/nasm-2.13.02.tar.bz2)

```
cd  /usr/local/ffmpeg_sources
curl -O -L http://www.nasm.us/pub/nasm/releasebuilds/2.13.02/nasm-2.13.02.tar.bz2
tar xjvf nasm-2.13.02.tar.bz2
cd nasm-2.13.02
./autogen.sh
./configure --prefix="/usr/local/ffmpeg_build" --bindir="/usr/local/bin"
make
make install
```

2.Yasm [下载](./files/yasm-1.3.0.tar.gz)

```
cd  /usr/local/ffmpeg_sources
curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
tar xzvf yasm-1.3.0.tar.gz
cd yasm-1.3.0
./configure --prefix="/usr/local/ffmpeg_build" --bindir="/usr/local/bin"
make
make install
```

3.libx264 [下载](./files/x264.tar.gz)

```
cd   /usr/local/ffmpeg_sources
#git clone --depth 1 http://git.videolan.org/git/x264
git clone https://code.videolan.org/videolan/x264.git
cd x264
PKG_CONFIG_PATH="/usr/local/ffmpeg_build/lib/pkgconfig"   ./configure --prefix="/usr/local/ffmpeg_build" --bindir="/usr/local/bin" --enable-static
make
make install
```

4.libx265 [下载](./files/x265_git.tar.gz)

```
cd  /usr/local/ffmpeg_sources
#hg clone https://bitbucket.org/multicoreware/x265
git clone https://bitbucket.org/multicoreware/x265_git.git
cd /usr/local/ffmpeg_sources/x265/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/usr/local/ffmpeg_build"     
-DENABLE_SHARED:bool=off ../../source
make
make install
```

5.libfdk_aac [下载](./files/fdk-aac.tar.gz)

```
cd   /usr/local/ffmpeg_sources
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix=" /usr/local/ffmpeg_build" --disable-shared
make
make install
```

6.libmp3lame [下载](./files/lame-3.100.tar.gz)

```
cd  /usr/local/ffmpeg_sources
curl -O -L http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzvf lame-3.100.tar.gz
cd lame-3.100
./configure --prefix="/usr/local/ffmpeg_build" --bindir="/usr/local/bin" --disable-shared --enable-nasm
make
make install
```

7.libopus [下载](./files/opus-1.2.1.tar.gz)

```
cd    /usr/local/ffmpeg_sources
curl -O -L https://archive.mozilla.org/pub/opus/opus-1.2.1.tar.gz
tar xzvf opus-1.2.1.tar.gz
cd opus-1.2.1
./configure --prefix="/usr/local/ffmpeg_build" --disable-shared
make
make install
```

8.libogg [下载](./files/libogg-1.3.3.tar.gz)

```
cd    /usr/local/ffmpeg_sources
curl -O -L http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz
tar xzvf libogg-1.3.3.tar.gz
cd libogg-1.3.3
./configure --prefix=" /usr/local/ffmpeg_build" --disable-shared
make
make install
```

9.libvorbis [下载](./files/libvorbis-1.3.5.tar.gz)

```
cd   /usr/local/ffmpeg_sources
curl -O -L http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz
tar xzvf libvorbis-1.3.5.tar.gz
cd libvorbis-1.3.5
./configure --prefix=" /usr/local/ffmpeg_build" --with-ogg=" /usr/local/ffmpeg_build" --disable-shared
make
make install
```

10.libvpx [下载](./files/libvpx.tar.gz)

```
cd  /usr/local/ffmpeg_sources

git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
./configure --prefix="/usr/local/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
make
make install
```

11.FFmpeg [下载](./files/ffmpeg-snapshot.tar.bz2)

```
cd   /usr/local/ffmpeg_sources

curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PKG_CONFIG_PATH="/usr/local/ffmpeg_build/lib/pkgconfig" 
./configure \
  --prefix="/usr/local/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I/usr/local/ffmpeg_build/include" \
  --extra-ldflags="-L/usr/local/ffmpeg_build/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir="/usr/local/bin" \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
```
