# ffmpeg进行rtmp推流源码

依赖环境：

https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-full-shared.7z

代码：

```
#include <iostream>
#include "string.h"

extern "C" 
{
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
#include "libavutil/time.h"
#include <libavutil/log.h>
}

using namespace std;
//
#include <stdio.h>
#define __STDC_CONSTANT_MACROS
#define USE_H264BSF 0

void printErrWithCode(int errCode) {
	char buf[1024] = { 0 };
	av_strerror(errCode, buf, sizeof(buf));
	cout << buf << endl;
	return;
}

int main() {
	AVFormatContext *ictx = NULL;
	AVFormatContext *octx = NULL;
	string in_path = "1.mp4";
	string out_path = "rtmp://127.0.0.1:1935/live/123";
	int ret = 0;
	avformat_network_init();

	//打开文件，解封装协议头
	//类似于mp4都有文件头，文件头里放了所有的文件信息。
	ret = avformat_open_input(&ictx, in_path.c_str(), 0, 0);
	if (ret) {
		printErrWithCode(ret);
	}
	ret = avformat_find_stream_info(ictx, NULL);
	av_dump_format(ictx, 0, in_path.c_str(), false);
	 
	//第二个参数是输出格式
	ret = avformat_alloc_output_context2(&octx, NULL, "flv", out_path.c_str());
	 
	if (!octx) {
		printErrWithCode(ret);
	}
	 
	//遍历所有输出流
	for (int i = 0; i < ictx->nb_streams; i++) {
		//创建一个输出流
		AVStream *out = avformat_new_stream(octx, ictx->streams[i]->codec->codec);
		if (!out) {
			ret = 0;
			printErrWithCode(ret);
		}
	 
		//将输入流的配置信息（AVCodecContext）复制到输出流中
		//上面这种是老的方式，下面这种是新的，但是对mp4文件可能会有问题
		avcodec_copy_context(out->codec, ictx->streams[i]->codec);		//avi有问题，mp4没问题,flv没问题，rmvb有问题
		//avcodec_parameters_copy(out->codecpar, ictx->streams[i]->codecpar);   //mp4有问题,avi有问题，rmvb有问题，flv没问题
		out->codec->codec_tag = 0;
	}
	av_dump_format(octx, 0, out_path.c_str(), true);
	 
	//打开流，写入头信息，至此，输出上下文建立完成
	//ret = avio_open(&octx->pb, out_path.c_str(), AVIO_FLAG_WRITE);
	ret = avio_open(&octx->pb, out_path.c_str(), 2);
	if (!octx->pb) {
		printErrWithCode(ret);
	}
	ret = avformat_write_header(octx, 0);
	if (ret < 0) {
		printErrWithCode(ret);
	}
	 
	//推流每一帧数据
	AVPacket pkt;
	long long startTime = av_gettime(); //获取当前的时间戳（微秒）
	while (1) {
		ret = av_read_frame(ictx, &pkt);    //这一步虽然名字叫 read_frame，但实际上读取出来的是 packet
		if (ret) {
			printErrWithCode(ret);
		}
		//计算转换 pts dts（time base可能不同）（但是实际上，段点调试发现time_base是相同的，不知道是哪一步复制的time_base）
//        AVRational itime = ictx->streams[pkt.stream_index]->time_base;
//        AVRational otime = octx->streams[pkt.stream_index]->time_base;
//        pkt.pts = av_rescale_q_rnd(pkt.pts, itime, otime,
//                    (AVRounding)(AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX));
//        pkt.dts = av_rescale_q_rnd(pkt.dts, itime,otime,
//                    (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
//        pkt.duration = av_rescale_q_rnd(pkt.duration, itime, otime,
//                    (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
//        pkt.pos = -1;

		//这里假设网络传输是没问题的，那么我们应该在dts也就是解码时间进行推流。
		//如果推流时间早于解码时间，那么就等一会儿。
		if (ictx->streams[pkt.stream_index]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
			AVRational tb = ictx->streams[pkt.stream_index]->time_base;
			long long now = av_gettime() - startTime;
			long long dts = pkt.dts * (1000 * 1000 * av_q2d(tb)); //将秒转化为微秒
			if (dts > now) {
				av_usleep(dts - now);
			}
		}
		//根据pts dts进行排序，然后写入（由于是网络流，这一段就是网络传输）
		ret = av_interleaved_write_frame(octx, &pkt);
		if (ret < 0) {
			printErrWithCode(ret);
		}
		av_packet_unref(&pkt);
	}
}
```

————————————————

版权声明：本文为CSDN博主「aspiretop」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/ljjjjjjjjjjj/article/details/124697800