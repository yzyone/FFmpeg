
# FFmpeg编解码处理2-编解码API详解 #

本文为作者原创，转载请注明出处：https://www.cnblogs.com/leisure_chn/p/10584925.html

FFmpeg编解码处理系列笔记：

- [0]. [FFmpeg时间戳详解](https://www.cnblogs.com/leisure_chn/p/10584910.html)
- [1]. [FFmpeg编解码处理1-转码全流程简介](https://www.cnblogs.com/leisure_chn/p/10584901.html)
- [2]. [FFmpeg编解码处理2-编解码API详解](https://www.cnblogs.com/leisure_chn/p/10584925.html)
- [3]. [FFmpeg编解码处理3-视频编码](https://www.cnblogs.com/leisure_chn/p/10584937.html)
- [4]. [FFmpeg编解码处理4-音频编码](https://www.cnblogs.com/leisure_chn/p/10584948.html)

基于FFmpeg 4.1版本。

## 4. 编解码API详解 ##
 
解码使用 avcodec_send_packet() 和 avcodec_receive_frame() 两个函数。

编码使用 avcodec_send_frame() 和 avcodec_receive_packet() 两个函数。

**4.1 API定义**

**4.1.1 avcodec_send_packet()**

```
/**
 * Supply raw packet data as input to a decoder.
 *
 * Internally, this call will copy relevant AVCodecContext fields, which can
 * influence decoding per-packet, and apply them when the packet is actually
 * decoded. (For example AVCodecContext.skip_frame, which might direct the
 * decoder to drop the frame contained by the packet sent with this function.)
 *
 * @warning The input buffer, avpkt->data must be AV_INPUT_BUFFER_PADDING_SIZE
 *          larger than the actual read bytes because some optimized bitstream
 *          readers read 32 or 64 bits at once and could read over the end.
 *
 * @warning Do not mix this API with the legacy API (like avcodec_decode_video2())
 *          on the same AVCodecContext. It will return unexpected results now
 *          or in future libavcodec versions.
 *
 * @note The AVCodecContext MUST have been opened with @ref avcodec_open2()
 *       before packets may be fed to the decoder.
 *
 * @param avctx codec context
 * @param[in] avpkt The input AVPacket. Usually, this will be a single video
 *                  frame, or several complete audio frames.
 *                  Ownership of the packet remains with the caller, and the
 *                  decoder will not write to the packet. The decoder may create
 *                  a reference to the packet data (or copy it if the packet is
 *                  not reference-counted).
 *                  Unlike with older APIs, the packet is always fully consumed,
 *                  and if it contains multiple frames (e.g. some audio codecs),
 *                  will require you to call avcodec_receive_frame() multiple
 *                  times afterwards before you can send a new packet.
 *                  It can be NULL (or an AVPacket with data set to NULL and
 *                  size set to 0); in this case, it is considered a flush
 *                  packet, which signals the end of the stream. Sending the
 *                  first flush packet will return success. Subsequent ones are
 *                  unnecessary and will return AVERROR_EOF. If the decoder
 *                  still has frames buffered, it will return them after sending
 *                  a flush packet.
 *
 * @return 0 on success, otherwise negative error code:
 *      AVERROR(EAGAIN):   input is not accepted in the current state - user
 *                         must read output with avcodec_receive_frame() (once
 *                         all output is read, the packet should be resent, and
 *                         the call will not fail with EAGAIN).
 *      AVERROR_EOF:       the decoder has been flushed, and no new packets can
 *                         be sent to it (also returned if more than 1 flush
 *                         packet is sent)
 *      AVERROR(EINVAL):   codec not opened, it is an encoder, or requires flush
 *      AVERROR(ENOMEM):   failed to add packet to internal queue, or similar
 *      other errors: legitimate decoding errors
 */
int avcodec_send_packet(AVCodecContext *avctx, const AVPacket *avpkt);
```

**4.1.2 avcodec_receive_frame()**

```
/**
 * Return decoded output data from a decoder.
 *
 * @param avctx codec context
 * @param frame This will be set to a reference-counted video or audio
 *              frame (depending on the decoder type) allocated by the
 *              decoder. Note that the function will always call
 *              av_frame_unref(frame) before doing anything else.
 *
 * @return
 *      0:                 success, a frame was returned
 *      AVERROR(EAGAIN):   output is not available in this state - user must try
 *                         to send new input
 *      AVERROR_EOF:       the decoder has been fully flushed, and there will be
 *                         no more output frames
 *      AVERROR(EINVAL):   codec not opened, or it is an encoder
 *      other negative values: legitimate decoding errors
 */
int avcodec_receive_frame(AVCodecContext *avctx, AVFrame *frame);
```

**4.1.3 avcodec_send_frame()**

```
/**
 * Supply a raw video or audio frame to the encoder. Use avcodec_receive_packet()
 * to retrieve buffered output packets.
 *
 * @param avctx     codec context
 * @param[in] frame AVFrame containing the raw audio or video frame to be encoded.
 *                  Ownership of the frame remains with the caller, and the
 *                  encoder will not write to the frame. The encoder may create
 *                  a reference to the frame data (or copy it if the frame is
 *                  not reference-counted).
 *                  It can be NULL, in which case it is considered a flush
 *                  packet.  This signals the end of the stream. If the encoder
 *                  still has packets buffered, it will return them after this
 *                  call. Once flushing mode has been entered, additional flush
 *                  packets are ignored, and sending frames will return
 *                  AVERROR_EOF.
 *
 *                  For audio:
 *                  If AV_CODEC_CAP_VARIABLE_FRAME_SIZE is set, then each frame
 *                  can have any number of samples.
 *                  If it is not set, frame->nb_samples must be equal to
 *                  avctx->frame_size for all frames except the last.
 *                  The final frame may be smaller than avctx->frame_size.
 * @return 0 on success, otherwise negative error code:
 *      AVERROR(EAGAIN):   input is not accepted in the current state - user
 *                         must read output with avcodec_receive_packet() (once
 *                         all output is read, the packet should be resent, and
 *                         the call will not fail with EAGAIN).
 *      AVERROR_EOF:       the encoder has been flushed, and no new frames can
 *                         be sent to it
 *      AVERROR(EINVAL):   codec not opened, refcounted_frames not set, it is a
 *                         decoder, or requires flush
 *      AVERROR(ENOMEM):   failed to add packet to internal queue, or similar
 *      other errors: legitimate decoding errors
 */
int avcodec_send_frame(AVCodecContext *avctx, const AVFrame *frame);
```

**4.1.4 avcodec_receive_packet()**

```
/**
 * Read encoded data from the encoder.
 *
 * @param avctx codec context
 * @param avpkt This will be set to a reference-counted packet allocated by the
 *              encoder. Note that the function will always call
 *              av_frame_unref(frame) before doing anything else.
 * @return 0 on success, otherwise negative error code:
 *      AVERROR(EAGAIN):   output is not available in the current state - user
 *                         must try to send input
 *      AVERROR_EOF:       the encoder has been fully flushed, and there will be
 *                         no more output packets
 *      AVERROR(EINVAL):   codec not opened, or it is an encoder
 *      other errors: legitimate decoding errors
 */
int avcodec_receive_packet(AVCodecContext *avctx, AVPacket *avpkt);
```

**4.2 API使用说明**

**4.2.1 解码API使用详解**

关于 avcodec_send_packet() 与 avcodec_receive_frame() 的使用说明：

[1] 按 dts 递增的顺序向解码器送入编码帧 packet，解码器按 pts 递增的顺序输出原始帧 frame，实际上解码器不关注输入 packe t的 dts(错值都没关系)，它只管依次处理收到的 packet，按需缓冲和解码

[2] avcodec_receive_frame() 输出 frame 时，会根据各种因素设置好 frame->best_effort_timestamp(文档明确说明)，实测 frame->pts 也会被设置(通常直接拷贝自对应的 packet.pts，文档未明确说明)用户应确保 avcodec_send_packet() 发送的 packet 具有正确的 pts，编码帧 packet 与原始帧 frame 间的对应关系通过 pts 确定

[3] avcodec_receive_frame() 输出 frame 时，frame->pkt_dts 拷贝自当前avcodec_send_packet() 发送的 packet 中的 dts，如果当前 packet 为 NULL(flush packet)，解码器进入 flush 模式，当前及剩余的 frame->pkt_dts 值总为 AV_NOPTS_VALUE。因为解码器中有缓存帧，当前输出的 frame 并不是由当前输入的 packet 解码得到的，所以这个 frame->pkt_dts 没什么实际意义，可以不必关注

[4] avcodec_send_packet() 发送第一个 NULL 会返回成功，后续的 NULL 会返回 AVERROR_EOF

[5] avcodec_send_packet() 多次发送 NULL 并不会导致解码器中缓存的帧丢失，使用 avcodec_flush_buffers() 可以立即丢掉解码器中缓存帧。因此播放完毕时应 avcodec_send_packet(NULL) 来取完缓存的帧，而 SEEK 操作或切换流时应调用 avcodec_flush_buffers() 来直接丢弃缓存帧

[6] 解码器通常的冲洗方法：调用一次 avcodec_send_packet(NULL)(返回成功)，然后不停调用 avcodec_receive_frame() 直到其返回 AVERROR_EOF，取出所有缓存帧，avcodec_receive_frame() 返回 AVERROR_EOF 这一次是没有有效数据的，仅仅获取到一个结束标志

**4.2.2 编码API使用详解**

关于 avcodec_send_frame() 与 avcodec_receive_packet() 的使用说明：

[1] 按 pts 递增的顺序向编码器送入原始帧 frame，编码器按 dts 递增的顺序输出编码帧 packet，实际上编码器关注输入 frame 的 pts 不关注其 dts，它只管依次处理收到的 frame，按需缓冲和编码

[2] avcodec_receive_packet() 输出 packet 时，会设置 packet.dts，从 0 开始，每次输出的 packet 的 dts 加 1，这是视频层的 dts，用户写输出前应将其转换为容器层的 dts

[3] avcodec_receive_packet() 输出 packet 时，packet.pts 拷贝自对应的 frame.pts，这是视频层的 pts，用户写输出前应将其转换为容器层的 pts

[4] avcodec_send_frame() 发送 NULL frame 时，编码器进入 flush 模式

[5] avcodec_send_frame() 发送第一个 NULL 会返回成功，后续的 NULL 会返回 AVERROR_EOF

[6] avcodec_send_frame() 多次发送 NULL 并不会导致编码器中缓存的帧丢失，使用 avcodec_flush_buffers() 可以立即丢掉编码器中缓存帧。因此编码完毕时应使用 avcodec_send_frame(NULL) 来取完缓存的帧，而SEEK操作或切换流时应调用 avcodec_flush_buffers() 来直接丢弃缓存帧

[7] 编码器通常的冲洗方法：调用一次 avcodec_send_frame(NULL)(返回成功)，然后不停调用 avcodec_receive_packet() 直到其返回 AVERROR_EOF，取出所有缓存帧，avcodec_receive_packet() 返回 AVERROR_EOF 这一次是没有有效数据的，仅仅获取到一个结束标志

[8] 对音频来说，如果 AV_CODEC_CAP_VARIABLE_FRAME_SIZE(在 AVCodecContext.codec.capabilities 变量中，只读)标志有效，表示编码器支持可变尺寸音频帧，送入编码器的音频帧可以包含任意数量的采样点。如果此标志无效，则每一个音频帧的采样点数目(frame->nb_samples)必须等于编码器设定的音频帧尺寸(avctx->frame_size)，最后一帧除外，最后一帧音频帧采样点数可以小于 avctx->frame_size

**4.3 API使用例程**

**4.3.1 解码API例程**

```
// retrun 0:                got a frame success
//        AVERROR(EAGAIN):  need more packet
//        AVERROR_EOF:      end of file, decoder has been flushed
//        <0:               error
int av_decode_frame(AVCodecContext *dec_ctx, AVPacket *packet, bool *new_packet, AVFrame *frame)
{
    int ret = AVERROR(EAGAIN);

    while (1)
    {
        // 2. 从解码器接收frame
        if (dec_ctx->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            // 2.1 一个视频packet含一个视频frame
            //     解码器缓存一定数量的packet后，才有解码后的frame输出
            //     frame输出顺序是按pts的顺序，如IBBPBBP
            //     frame->pkt_pos变量是此frame对应的packet在视频文件中的偏移地址，值同pkt.pos
            ret = avcodec_receive_frame(dec_ctx, frame);
            if (ret >= 0)
            {
                if (frame->pts == AV_NOPTS_VALUE)
                {
                    frame->pts = frame->best_effort_timestamp;
                    printf("set video pts %d\n", frame->pts);
                }
            }
        }
        else if (dec_ctx->codec_type ==  AVMEDIA_TYPE_AUDIO)
        {
            // 2.2 一个音频packet含一至多个音频frame，每次avcodec_receive_frame()返回一个frame，此函数返回。
            //     下次进来此函数，继续获取一个frame，直到avcodec_receive_frame()返回AVERROR(EAGAIN)，
            //     表示解码器需要填入新的音频packet
            ret = avcodec_receive_frame(dec_ctx, frame);
            if (ret >= 0)
            {
                if (frame->pts == AV_NOPTS_VALUE)
                {
                    frame->pts = frame->best_effort_timestamp;
                    printf("set audio pts %d\n", frame->pts);
                }
            }
        }

        if (ret >= 0)                   // 成功解码得到一个视频帧或一个音频帧，则返回
        {
            return ret;   
        }
        else if (ret == AVERROR_EOF)    // 解码器已冲洗，解码中所有帧已取出
        {
            avcodec_flush_buffers(dec_ctx);
            return ret;
        }
        else if (ret == AVERROR(EAGAIN))// 解码器需要喂数据
        {
            if (!(*new_packet))         // 本函数中已向解码器喂过数据，因此需要从文件读取新数据
            {
                //av_log(NULL, AV_LOG_INFO, "decoder need more packet\n");
                return ret;
            }
        }
        else                            // 错误
        {
            av_log(NULL, AV_LOG_ERROR, "decoder error %d\n", ret);
            return ret;
        }

        /*
        if (packet == NULL || (packet->data == NULL && packet->size == 0))
        {
            // 复位解码器内部状态/刷新内部缓冲区。当seek操作或切换流时应调用此函数。
            avcodec_flush_buffers(dec_ctx);
        }
        */

        // 1. 将packet发送给解码器
        //    发送packet的顺序是按dts递增的顺序，如IPBBPBB
        //    pkt.pos变量可以标识当前packet在视频文件中的地址偏移
        //    发送第一个 flush packet 会返回成功，后续的 flush packet 会返回AVERROR_EOF
        ret = avcodec_send_packet(dec_ctx, packet);
        *new_packet = false;
        
        if (ret != 0)
        {
            av_log(NULL, AV_LOG_ERROR, "avcodec_send_packet() error, return %d\n", ret);
            return ret;
        }
    }

    return -1;
}
```

4.3.2 编码API例程

```
int av_encode_frame(AVCodecContext *enc_ctx, AVFrame *frame, AVPacket *packet)
{
    int ret = -1;
    
    // 第一次发送flush packet会返回成功，进入冲洗模式，可调用avcodec_receive_packet()
    // 将编码器中缓存的帧(可能不止一个)取出来
    // 后续再发送flush packet将返回AVERROR_EOF
    ret = avcodec_send_frame(enc_ctx, frame);
    if (ret == AVERROR_EOF)
    {
        //av_log(NULL, AV_LOG_INFO, "avcodec_send_frame() encoder flushed\n");
    }
    else if (ret == AVERROR(EAGAIN))
    {
        //av_log(NULL, AV_LOG_INFO, "avcodec_send_frame() need output read out\n");
    }
    else if (ret < 0)
    {
        //av_log(NULL, AV_LOG_INFO, "avcodec_send_frame() error %d\n", ret);
        return ret;
    }

    ret = avcodec_receive_packet(enc_ctx, packet);
    if (ret == AVERROR_EOF)
    {
        av_log(NULL, AV_LOG_INFO, "avcodec_recieve_packet() encoder flushed\n");
    }
    else if (ret == AVERROR(EAGAIN))
    {
        //av_log(NULL, AV_LOG_INFO, "avcodec_recieve_packet() need more input\n");
    }
    
    return ret;
}
```