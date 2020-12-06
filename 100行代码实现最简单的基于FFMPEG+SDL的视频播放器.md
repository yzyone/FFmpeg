# 100行代码实现最简单的基于FFMPEG+SDL的视频播放器 #

雷霄骅 2013-03-08 23:57:00  6604  收藏 9
分类专栏： FFMPEG 文章标签： ffmpeg 操作系统

## 简介 ##

FFMPEG工程浩大，可以参考的书籍又不是很多，因此很多刚学习FFMPEG的人常常感觉到无从下手。我刚接触FFMPEG的时候也感觉不知从何学起。

因此我把自己做项目过程中实现的一个非常简单的视频播放器（大约100行代码）源代码传上来，以作备忘，同时方便新手学习FFMPEG。

该播放器虽然简单，但是几乎包含了使用FFMPEG播放一个视频所有必备的API，并且使用SDL显示解码出来的视频。

并且支持流媒体等多种视频输入，处于简单考虑，没有音频部分，同时视频播放采用直接延时40ms的方式

平台使用VC2010

使用了新版的FFMPEG类库

## 流程图 ##

没想到这篇文章中介绍的播放器挺受FFMPEG初学者的欢迎，因此再次更新两张流程图，方便大家学习。此外在源代码上添加了注释，方便理解。

该播放器解码的流程用图的方式可以表示称如下形式：



SDL显示YUV图像的流程图：



 

 

 

代码
 
```
int _tmain(int argc, _TCHAR* argv[])
{
	AVFormatContext	*pFormatCtx;
	int				i, videoindex;
	AVCodecContext	*pCodecCtx;
	AVCodec			*pCodec;
	char filepath[]="nwn.mp4";
	av_register_all();//注册组件
	avformat_network_init();//支持网络流
	pFormatCtx = avformat_alloc_context();//初始化AVFormatContext
	if(avformat_open_input(&pFormatCtx,filepath,NULL,NULL)!=0){//打开文件
		printf("无法打开文件\n");
		return -1;
	}
	if(av_find_stream_info(pFormatCtx)<0)//查找流信息
	{
		printf("Couldn't find stream information.\n");
		return -1;
	}
	videoindex=-1;
	for(i=0; i<pFormatCtx->nb_streams; i++) //获取视频流ID
		if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO)
		{
			videoindex=i;
			break;
		}
	if(videoindex==-1)
	{
		printf("Didn't find a video stream.\n");
		return -1;
	}
	pCodecCtx=pFormatCtx->streams[videoindex]->codec;
	pCodec=avcodec_find_decoder(pCodecCtx->codec_id);//查找解码器
	if(pCodec==NULL)
	{
		printf("Codec not found.\n");
		return -1;
	}
	if(avcodec_open(pCodecCtx, pCodec)<0)//打开解码器
	{
		printf("Could not open codec.\n");
		return -1;
	}
	AVFrame	*pFrame,*pFrameYUV;
	pFrame=avcodec_alloc_frame();//存储解码后AVFrame
	pFrameYUV=avcodec_alloc_frame();//存储转换后AVFrame（为什么要转换？后文解释）
	uint8_t *out_buffer;
	out_buffer=new uint8_t[avpicture_get_size(PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height)];//分配AVFrame所需内存
	avpicture_fill((AVPicture *)pFrameYUV, out_buffer, PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height);//填充AVFrame
	//------------SDL初始化--------
	if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER)) {  
		printf( "Could not initialize SDL - %s\n", SDL_GetError()); 
		return -1;
	} 
	SDL_Surface *screen; 
	screen = SDL_SetVideoMode(pCodecCtx->width, pCodecCtx->height, 0, 0);
	if(!screen) {  
		printf("SDL: could not set video mode - exiting\n");  
		return -1;
	}
	SDL_Overlay *bmp; 
	bmp = SDL_CreateYUVOverlay(pCodecCtx->width, pCodecCtx->height,SDL_YV12_OVERLAY, screen); 
	SDL_Rect rect;
	//-----------------------------
	int ret, got_picture;
	static struct SwsContext *img_convert_ctx;
	int y_size = pCodecCtx->width * pCodecCtx->height;
 
	AVPacket *packet=(AVPacket *)malloc(sizeof(AVPacket));//存储解码前数据包AVPacket
	av_new_packet(packet, y_size);
	//输出一下信息-----------------------------
	printf("文件信息-----------------------------------------\n");
	av_dump_format(pFormatCtx,0,filepath,0);
	printf("-------------------------------------------------\n");
	//------------------------------
	while(av_read_frame(pFormatCtx, packet)>=0)//循环获取压缩数据包AVPacket
	{
		if(packet->stream_index==videoindex)
		{
			ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);//解码。输入为AVPacket，输出为AVFrame
			if(ret < 0)
			{
				printf("解码错误\n");
				return -1;
			}
			if(got_picture)
			{
				//像素格式转换。pFrame转换为pFrameYUV。
				img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL); 
				sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
				sws_freeContext(img_convert_ctx);
				//------------SDL显示--------
				SDL_LockYUVOverlay(bmp);
				bmp->pixels[0]=pFrameYUV->data[0];
				bmp->pixels[2]=pFrameYUV->data[1];
				bmp->pixels[1]=pFrameYUV->data[2];     
				bmp->pitches[0]=pFrameYUV->linesize[0];
				bmp->pitches[2]=pFrameYUV->linesize[1];   
				bmp->pitches[1]=pFrameYUV->linesize[2];
				SDL_UnlockYUVOverlay(bmp); 
				rect.x = 0;    
				rect.y = 0;    
				rect.w = pCodecCtx->width;    
				rect.h = pCodecCtx->height;    
				SDL_DisplayYUVOverlay(bmp, &rect); 
				//延时40ms
				SDL_Delay(40);
				//------------SDL-----------
			}
		}
		av_free_packet(packet);
	}
	delete[] out_buffer;
	av_free(pFrameYUV);
	avcodec_close(pCodecCtx);
	avformat_close_input(&pFormatCtx);
 
	return 0;
}
```





## 结果 ##
 

软件运行截图：



完整工程下载地址：

http://download.csdn.net/detail/leixiaohua1020/5122959

完整工程（更新版）下载地址：

http://download.csdn.net/detail/leixiaohua1020/7319153

注1：类库版本2014.5.6，已经支持HEVC以及VP9的解码，附带了这两种视频编码的码流文件。此外修改了个别变更的API函数，并且提高了一些程序的效率。

注2：新版FFmpeg类库Release下出现错误的解决方法如下：
（注：此方法适用于所有近期发布的FFmpeg类库）
VC工程属性里，linker->Optimization->References 选项，改成No(/OPT:NOREF)即可。

Linux下代码下载地址：

http://download.csdn.net/detail/leixiaohua1020/7696879

这个是Linux下的代码，在Ubuntu下测试可以运行，前提是安装了FFmpeg和SDL（版本1.2）。
编译命令：

    gcc simplest_ffmpeg_player.c -g -o smp.out -lSDLmain -lSDL -lavformat -lavcodec -lavutil -lswscale

使用方法：

 

下列命令即可播放同一目录下的test.flv文件。

 

    ./smp.out test.flv
 

FFMPEG相关学习资料
 

SDL GUIDE 中文译本

http://download.csdn.net/detail/leixiaohua1020/6389841
ffdoc （FFMPEG的最完整教程）

http://download.csdn.net/detail/leixiaohua1020/6377803
如何用FFmpeg编写一个简单播放器

http://download.csdn.net/detail/leixiaohua1020/6373783
 
## 补充问题 ##

补充1：旧版程序有一个小BUG，就是sws_getContext()之后，需要调用sws_freeContext()。否则长时间运行的话，会出现内存泄露的状况。更新版已经修复。

此外该工程已经传到SourceForge上了：

https://sourceforge.net/projects/simplestffmpegplayer/

补充2：有人会疑惑，为什么解码后的pFrame不直接用于显示，而是调用swscale()转换之后进行显示？

如果不进行转换，而是直接调用SDL进行显示的话，会发现显示出来的图像是混乱的。关键问题在于解码后的pFrame的linesize里存储的不是图像的宽度，而是比宽度大一些的一个值。其原因目前还没有仔细调查。例如分辨率为480x272的图像，解码后的视频的linesize[0]为512，而不是480。以第1行亮度像素（pFrame->data[0]）为例，从0-480存储的是亮度数据，而从480-512则存储的是无效的数据。因此需要使用swscale()进行转换。转换后去除了无效数据，linesize[0]变为480。就可以正常显示了。



 

 