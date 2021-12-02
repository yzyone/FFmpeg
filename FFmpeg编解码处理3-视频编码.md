
# FFmpeg编解码处理3-视频编码  #

本文为作者原创，转载请注明出处：https://www.cnblogs.com/leisure_chn/p/10584937.html

FFmpeg编解码处理系列笔记：

- [0]. [FFmpeg时间戳详解](https://www.cnblogs.com/leisure_chn/p/10584910.html)
- [1]. [FFmpeg编解码处理1-转码全流程简介](https://www.cnblogs.com/leisure_chn/p/10584901.html)
- [2]. [FFmpeg编解码处理2-编解码API详解](https://www.cnblogs.com/leisure_chn/p/10584925.html)
- [3]. [FFmpeg编解码处理3-视频编码](https://www.cnblogs.com/leisure_chn/p/10584937.html)
- [4]. [FFmpeg编解码处理4-音频编码](https://www.cnblogs.com/leisure_chn/p/10584948.html)

基于 FFmpeg 4.1 版本。

## 5. 视频编码 ##

编码使用 avcodec_send_frame() 和 avcodec_receive_packet() 两个函数。

视频编码的步骤：

- [1] 初始化打开输出文件时构建编码器上下文
- [2] 视频帧编码
- [2.1] 设置帧类型 "frame->pict_type=AV_PICTURE_TYPE_NONE"，让编码器根据设定参数自行生成 I/B/P 帧类型
- [2.2] 将原始帧送入编码器，从编码器取出编码帧
- [2.3] 更新编码帧流索引
- [2.4] 将帧中时间参数按输出封装格式的时间基进行转换

**5.1 打开视频编码器**

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

**5.2 编码视频帧**

完整源码在 transcode_video() 函数中，下面摘出关键部分：

```
    // 2. 滤镜处理
    ret = filtering_frame(sctx->flt_ctx, frame_dec, frame_flt);
    if (ret == AVERROR_EOF)
    {
        av_log(NULL, AV_LOG_INFO, "filtering vframe EOF\n");
        flt_finished = true;
        av_frame_free(&frame_flt);  // flush encoder
    }
    else if (ret < 0)
    {
        av_log(NULL, AV_LOG_INFO, "filtering vframe error %d\n", ret);
        goto end;
    }

flush_encoder:
    // 3. 编码
    if (frame_flt != NULL)
    {
        // 3.1 设置帧类型。如果不设置，则使用输入流中的帧类型。
        frame_flt->pict_type = AV_PICTURE_TYPE_NONE;
    }
    // 3.2 编码
    ret = av_encode_frame(sctx->o_codec_ctx, frame_flt, &opacket);
    if (ret == AVERROR(EAGAIN))     // 需要读取新的packet喂给编码器
    {
        //av_log(NULL, AV_LOG_INFO, "encode vframe need more packet\n");
        goto end;
    }
    else if (ret == AVERROR_EOF)
    {
        av_log(NULL, AV_LOG_INFO, "encode vframe EOF\n");
        enc_finished = true;
        goto end;
    }
    else if (ret < 0)
    {
        av_log(NULL, AV_LOG_ERROR, "encode vframe error %d\n", ret);
        goto end;
    }

    // 3.3 更新编码帧中流序号，并进行时间基转换
    //     AVPacket.pts和AVPacket.dts的单位是AVStream.time_base，不同的封装格式其AVStream.time_base不同
    //     所以输出文件中，每个packet需要根据输出封装格式重新计算pts和dts
    opacket.stream_index = sctx->stream_idx;
    av_packet_rescale_ts(&opacket, sctx->o_codec_ctx->time_base, sctx->o_stream->time_base);

    // 4. 将编码后的packet写入输出媒体文件
    ret = av_interleaved_write_frame(sctx->o_fmt_ctx, &opacket);
    av_packet_unref(&opacket);
```

**5.3 视频编码中的 I/B/P 帧类型**

做一个实验，修改 5.1.2 节 frame_flt->pict_type 值和 5.1.1 节 enc_ctx->gop_size 和 enc_ctx->max_b_frames，将编码后视频帧 I/B/P 类型打印出来，观察实验结果。

我们选一个很短的视频文件用于测试(右键另存为)：tnmil3.flv
迷龙

tnmil3.flv 重命名为 tnmil.flv
转码：tnmil.flv ==> tnmilo1.flv 
命令：./transcode -i tnmil.flv -c:v copy -c:a copy tnmilo1.flv

tnmil.flv ==> tnmilo1.flv 不修改frame IBP类型，不设置编码器gop_size和max_b_frames
IBPBPBPBPBPBBBPBBBPBBBPBBPBBBPBBBPBBPBBBPBBBPBBBPBPBPBBPBBBPBBBPBPBBBPBBBPBPBBPBBBPPIBBP
IBPBPBPBPBPBBBPBBBPBBBPBBPBBBPBBBPBBPBBBPBBBPBBBPBPBPBBPBBBPBBBPBPBBBPBBBPBPBBPBBBPPIBBP

tnmil.flv ==> tnmilo3.flv 将frame IBP类型设为NONE，将编码器gop_size设为10，max_b_frames设为1
IBPBPBPBPBPBBBPBBBPBBBPBBPBBBPBBBPBBPBBBPBBBPBBBPBPBPBBPBBBPBBBPBPBBBPBBBPBPBBPBBBPPIBBP
IBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPPIBPP

tnmilo3.flv ==> tnmilo4.flv 不修改frame IBP类型，不设置编码器gop_size和max_b_frames
IBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPPIBPP
IBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPPIBPP

tnmilo3.flv ==> tnmilo5.flv 将frame IBP类型设为NONE，不设置编码器gop_size(默认-1)和max_b_frames(默认0)
IBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPBPBPBPPIBPPIBPP
IBPBPBPBPBBBPBPBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBBBPBPBBBPPIBBP

实验结论如下：将原始视频帧 frame 送入视频编码器后生成编码帧 packet，那么

- [1] 手工设置每一帧 frame 的帧类型为 I/B/P，则编码后的 packet 的帧类型和 frame 中的一样。编码器是否设置 gop_size 和 max_b_frames 两个参数无影响。
- [2] 将每一帧 frame 的帧类型设置为 NONE，如果未设置编码器的 gop_size(默认值 -1)和 max_b_frames (默认值 0)两个参数，则编码器自动选择合适参数来进行编码，生成帧类型。
- [3] 将每一帧 frame 的帧类型设置为 NONE，如果设置了编码器的 gop_size 和 max_b_frames 两个参数，则编码器按照这两个参数来进行编码，生成帧类型。