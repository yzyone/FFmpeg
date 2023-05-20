# ffmpeg源码笔记-查找编解码器(一)

2023-05-15 21:28·[音视频流媒体技术](https://www.toutiao.com/c/user/token/MS4wLjABAAAA21_fy3ikLEGHBFg0FPTOpP6rkmW8pqu43JJD_Z4rxQmWOXc7WdKZfBON0djDMRd1/?source=tuwen_detail)

AVCodec类型的结构体包含了对一个编码器底层实现的封装;定义如下:

```
typedef struct AVCodec {
    //编码器名,在编码器和解码器两个类别中分别具有唯一性;
    //如:libx264
    const char *name;
 
    //编码器实例的完整名称;
    //如:libx264 H.264/AVC/MPEG-4 AVC/MPEG-4 part 10
    const char *long_name;
 
    //当前编码器处理的媒体类型;
    enum AVMediaType type;
 
    //编码类型ID;
    enum AVCodecID id;
 
    //当前编码器所支持的能力;
    int capabilities;
 
    //支持的帧率
    const AVRational *supported_framerates; 
    //支持的图像像素格式;
    const enum AVPixelFormat *pix_fmts;    
 
    //支持的音频采样率 
    const int *supported_samplerates;  
    //支持的音频采样格式    
    const enum AVSampleFormat *sample_fmts; 
    //支持的声道布局
    const uint64_t *channel_layouts;      
    //支持的降分辨率解码;  
    uint8_t max_lowres;                     
    const AVClass *priv_class;  
 
    //支持的编码档次;      
    const AVProfile *profiles;              
 
    /*编码器实现的组件或封装名称,主要用于标识该编码器的外部实现者;
      当该字段为空时,该编码器有libavcodec库内部实现;当该字段不为空时,该编码器由硬件或操作系统
      等外部实现,并在字段保存AVCodec.nam的缩写;    
    */
    const char *wrapper_name;
 
    int priv_data_size;
 
    //实现链表
    struct AVCodec *next;
   
    int (*update_thread_context)(struct AVCodecContext *dst, const struct AVCodecContext *src);
  
    const AVCodecDefault *defaults;
 
    void (*init_static_data)(struct AVCodec *codec);
 
    int (*init)(struct AVCodecContext *);
    int (*encode_sub)(struct AVCodecContext *, uint8_t *buf, int buf_size,
                      const struct AVSubtitle *sub);
    int (*encode2)(struct AVCodecContext *avctx, struct AVPacket *avpkt,
                   const struct AVFrame *frame, int *got_packet_ptr);
    int (*decode)(struct AVCodecContext *, void *outdata, int *outdata_size, struct AVPacket *avpkt);
    int (*close)(struct AVCodecContext *);
   
    int (*send_frame)(struct AVCodecContext *avctx, const struct AVFrame *frame);
    int (*receive_packet)(struct AVCodecContext *avctx, struct AVPacket *avpkt);
   
    int (*receive_frame)(struct AVCodecContext *avctx, struct AVFrame *frame);
    void (*flush)(struct AVCodecContext *);
    
    int caps_internal;
    const char *bsfs;
 
    const struct AVCodecHWConfigInternal **hw_configs;
 
    const uint32_t *codec_tags;
} AVCodec;
```

**1. 查找编码器的方法**

```
//通过指定名称查找编码器实例; 
AVCodec *avcodec_find_encoder_by_name(const char *name);
 
//通过指定编码器ID查找编码器实例;
AVCodec *avcodec_find_encoder(enum AVCodecID id);
```

(a)其中的name为编解码器名,不知道如何填写可以看文件开头定义的很多extern结构体；

最常见的为 extern AVCodec ff_libx264_encoder;

点击去后为:

```
AVCodec ff_libx264_encoder = {
    .name             = "libx264",
    .long_name        = NULL_IF_CONFIG_SMALL("libx264 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10"),
    .type             = AVMEDIA_TYPE_VIDEO,
    .id               = AV_CODEC_ID_H264,
    .priv_data_size   = sizeof(X264Context),
    .init             = X264_init,
    .encode2          = X264_frame,
    .close            = X264_close,
    .capabilities     = AV_CODEC_CAP_DELAY | AV_CODEC_CAP_AUTO_THREADS |
                        AV_CODEC_CAP_ENCODER_REORDERED_OPAQUE,
    .priv_class       = &x264_class,
    .defaults         = x264_defaults,
    .init_static_data = X264_init_static,
#if X264_BUILD >= 158
    .caps_internal    = FF_CODEC_CAP_INIT_CLEANUP | FF_CODEC_CAP_INIT_THREADSAFE,
#else
    .caps_internal    = FF_CODEC_CAP_INIT_CLEANUP,
#endif
    .wrapper_name     = "libx264",
};
```

可知对应的名字可以填 libx264;

而要支持x264需要configue时--enable-x264等字样去配置;

(b) enum AVCodecID id;对应codec_id.h;

# 2. 查找解码器的方法

```
//通过名字查找指定解码器
AVCodec *avcodec_find_decoder_by_name(const char *name);
 
//通过ID查找指定解码器
AVCodec *avcodec_find_decoder(enum AVCodecID id);
```

libavcodec/allcodecs.c中开头定义了很多支编解码结构体;如:

```
extern AVCodec ff_h264_decoder;
...
 
//音频编解码器
extern AVCodec ff_aac_encoder;
extern AVCodec ff_aac_decoder;
...
 
//PCM编解码器
extern AVCodec ff_pcm_alaw_encoder;
extern AVCodec ff_pcm_alaw_decoder;
...
 
//DPCM编解码器
extern AVCodec ff_derf_dpcm_decoder;
extern AVCodec ff_gremlin_dpcm_decoder;
...
 
//ADPCM编解码器
extern AVCodec ff_adpcm_4xm_decoder;
extern AVCodec ff_adpcm_adx_encoder;
...
 
//字幕编解码器
extern AVCodec ff_ssa_encoder;
extern AVCodec ff_ssa_decoder;
...
 
//外部库、
extern AVCodec ff_aac_at_encoder;
extern AVCodec ff_aac_at_decoder;
...
//优于libwebp
extern AVCodec ff_libx264_encoder;
 
 
//文本
extern AVCodec ff_bintext_decoder;
extern AVCodec ff_xbin_decoder;
extern AVCodec ff_idf_decoder;
 
//其他外部库
extern AVCodec ff_aac_mf_encoder;
extern AVCodec ff_ac3_mf_encoder;
...
```

# 3. 源码解读avcodec_find_encoder_by_name调用


avcodec_find_encoder_by_name调用了find_codec_by_name;

```
//参数1,需要查找的编解码器名  参数2:回调函数指针,用于判断下面查找出来的AVCodec是否为编/解码器
static AVCodec *find_codec_by_name(const char *name, int (*x)(const AVCodec *))
{
    void *i = 0;
    const AVCodec *p;
 
    if (!name)
        return NULL;
 
    //av_codec_iterate相当于迭代器遍历所有的codec_list数组,返回值p为遍历到的编/解码器
    while ((p = av_codec_iterate(&i))) {
        if (!x(p)) //既不是编码器也不是解码器,滤过;
            continue;
        if (strcmp(name, p->name) == 0) //比较名字
            return (AVCodec*)p;
    }
 
    return NULL;//没有找到
}
```

其中调用的av_codec_iterate如下:

```
//传入的是上面的整形值i的地址,二级指针,可以改传入的地址值;
const AVCodec *av_codec_iterate(void **opaque)
{
    uintptr_t i = (uintptr_t)*opaque;
    const AVCodec *c = codec_list[i];
 
    ff_thread_once(&av_codec_static_init, av_codec_init_static);
 
    if (c) //若codec_list不为NULL,继续下一个
        *opaque = (void*)(i + 1); //相当于i++
 
    return c; //返回AVCodec,可能为NULL;
}
```

其中又调用ff_thread_once；

![img](./codec/372e9589795f44a695485b5e67fd8245~noop.image)



# 4. 源码解读avcodec_find_encoder调用流程

avcodec_find_encoder调用了find_codec,

```
static AVCodec *find_codec(enum AVCodecID id, int (*x)(const AVCodec *))
{
    const AVCodec *p, *experimental = NULL;
    void *i = 0;
 
    //看名字是重映射,实际啥都没干;
    id = remap_deprecated_codec_id(id);
 
    while ((p = av_codec_iterate(&i))) { //通过codec_list数组获取AVCodec
        if (!x(p)) //判断是否为编/解码器
            continue;
        if (p->id == id) { //比较ID
 
            //判断编/解码器是否是实验性的,优先选择非实验性的;
            if (p->capabilities & AV_CODEC_CAP_EXPERIMENTAL && !experimental) {
                experimental = p;
            } else
                return (AVCodec*)p;
        }
    }
 
    return (AVCodec*)experimental;
}
```

# 5. 源码解读avcodec_register作用

调用了 ff_thread_once(&av_codec_next_init, av_codec_init_next);

```
static AVOnce av_codec_next_init = AV_ONCE_INIT; //标识只初始化一次
 
static void av_codec_init_next(void)
{
    AVCodec *prev = NULL, *p;
    void *i = 0;
    while ((p = (AVCodec*)av_codec_iterate(&i))) {
        if (prev)
            prev->next = p; //把所有编/解码器连接起来
        prev = p;
    }
}
```

6. 总结


avcodec_find_encoder_by_name查找编码器可以使开发者对系统的控制性更强,但整体兼容性较弱,因为一旦当前使用的FFmpeg不支持指定的编码器,则整个流程将以错误结束;

若使用avcodec_find_encoder,则调用者无法指定特定的编码器进行编码,只能由系统根据优先级自动选择,因此兼容性更好;

实际开发时根据需求选择;

补充说明:

```
#if CONFIG_OSSFUZZ
AVCodec * codec_list[] = {
    NULL,
    NULL,
    NULL
};
#else
#include "libavcodec/codec_list.c"
#endif
```

源码中有codec_list数组,其内容在#include "libavcodec/codec_list.c"当中,但是源码中并没有该文件; 而在编译后的源码中有此文件;所以该文件是编译时根据版本等来生成的;其内容部分如下:

```
static const AVCodec * const codec_list[] = {
    &ff_a64multi_encoder,
    &ff_a64multi5_encoder,
    &ff_alias_pix_encoder,
    &ff_amv_encoder,
    &ff_asv1_encoder,
    &ff_asv2_encoder,
    &ff_avrp_encoder,
    &ff_avui_encoder,
    ...
    ...
};
```



原文链接：ffmpeg源码笔记-查找编解码器(一)_ffmpeg 查看支持的编码器_天未及海宽的博客-CSDN博客