
# FFmpeg编解码处理4-音频编码 #

本文为作者原创，转载请注明出处：https://www.cnblogs.com/leisure_chn/p/10584948.html

FFmpeg 编解码处理系列笔记：

- [0]. [FFmpeg时间戳详解](https://www.cnblogs.com/leisure_chn/p/10584910.html)
- [1]. [FFmpeg编解码处理1-转码全流程简介](https://www.cnblogs.com/leisure_chn/p/10584901.html)
- [2]. [FFmpeg编解码处理2-编解码API详解](https://www.cnblogs.com/leisure_chn/p/10584925.html)
- [3]. [FFmpeg编解码处理3-视频编码](https://www.cnblogs.com/leisure_chn/p/10584937.html)
- [4]. [FFmpeg编解码处理4-音频编码](https://www.cnblogs.com/leisure_chn/p/10584948.html)

基于 FFmpeg 4.1 版本。

# 6. 音频编码 #

编码使用 avcodec_send_frame() 和 avcodec_receive_packet() 两个函数。

音频编码的步骤：

- [1] 初始化打开输出文件时构建编码器上下文
- [2] 音频帧编码
- [2.1] 将滤镜输出的音频帧写入音频 FIFO
- [2.2] 按音频编码器中要求的音频帧尺寸从音频 FIFO 中取出音频帧
- [2.3] 为音频帧生成 pts
- [2.4] 将音频帧送入编码器，从编码器取出编码帧
- [2.5] 更新编码帧流索引
- [2.6] 将帧中时间参数按输出封装格式的时间基进行转换

**6.1 打开视频编码器**

完整源码在 open_output_file() 函数中，下面摘出关键部分：

```
    // 3. 构建AVCodecContext
    if (dec_ctx->codec_type == AVMEDIA_TYPE_VIDEO ||
        dec_ctx->codec_type == AVMEDIA_TYPE_AUDIO)          // 音频流或视频流
    {
        // 3.1 查找编码器AVCodec，本例使用与解码器相同的编码器
        AVCodec *encoder = NULL;
        if ((dec_ctx->codec_type == AVMEDIA_TYPE_VIDEO) && (strcmp(v_enc_name, "copy") != 0))
        {
            encoder = avcodec_find_encoder_by_name(v_enc_name);
        }
        else if ((dec_ctx->codec_type == AVMEDIA_TYPE_AUDIO) && (strcmp(a_enc_name, "copy") != 0))
        {
            encoder = avcodec_find_encoder_by_name(a_enc_name);
        }
        else 
        {
            encoder = avcodec_find_encoder(dec_ctx->codec_id);
        }

        if (!encoder)
        {
            av_log(NULL, AV_LOG_FATAL, "Necessary encoder not found\n");
            return AVERROR_INVALIDDATA;
        }
        // 3.2 AVCodecContext初始化：分配结构体，使用AVCodec初始化AVCodecContext相应成员为默认值
        AVCodecContext *enc_ctx = avcodec_alloc_context3(encoder);
        if (!enc_ctx)
        {
            av_log(NULL, AV_LOG_FATAL, "Failed to allocate the encoder context\n");
            return AVERROR(ENOMEM);
        }

        // 3.3 AVCodecContext初始化：配置图像/声音相关属性
        /* In this example, we transcode to same properties (picture size,
         * sample rate etc.). These properties can be changed for output
         * streams easily using filters */
        if (dec_ctx->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            enc_ctx->height = dec_ctx->height;              // 图像高
            enc_ctx->width = dec_ctx->width;                // 图像宽
            enc_ctx->sample_aspect_ratio = dec_ctx->sample_aspect_ratio; // 采样宽高比：像素宽/像素高
            /* take first format from list of supported formats */
            if (encoder->pix_fmts)  // 编码器支持的像素格式列表
            {
                enc_ctx->pix_fmt = encoder->pix_fmts[0];    // 编码器采用所支持的第一种像素格式
            }
            else
            {
                enc_ctx->pix_fmt = dec_ctx->pix_fmt;        // 编码器采用解码器的像素格式
            }
            /* video time_base can be set to whatever is handy and supported by encoder */
            enc_ctx->time_base = av_inv_q(dec_ctx->framerate);  // 时基：解码器帧率取倒数
            enc_ctx->framerate = dec_ctx->framerate;
            //enc_ctx->bit_rate = dec_ctx->bit_rate;

            /* emit one intra frame every ten frames
            * check frame pict_type before passing frame
            * to encoder, if frame->pict_type is AV_PICTURE_TYPE_I
            * then gop_size is ignored and the output of encoder
            * will always be I frame irrespective to gop_size
            */
            //enc_ctx->gop_size = 10;
            //enc_ctx->max_b_frames = 1;
        }
        else
        {
            enc_ctx->sample_rate = dec_ctx->sample_rate;    // 采样率
            enc_ctx->channel_layout = dec_ctx->channel_layout; // 声道布局
            enc_ctx->channels = av_get_channel_layout_nb_channels(enc_ctx->channel_layout); // 声道数量
            /* take first format from list of supported formats */
            enc_ctx->sample_fmt = encoder->sample_fmts[0];  // 编码器采用所支持的第一种采样格式
            enc_ctx->time_base = (AVRational){1, enc_ctx->sample_rate}; // 时基：编码器采样率取倒数
            // enc_ctx->codec->capabilities |= AV_CODEC_CAP_VARIABLE_FRAME_SIZE; // 只读标志

            // 初始化一个FIFO用于存储待编码的音频帧，初始化FIFO大小的1个采样点
            // av_audio_fifo_alloc()第二个参数是声道数，第三个参数是单个声道的采样点数
            // 采样格式及声道数在初始化FIFO时已设置，各处涉及FIFO大小的地方都是用的单个声道的采样点数
            pp_audio_fifo[i] = av_audio_fifo_alloc(enc_ctx->sample_fmt, enc_ctx->channels, 1);
            if (pp_audio_fifo == NULL)
            {
                av_log(NULL, AV_LOG_ERROR, "Could not allocate FIFO\n");
                return AVERROR(ENOMEM);
            }
        }

        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
        {
            enc_ctx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
        }

        // 3.4 AVCodecContext初始化：使用AVCodec初始化AVCodecContext，初始化完成
        /* Third parameter can be used to pass settings to encoder */
        ret = avcodec_open2(enc_ctx, encoder, NULL);
        if (ret < 0)
        {
            av_log(NULL, AV_LOG_ERROR, "Cannot open video encoder for stream #%u\n", i);
            return ret;
        }
        // 3.5 设置输出流codecpar
        ret = avcodec_parameters_from_context(out_stream->codecpar, enc_ctx);
        if (ret < 0)
        {
            av_log(NULL, AV_LOG_ERROR, "Failed to copy encoder parameters to output stream #%u\n", i);
            return ret;
        }

        // 3.6 保存输出流contex
        pp_enc_ctx[i] = enc_ctx;
    } 
```

**6.2 判断是否需要音频 FIFO**


完整源码在 main() 函数中，下面摘出关键部分：

```
    if (codec_type == AVMEDIA_TYPE_AUDIO) {
        if (((stream.o_codec_ctx->codec->capabilities & AV_CODEC_CAP_VARIABLE_FRAME_SIZE) == 0) &&
            (stream.i_codec_ctx->frame_size != stream.o_codec_ctx->frame_size))
        {
            stream.aud_fifo = oafifo[stream_index];
            ret = transcode_audio_with_afifo(&stream, &ipacket);
        }
        else
        {
            ret = transcode_audio(&stream, &ipacket);
        }
    }
```

解码过程中的音频帧尺寸：

AVCodecContext.frame_size 表示音频帧中每个声道包含的采样点数。当编码器 AV_CODEC_CAP_VARIABLE_FRAME_SIZE 标志有效时，音频帧尺寸是可变的，AVCodecContext.frame_size 值可能为 0；否则，解码器的 AVCodecContext.frame_size 等于解码帧中的 AVFrame.nb_samples。

编码过程中的音频帧尺寸：

上述代码中第一个判断条件是 "(stream.o_codec_ctx->codec->capabilities & AV_CODEC_CAP_VARIABLE_FRAME_SIZE) == 0)", 第二个判断条件是 "(stream.i_codec_ctx->frame_size != stream.o_codec_ctx->frame_size)"。如果编码器不支持可变尺寸音频帧(第一个判断条件生效)，而原始音频帧的尺寸又和编码器帧尺寸不一样(第二个判断条件生效)，则需要引入音频帧 FIFO，以保证每次从 FIFO 中取出的音频帧尺寸和编码器帧尺寸一样。音频 FIFO 输出的音频帧不含时间戳信息，因此需要重新生成时间戳。

引入音频FIFO的原因：

如果编码器不支持可变长度帧，而编码器输入音频帧尺寸和编码器要求的音频帧尺寸不一样，就会编码失败。比如，AAC 音频格式转 MP2 音频格式，AAC 格式音频帧尺寸为 1024，而 MP2 音频编码器要求音频帧尺寸为 1152，编码会失败；再比如 AAC 格式转码 AAC 格式，某些 AAC 音频帧为 2048，而此时若 AAC 音频编码器要求音频帧尺寸为 1024，编码就会失败。解决这个问题的方法有两个，一是进行音频重采样，使音频帧转换为编码器支持的格式；另一个是引入音频 FIFO，一端写一端读，每次从读端取出编码器要求的帧尺寸即可。

AAC 音频帧尺寸可能是 1024，也可能是 2048，参考“FFmpeg关于nb_smples,frame_size以及profile的解释”

**6.3 音频 FIFO 接口函数**

本节代码参考 "https://github.com/FFmpeg/FFmpeg/blob/n4.1/doc/examples/transcode_aac.c" 实现

```
/**
 * Initialize one input frame for writing to the output file.
 * The frame will be exactly frame_size samples large.
 * @param[out] frame                Frame to be initialized
 * @param      output_codec_context Codec context of the output file
 * @param      frame_size           Size of the frame
 * @return Error code (0 if successful)
 */
static int init_audio_output_frame(AVFrame **frame,
                                   AVCodecContext *occtx,
                                   int frame_size)
{
    int error;

    /* Create a new frame to store the audio samples. */
    if (!(*frame = av_frame_alloc()))
    {
        fprintf(stderr, "Could not allocate output frame\n");
        return AVERROR_EXIT;
    }

    /* Set the frame's parameters, especially its size and format.
     * av_frame_get_buffer needs this to allocate memory for the
     * audio samples of the frame.
     * Default channel layouts based on the number of channels
     * are assumed for simplicity. */
    (*frame)->nb_samples     = frame_size;
    (*frame)->channel_layout = occtx->channel_layout;
    (*frame)->format         = occtx->sample_fmt;
    (*frame)->sample_rate    = occtx->sample_rate;

    /* Allocate the samples of the created frame. This call will make
     * sure that the audio frame can hold as many samples as specified. */
    // 为AVFrame分配缓冲区，此函数会填充AVFrame.data和AVFrame.buf，若有需要，也会填充
    // AVFrame.extended_data和AVFrame.extended_buf，对于planar格式音频，会为每个plane
    // 分配一个缓冲区
    if ((error = av_frame_get_buffer(*frame, 0)) < 0)
    {
        fprintf(stderr, "Could not allocate output frame samples (error '%s')\n",
                av_err2str(error));
        av_frame_free(frame);
        return error;
    }

    return 0;
}

// FIFO中可读数据小于编码器帧尺寸，则继续往FIFO中写数据
static int write_frame_to_audio_fifo(AVAudioFifo *fifo,
                                     uint8_t **new_data,
                                     int new_size)
{
    int ret = av_audio_fifo_realloc(fifo, av_audio_fifo_size(fifo) + new_size);
    if (ret < 0)
    {
        fprintf(stderr, "Could not reallocate FIFO\n");
        return ret;
    }
    
    /* Store the new samples in the FIFO buffer. */
    ret = av_audio_fifo_write(fifo, (void **)new_data, new_size);
    if (ret < new_size)
    {
        fprintf(stderr, "Could not write data to FIFO\n");
        return AVERROR_EXIT;
    }

    return 0;
}

static int read_frame_from_audio_fifo(AVAudioFifo *fifo,
                                      AVCodecContext *occtx,
                                      AVFrame **frame)
{
    AVFrame *output_frame;
    // 如果FIFO中可读数据多于编码器帧大小，则只读取编码器帧大小的数据出来
    // 否则将FIFO中数据读完。frame_size是帧中单个声道的采样点数
    const int frame_size = FFMIN(av_audio_fifo_size(fifo), occtx->frame_size);

    /* Initialize temporary storage for one output frame. */
    // 分配AVFrame及AVFrame数据缓冲区
    int ret = init_audio_output_frame(&output_frame, occtx, frame_size);
    if (ret < 0)
    {
        return AVERROR_EXIT;
    }

    // 从FIFO从读取数据填充到output_frame->data中
    ret = av_audio_fifo_read(fifo, (void **)output_frame->data, frame_size);
    if (ret < frame_size)
    {
        fprintf(stderr, "Could not read data from FIFO\n");
        av_frame_free(&output_frame);
        return AVERROR_EXIT;
    }

    *frame = output_frame;

    return ret;
}
```

**6.4 编码音频帧**

完整源码在 transcode_audio_with_afifo() 函数中，下面摘出关键部分：

```
    // 2. 滤镜处理
    ret = filtering_frame(sctx->flt_ctx, frame_dec, frame_flt);
    if (ret == AVERROR_EOF)         // 滤镜已冲洗
    {
        flt_finished = true;
        av_log(NULL, AV_LOG_INFO, "filtering aframe EOF\n");
        frame_flt = NULL;
    }
    else if (ret < 0)
    {
        av_log(NULL, AV_LOG_INFO, "filtering aframe error %d\n", ret);
        goto end;
    }

    // 3. 使用音频fifo，从而保证每次送入编码器的音频帧尺寸满足编码器要求
    // 3.1 将音频帧写入fifo，音频帧尺寸是解码格式中音频帧尺寸
    if (!dec_finished)
    {
        uint8_t** new_data = frame_flt->extended_data;  // 本帧中多个声道音频数据
        int new_size = frame_flt->nb_samples;           // 本帧中单个声道的采样点数
        
        // FIFO中可读数据小于编码器帧尺寸，则继续往FIFO中写数据
        ret = write_frame_to_audio_fifo(p_fifo, new_data, new_size);
        if (ret < 0)
        {
            av_log(NULL, AV_LOG_INFO, "write aframe to fifo error\n");
            goto end;
        }
    }

    // 3.2 从fifo中取出音频帧，音频帧尺寸是编码格式中音频帧尺寸
    // FIFO中可读数据大于编码器帧尺寸，则从FIFO中读走数据进行处理
    while ((av_audio_fifo_size(p_fifo) >= enc_frame_size) || dec_finished)
    {
        bool flushing = dec_finished && (av_audio_fifo_size(p_fifo) == 0);  // 已取空，刷洗编码器
        
        if (frame_enc != NULL)
        {
            av_frame_free(&frame_enc);
        }

        if (!flushing)
        {
            // 从FIFO中读取数据，编码，写入输出文件
            ret = read_frame_from_audio_fifo(p_fifo, sctx->o_codec_ctx, &frame_enc);
            if (ret < 0)
            {
                av_log(NULL, AV_LOG_INFO, "read aframe from fifo error\n");
                goto end;
            }

            // 4. fifo中读取的音频帧没有时间戳信息，重新生成pts
            frame_enc->pts = s_pts;
            s_pts += ret;
        }

flush_encoder:
        // 5. 编码
        ret = av_encode_frame(sctx->o_codec_ctx, frame_enc, &opacket);
        if (ret == AVERROR(EAGAIN))     // 需要获取新的frame喂给编码器
        {
            //av_log(NULL, AV_LOG_INFO, "encode aframe need more packet\n");
            if (frame_enc != NULL)
            {
                av_frame_free(&frame_enc);
            }
            continue;
        }
        else if (ret == AVERROR_EOF)
        {
            av_log(NULL, AV_LOG_INFO, "encode aframe EOF\n");
            enc_finished = true;
            goto end;
        }

        // 5.1 更新编码帧中流序号，并进行时间基转换
        //     AVPacket.pts和AVPacket.dts的单位是AVStream.time_base，不同的封装格式其AVStream.time_base不同
        //     所以输出文件中，每个packet需要根据输出封装格式重新计算pts和dts
        opacket.stream_index = sctx->stream_idx;
        av_packet_rescale_ts(&opacket, sctx->o_codec_ctx->time_base, sctx->o_stream->time_base);
        
        av_log(NULL, AV_LOG_DEBUG, "Muxing frame\n");

        // 6. 将编码后的packet写入输出媒体文件
        ret = av_interleaved_write_frame(sctx->o_fmt_ctx, &opacket);
        if (ret < 0)
        {
            av_log(NULL, AV_LOG_INFO, "write aframe error %d\n", ret);
            goto end;
        }

        if (flushing)
        {
            goto flush_encoder;
        }
    }
```
