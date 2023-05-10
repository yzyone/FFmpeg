# [实战小项目之ffmpeg推流yolo视频实时检测](https://www.cnblogs.com/tla001/p/7040344.html)

   之前实现了yolo图像的在线检测，这次主要完成远程视频的检测。主要包括推流--収流--检测显示三大部分

　　首先说一下推流，主要使用ffmpeg命令进行本地摄像头的推流，为了实现首屏秒开使用-g设置gop大小，同时使用-b降低网络负载，保证流畅度。

linux

```
ffmpeg -r 30  -i /dev/video0 -vcodec h264 -max_delay 100 -f flv -g 5 -b 700000 rtmp://219.216.87.170/live/test1
```

 window

```
ffmpeg -r 30  -f vfwcap -i 0 -vcodec h264 -max_delay 100 -f flv -g 5 -b 700000 rtmp://219.216.87.170/live/test1
```

 

```
ffmpeg -list_devices true -f dshow -i dummy  
ffmpeg -r 30  -f dshow -i video="1.3M HD WebCam" -vcodec h264 -max_delay 100 -f flv -g 5 -b 700000 rtmp://219.216.87.170/live/tes
t1
```

 

　　其次是収流，収流最开始的时候，有很大的延迟，大约5秒，后来通过优化，现在延时保证在1s以内，还是可以接收的，直接上収流的程序

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
AVFormatContext *pFormatCtx;
    int i, videoindex;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame, *pFrameRGB;
    uint8_t *out_buffer;
    AVPacket *packet;
    //int y_size;
    int ret, got_picture;
    struct SwsContext *img_convert_ctx;
    //输入文件路径
//    char filepath[] = "rtmp://219.216.87.170/vod/test.flv";
    char filepath[] = "rtmp://219.216.87.170/live/test1";
    int frame_cnt;

    printf("wait for playing %s\n", filepath);
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    printf("size %ld\tduration %ld\n", pFormatCtx->probesize,
            pFormatCtx->max_analyze_duration);
    pFormatCtx->probesize = 20000000;
    pFormatCtx->max_analyze_duration = 2000;
//    pFormatCtx->interrupt_callback.callback = timout_callback;
//    pFormatCtx->interrupt_callback.opaque = pFormatCtx;
//    pFormatCtx->flags |= AVFMT_FLAG_NONBLOCK;

    AVDictionary* options = NULL;
    av_dict_set(&options, "fflags", "nobuffer", 0);
//    av_dict_set(&options, "max_delay", "100000", 0);
//    av_dict_set(&options, "rtmp_transport", "tcp", 0);
//    av_dict_set(&options, "stimeout", "6", 0);

    printf("wating for opening file\n");
    if (avformat_open_input(&pFormatCtx, filepath, NULL, &options) != 0) {
        printf("Couldn't open input stream.\n");
        return -1;
    }
    av_dict_free(&options);
    printf("wating for finding stream\n");
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        printf("Couldn't find stream information.\n");
        return -1;
    }
    videoindex = -1;
    for (i = 0; i < pFormatCtx->nb_streams; i++)
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoindex = i;
            break;
        }
    if (videoindex == -1) {
        printf("Didn't find a video stream.\n");
        return -1;
        }

    pCodecCtx = pFormatCtx->streams[videoindex]->codec;
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if (pCodec == NULL) {
        printf("Codec not found.\n");
        return -1;
        }
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        printf("Could not open codec.\n");
        return -1;
        }
    /*
     * 在此处添加输出视频信息的代码
     * 取自于pFormatCtx，使用fprintf()
     */
    pFrame = av_frame_alloc();
    pFrameRGB = av_frame_alloc();
    out_buffer = (uint8_t *) av_malloc(
            avpicture_get_size(AV_PIX_FMT_BGR24, pCodecCtx->width,
                    pCodecCtx->height));
    avpicture_fill((AVPicture *) pFrameRGB, out_buffer, AV_PIX_FMT_BGR24,
            pCodecCtx->width, pCodecCtx->height);
    packet = (AVPacket *) av_malloc(sizeof(AVPacket));
    //Output Info-----------------------------
    printf("--------------- File Information ----------------\n");
    av_dump_format(pFormatCtx, 0, filepath, 0);
    printf("-------------------------------------------------\n");
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height,
            pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height,
            AV_PIX_FMT_BGR24, SWS_BICUBIC, NULL, NULL, NULL);
    CvSize imagesize;
    imagesize.width = pCodecCtx->width;
    imagesize.height = pCodecCtx->height;
    IplImage *image = cvCreateImageHeader(imagesize, IPL_DEPTH_8U, 3);
    cvSetData(image, out_buffer, imagesize.width * 3);
    cvNamedWindow(filepath, CV_WINDOW_AUTOSIZE);

    frame_cnt = 0;
    int num = 0;
    while (av_read_frame(pFormatCtx, packet) >= 0) {
        if (packet->stream_index == videoindex) {
            /*
             * 在此处添加输出H264码流的代码
             * 取自于packet，使用fwrite()
             */
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture,
                    packet);
            if (ret < 0) {
                printf("Decode Error.\n");
                return -1;
            }
            if (got_picture) {
                sws_scale(img_convert_ctx,
                        (const uint8_t* const *) pFrame->data, pFrame->linesize,
                        0, pCodecCtx->height, pFrameRGB->data,
                        pFrameRGB->linesize);

                printf("Decoded frame index: %d\n", frame_cnt);

                /*
                 * 在此处添加输出YUV的代码
                 * 取自于pFrameYUV，使用fwrite()
                 */

                frame_cnt++;
                cvShowImage(filepath, image);
                cvWaitKey(30);

            }
        }
        av_free_packet(packet);
        }

    sws_freeContext(img_convert_ctx);

    av_frame_free(&pFrameRGB);
    av_frame_free(&pFrame);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);

    return 0;
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

　　将解压后的数据区与opencv的IplImage的数据区映射，实现opencv显示。

　　

　　检测部分，主要使用IplImage与yolo中的图像进行对接，在图像转换方面，进行了部分优化，缩减一些不必要的步骤。然后使用线程区接收ffmepg流，主循环里区做检测并显示。需要做线程同步处理，只有当收到新流时，才去检测。

转载请注明出处：http://www.cnblogs.com/tla001/ 一起学习，一起进步