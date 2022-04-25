#!/bin/bash
NDK=/home/android-ndk-r20b
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
#这里修改的是最低支持的android sdk版本（r20版本ndk中armv8a、x86_64最低支持21，armv7a、x86最低支持16）
API=16

function build_android
{
echo "Compiling FFmpeg for $CPU"

    ./configure \
	    --prefix=$PREFIX \
	    --disable-neon \
	    --disable-hwaccels \
	    --disable-gpl \
	    --disable-postproc \
	    --enable-shared \
	    --enable-jni \
	    --disable-mediacodec \
	    --disable-decoder=h264_mediacodec \
	    --disable-static \
	    --disable-doc \
	    --disable-ffmpeg \
	    --disable-ffplay \
	    --disable-ffprobe \
	    --disable-avdevice \
	    --disable-doc \
	    --disable-symver \
	    --cross-prefix=$CROSS_PREFIX \
	    --target-os=android \
	    --arch=$ARCH \
	    --cpu=$CPU \
	    --cc=$CC \
	    --cxx=$CXX \
	    --enable-cross-compile \
	    --sysroot=$SYSROOT \
	    --extra-cflags="-Os -fpic $OPTIMIZE_CFLAGS" \
	    --extra-ldflags="$ADDI_LDFLAGS" \
	    $ADDITIONAL_CONFIGURE_FLAG

echo "Configure complete!"
make clean
echo "Start building..."
make -j4
echo "Start installing..."
make install
echo "The Compilation of FFmpeg for $CPU is completed"
}

#armv7-a
API=16
ARCH=arm
CPU=armv7-a
CC=$TOOLCHAIN/bin/armv7a-linux-androideabi$API-clang
CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi$API-clang++
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
PREFIX=$(pwd)/android/$CPU
OPTIMIZE_CFLAGS="-march=$CPU"

build_android

#armv8-a
API=21
ARCH=arm64
CPU=armv8-a
CC=$TOOLCHAIN/bin/aarch64-linux-android$API-clang
CXX=$TOOLCHAIN/bin/aarch64-linux-android$API-clang++
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-
PREFIX=$(pwd)/android/$CPU
OPTIMIZE_CFLAGS="-march=$CPU"

build_android

#x86
API=16
ARCH=x86
CPU=x86
CC=$TOOLCHAIN/bin/i686-linux-android$API-clang
CXX=$TOOLCHAIN/bin/i686-linux-android$API-clang++
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CROSS_PREFIX=$TOOLCHAIN/bin/i686-linux-android-
PREFIX=$(pwd)/android/$CPU
OPTIMIZE_CFLAGS="-march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32"
build_android

#x86_64
API=21
ARCH=x86_64
CPU=x86-64
CC=$TOOLCHAIN/bin/x86_64-linux-android$API-clang
CXX=$TOOLCHAIN/bin/x86_64-linux-android$API-clang++
SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CROSS_PREFIX=$TOOLCHAIN/bin/x86_64-linux-android-
PREFIX=$(pwd)/android/$CPU
OPTIMIZE_CFLAGS="-march=$CPU -msse4.2 -mpopcnt -m64 -mtune=intel"
build_android

