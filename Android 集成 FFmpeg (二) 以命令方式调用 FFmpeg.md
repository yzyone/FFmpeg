# Android 集成 FFmpeg (二) 以命令方式调用 FFmpeg

2023-05-09 15:04·[音视频流媒体技术](https://www.toutiao.com/c/user/token/MS4wLjABAAAA21_fy3ikLEGHBFg0FPTOpP6rkmW8pqu43JJD_Z4rxQmWOXc7WdKZfBON0djDMRd1/?source=tuwen_detail)

上一篇文章实现了 FFmpeg 编译及 Android 端的简单调用，成功获取了 FFmpeg 支持的编解码信息，而在实际使用时，需要调用 FFmpeg 内部函数，或通过命令行方式调用，但后者简单很多。

怎么让 FFmpeg 运行命令呢？很简单，调用 FFmpeg 中执行命令的函数即可，这个函数位于源码的 ffmpeg.c 文件中：

```
int main(int argc, char **argv)
```

我们的目的很简单：将 FFmpeg 命令传递给 main 函数并执行。而这个传递过程需要编写底层代码实现，在这个底层接口代码中，接收上层传递过来的 FFmpeg 命令 ，然后调用 ffmpeg.c 中的 main 函数执行该命令。

开始集成之前，首先回顾一下 JNI 标准接入步骤：

1.编写带有 native 方法的 Java 类

2.生成该类扩展名为 .h 的头文件

3.创建该头文件的 C/C++ 文件，实现 native 方法

4.将该 C/C++ 文件编译成动态链接库

5.在Java 程序中加载该动态链接库

接下来按照此步骤开始集成，实现 Android 端以命令方式调用 FFmpeg ，这里假设你已经编译过 FFmpeg 源码，具体编译方法可查看本系列第一篇。如果你是新手或对 Android 端集成底层库不太熟悉，强烈建议先阅读本系列第一篇 Android 集成 FFmpeg (一）基础知识及简单调用 。

首先新建一个文件夹 ndkBuild 作为工作空间，在 ndkBuild 目录下新建 jni 文件夹, 作为编译工作目录。

# 1. 编写带有 native 方法的 Java 类

```
package com.jni;

public class FFmpegJni {
   
    public static native int run(String[] commands);
    
}
```

# 2. 生成该类扩展名为 .h 的头文件

在 Android Studio 的 Terminal 中 切换到 java 目录下，运行 javah 命令生成头文件：

![img](E:\GitHub\FFmpeg\codec\c1b7171fe45641089a5723ee6b661aca~noop.image)



可以看到在 java 目录下生成了头文件：

![img](E:\GitHub\FFmpeg\codec\f4aeb373c4474a639d6d639b47b09dd2~noop.image)



然后将此头文件剪切到 jni 目录下。



# 3. 创建该头文件的 C/C++ 文件，实现 native 方法

在 jni 目录下创建对应的 C 文件 com_jni_FFmpegJni.c :

```
#include "android_log.h"
#include "com_jni_FFmpegJni.h"
#include "ffmpeg.h"

JNIEXPORT jint JNICALL Java_com_jni_FFmpegJni_run(JNIEnv *env, jclass obj, jobjectArray commands) {
    int argc = (*env)->GetArrayLength(env, commands);
    char *argv[argc];
    int i;
    for (i = 0; i < argc; i++) {
        jstring js = (jstring) (*env)->GetObjectArrayElement(env, commands, i);
        argv[i] = (char*) (*env)->GetStringUTFChars(env, js, 0);
    }
    LOGD("----------begin---------");
    return main(argc, argv);
}
```

函数的主要作用就是将 Java 端传递过来的 jobjectArray 类型的 FFmpeg 命令，转换为 main 函数所需要的参数 argc 和 argv ，然后调用之。为了将日志输出函数简化为简洁的 “LOGD”、 “LOGE”，需要在同级目录下新建 android_log.h 文件：

```
#ifdef ANDROID
#include <android/log.h>
#ifndef LOG_TAG
#define  MY_TAG   "MYTAG"
#define  AV_TAG   "AVLOG"
#endif
#define LOGE(format, ...)  __android_log_print(ANDROID_LOG_ERROR, MY_TAG, format, ##__VA_ARGS__)
#define LOGD(format, ...)  __android_log_print(ANDROID_LOG_DEBUG,  MY_TAG, format, ##__VA_ARGS__)
#define  XLOGD(...)  __android_log_print(ANDROID_LOG_INFO,AV_TAG,__VA_ARGS__)
#define  XLOGE(...)  __android_log_print(ANDROID_LOG_ERROR,AV_TAG,__VA_ARGS__)
#else
#define LOGE(format, ...)  printf(MY_TAG format "\n", ##__VA_ARGS__)
#define LOGD(format, ...)  printf(MY_TAG format "\n", ##__VA_ARGS__)
#define XLOGE(format, ...)  fprintf(stdout, AV_TAG ": " format "\n", ##__VA_ARGS__)
#define XLOGI(format, ...)  fprintf(stderr, AV_TAG ": " format "\n", ##__VA_ARGS__)
#endif
```

其中 XLOGD 和 XLOGE 方法是为了将 FFmpeg 内部日志信息自动输出到 logcat，后面会用到。除 android_log.h 之外，很显然，还需要添加 ffmpeg.c 、ffmpeg.h 文件，实际上 ffmpeg.c 的 main 函数中还会调用到其他文件，所以需要从源码中拷贝 ffmpeg.h、ffmpeg.c、ffmpeg_opt.c、ffmpeg_filter.c、cmdutils.c、cmdutils.h 以及 cmdutils_common_opts.h 共 7 个文件到 jni 目录下。

此时 jni 目录下应该有以下 10 个文件：

![img](E:\GitHub\FFmpeg\codec\71e2cf3faf6245e9a68a299e61735f83~noop.image)



接下来还要修改 ffmpeg.c 、cmdutils.c 以及 cmdutils.h 三个文件使其适用于 Android 端调用，按功能分为以下三点：

1.日志输出到 logcat （修改 ffmpeg.c）

在执行命令过程中，FFmpeg 内部的日志系统会输出很多有用的信息，但是在 Android 的 logcat 中是看不到的，所以需要修改源码将 FFmpeg 内部日志输出 logcat 中，方便调试，其实这是十分必要的。修改方法很简单，只需修改 ffmpeg.c 文件三处：

引入 android_log.h 头文件：

```
#include "android_log.h"
```

修改 log_callback_null 方法为下：（原方法为空）

```
static void log_callback_null(void *ptr, int level, const char *fmt, va_list vl)
{
    static int print_prefix = 1;
    static int count;
    static char prev[1024];
    char line[1024];
    static int is_atty;
    av_log_format_line(ptr, level, fmt, vl, line, sizeof(line), &print_prefix);
    strcpy(prev, line);
    if (level <= AV_LOG_WARNING){
        XLOGE("%s", line);
    }else{
        XLOGD("%s", line);
    }
}
```

设置日志回调方法为 log_callback_null：（main 函数开始处）

```
int main(int argc, char **argv)
{
    av_log_set_callback(log_callback_null);
    int i, ret;
    ......
```

**2.执行命令后清除数据（修改 ffmpeg.c）**

由于 Android 端执行一条 FFmpeg 命令后并不需要结束进程，所以需要初始化相关变量，否则执行下一条命令时就会崩溃。首先找到 ffmpeg.c 的 ffmpeg_cleanup 方法，在该方法的末尾添加以下代码：

```
    nb_filtergraphs = 0;
    nb_output_files = 0;
    nb_output_streams = 0;
    nb_input_files = 0;
    nb_input_streams = 0;
```

然后在 main 函数的最后调用 ffmpeg_cleanup 方法，如下：

```
    ......
    ffmpeg_cleanup(0);
    return main_return_code;
}
```

3.执行结束后不结束进程（修改 cmdutils.c、cmdutils.h）

FFmpeg 在执行过程中出现异常或执行结束后会自动销毁进程，而我们在 Android 中调用时，只想让它作为一个普通的方法，不需要销毁进程，只需要正常返回就可以了，这就需要修改 cmdutils.c 中的 exit_program 方法，源码中为：

```
void exit_program(int ret)
{
    if (program_exit)
        program_exit(ret);

    exit(ret);
}
```

修改为：

```
int exit_program(int ret)
{
   return ret;
}
```

此处修改了方法的返回值类型，所以还需要修改对应头文件中的方法声明，即将 cmdutils.h 中的：

```
void exit_program(int ret) av_noreturn;
```

修改为：

```
int exit_program(int ret);
```

到这里需要修改项都已修改完毕，网上教程实现 FFmpeg 内部日志输出到 logcat 的并不多，但这一步是十分有必要的。很多教程中需要将 ffmpeg 中的 main 方法名字修改为 “run” 、“exec” 等等，其实完全没必要，为什么要对方法名这么在意，乃至不惜徒增新手学习的复杂度呢？ 我不知道修改的原因和意义所在。 有些教程中需要把 config.h 文件也拷贝到 jni 目录下，而我并没有拷贝，那么到底需不需要呢？FFmpeg 的命令数不胜数，我只能说我执行过的命令都不需要拷贝 config.h ，尽管源码 ffmpeg.c 中就声明了引入 config.h 文件。

4. 将该 C/C++ 文件编译成动态链接库

在 jni 目录下创建 Android.mk 文件 ：

```
LOCAL_PATH:= $(call my-dir)

#编译好的 FFmpeg 头文件目录
INCLUDE_PATH:=/home/yhao/sf/ffmpeg-3.3.3/Android/arm/include

#编译好的 FFmpeg 动态库目录
FFMPEG_LIB_PATH:=/home/yhao/sf/ffmpeg-3.3.3/Android/arm/lib

include $(CLEAR_VARS)
LOCAL_MODULE:= libavcodec
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libavcodec-57.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)
 
include $(CLEAR_VARS)
LOCAL_MODULE:= libavformat
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libavformat-57.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)
 
include $(CLEAR_VARS)
LOCAL_MODULE:= libswscale
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libswscale-4.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)
 
include $(CLEAR_VARS)
LOCAL_MODULE:= libavutil
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libavutil-55.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)
 
include $(CLEAR_VARS)
LOCAL_MODULE:= libavfilter
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libavfilter-6.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)
 
include $(CLEAR_VARS)
LOCAL_MODULE:= libswresample
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libswresample-2.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libpostproc
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libpostproc-54.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libavdevice
LOCAL_SRC_FILES:= $(FFMPEG_LIB_PATH)/libavdevice-57.so
LOCAL_EXPORT_C_INCLUDES := $(INCLUDE_PATH)
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := ffmpeg
LOCAL_SRC_FILES := com_jni_FFmpegJni.c \
                  cmdutils.c \
                  ffmpeg.c \
                  ffmpeg_opt.c \
                  ffmpeg_filter.c   
LOCAL_C_INCLUDES := /home/yhao/sf/ffmpeg-3.3.3
LOCAL_LDLIBS := -lm -llog
LOCAL_SHARED_LIBRARIES := libavcodec libavfilter libavformat libavutil libswresample libswscale libavdevice
include $(BUILD_SHARED_LIBRARY)
```

此处使用的 FFmpeg 为本系列上篇文章中的编译配置，其中引入了 libmp3lame 库以支持 mp3 格式编码，与上篇文章不同的是最后对 ffmpeg 动态库的编译，加入了 ffmpeg.c 、cmdutils.c 等文件。

然后在 jni 目录下创建 MKhost domain parking page 文件：

```
APP_ABI := armeabi-v7a
APP_PLATFORM=android-14
NDK_TOOLCHAIN_VERSION=4.9
```

这时 jni 目录应该有以下 12 个文件：

![img](E:\GitHub\FFmpeg\codec\9d9675987b6f4148a671ae987b19c303~noop.image)



一切准备就绪，在 jni 目录下运行 ndk 编译命令：

```
ndk-build
```

然后就可以在 ndkBuild 目录下看到生成的 libs 和 obj 文件夹了。

# 5.在Java 程序中加载该动态链接库

将 libs 目录下生成的 armeabi-v7a 动态库拷贝到 Android 工程中，此时工程应该是这样的：

![img](E:\GitHub\FFmpeg\codec\50f48ea7cfc149dabca6a9bfa5a30bfd~noop.image)



在 FFmpegJni.java 中加载动态库：

```
package com.jni;

public class FFmpegJni {
    static {
        System.loadLibrary("avutil-55");
        System.loadLibrary("avcodec-57");
        System.loadLibrary("avformat-57");
        System.loadLibrary("avdevice-57");
        System.loadLibrary("swresample-2");
        System.loadLibrary("swscale-4");
        System.loadLibrary("postproc-54");
        System.loadLibrary("avfilter-6");
        System.loadLibrary("ffmpeg");
    }
    public static native int run(String[] commands);
}
```

记得在应用的 build.gradle 文件中 android 节点下添加动态库加载路径：

```
    sourceSets {
        main {
            jniLibs.srcDirs = ['libs']
        }
    }
```

OK，至此集成工作就全部完成了，在程序中调用 run 方法，就能以命令方式调用 FFmpeg 。

接下来以剪切 mp3 文件为例，验证是否集成成功，首先需要准备一个 mp3 文件，这里我提供两首歌：泡沫、童话镇，下载解压后直接将其放到手机根目录下即可。

直接给出 MainActivity 代码：

```
import com.jni.FFmpegJni;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        if ( ActivityCompat.checkSelfPermission(this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED ) {
            ActivityCompat.requestPermissions(this,new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE }, 1);
        }
    }

    public void run(View view) {
        String dir = Environment.getExternalStorageDirectory().getPath() + "/ffmpegTest/";

        //ffmpeg -i source_mp3.mp3 -ss 00:01:12 -t 00:01:42 -acodec copy output_mp3.mp3
        String[] commands = new String[10];
        commands[0] = "ffmpeg";
        commands[1] = "-i";
        commands[2] = dir+"paomo.mp3";
        commands[3] = "-ss";
        commands[4] = "00:01:00";
        commands[5] = "-t";
        commands[6] = "00:01:00";
        commands[7] = "-acodec";
        commands[8] = "copy";
        commands[9] = dir+"paomo_cut_mp3.mp3";

        int result = FFmpegJni.run(commands);
        Toast.makeText(MainActivity.this, "命令行执行完成 result="+result, Toast.LENGTH_SHORT).show();
    }
}
```

记得在 AndroidManifest.xml 中声明权限：

```
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

运行之后，播放生成的 paomo_cut_mp3 试试，剪切成功～ 但是一个例子不够过瘾，再来一个延时播放的命令：

```
        String[] commands = new String[12];
        commands[0] = "ffmpeg";
        commands[1] = "-i";
        commands[2] = dir+"paomo.mp3";
        commands[3] = "-filter_complex";
        commands[4] = "adelay=5000|5000";
        commands[5] = "-ac"; //声道数
        commands[6] = "1";
        commands[7] = "-ar"; //采样率
        commands[8] = "24k";
        commands[9] = "-ab"; //比特率
        commands[10] = "32k";
        commands[11] = dir+"adelay_output.mp3";
```

更简单的方法实现

本文的核心工作是 ffmpeg.c 等文件的修改及编译，其实这些文件的修改是一劳永逸的。无论你的 FFmpeg 如何配置编译选项，不管是支持 mp3 编码还是支持 h264 编码，对 ffmpeg.c 等文件的修改内容都是固定的，所以我把这个工作目录上传到了 github ，方便大家直接拿来使用。

github 地址 :
https://github.com/yhaolpz/ffmpeg-command-ndkBuild

接下来演示一下如何使用，首先要将 ffmpeg-command-ndkBuild 克隆到你的电脑上，注意这里默认你已经编译过 FFmpeg，编译方法见本系列第一章。

编写带有 native 方法的 Java 类

```
package com.jni;

public class FFmpegJni {
   
    public static native int run(String[] commands);
    
}
```

如果你编写的 Java 类跟上面这个类的包名、类名和方法都相同，那就直接跳到第 4 步，因为你可以直接使用 jni 目录中的 com_jni_FFmpegJni.c 和 com_jni_FFmpegJni.h 。

生成该类扩展名为 .h 的头文件

在 Android Studio 的 Terminal 中 切换到 Java 目录下，运行 javah 命令生成头文件：

```
javah -classpath .  com.包名.类名
```

将该头文件拷贝到 jni 目录下，并且删除 com_jni_FFmpegJni.h 文件。

创建该头文件的 C/C++ 文件，实现 native 方法

这里不需要重新创建 C 文件，直接在 com_jni_FFmpegJni.c 基础上修改即可。

修改第2行 com_jni_FFmpegJni.h 为你自己的头文件名

修改
Java_com_jni_FFmpegJni_run 方法名为你自己的头文件中的方法名

修改 com_jni_FFmpegJni.c 文件名为你自己的头文件名

修改 Android.mk 中文件最后的 com_jni_FFmpegJni.c 为你自己的 C 文件名

将该 C/C++ 文件编译成动态链接库

修改 Android.mk 中的 INCLUDE_PATH 、FFMPEG_LIB_PATH 为你自己编译好的 FFmpeg 动态库路径

修改 Android.mk 倒数第四行的 LOCAL_C_INCLUDES 为你自己的 FFmpeg 源码路径。

OK~ 直接运行 ndk-build 命令编译吧，最后一步 “在Java 程序中加载该动态链接库” 以及调用案例在上文中已经描述的很详细了，就不再赘述了。

总结

本文延续第一篇的规则，将编译工作置于 Android 工程之外进行，直到生成最后可用的 so 库再移植到 Android 工程中，我相信这样对 jni 的理解会更清晰一些。

本文中还有两个问题待解决，在 MKhost domain parking page 文件中通过 NDK_TOOLCHAIN_VERSION=4.9 指定编译器为 4.9 版本的 gcc，若不指定，将默认使用 clang 编译器，这时编译会报错，提示缺少一些文件。第二个问题就是 MKhost domain parking page 中通过 APP_ABI := armeabi-v7a 指定生成 armv7 架构动态库，若改成 armeabi 架构编译则会报错，提示不支持该模式，后续尽快解决这两个问题。

原文链接：Android 集成 FFmpeg (二) 以命令方式调用 FFmpeg