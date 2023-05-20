# 开源ffmpeg（三）——音频拉流、解码以及重采样

2023-05-12 10:45·[音视频流媒体技术](https://www.toutiao.com/c/user/token/MS4wLjABAAAA21_fy3ikLEGHBFg0FPTOpP6rkmW8pqu43JJD_Z4rxQmWOXc7WdKZfBON0djDMRd1/?source=tuwen_detail)

前言

对于ffmpeg介绍和如何输出ffmpeg日志可以参照之前的博客。

该篇博客是用于学习如何使用ffmpeg进行读取音频（包括本地和远端），并对读取流进行音频解码、以及进行重采样的操作。如果现在看官对于音频解码不是很熟悉，建议可以多看看雷神的文章，膜拜+缅怀雷神。

这里有对于音频解码基础的介绍：

视音频编解码技术零基础学习方法

PCM音频数据格式介绍

一、API介绍

1.流程介绍

下文会把一些主要的API做个介绍，我们可以简单理解使用这些API的主要目的就是为了获取：流上下文、解码器、重采样工具。

流上下文：用于读包

解码器：将读取的包进行解码为pcm

重采样工具：将pcm数据重采样为需要的格式

接下来就是拉流、解码、重采样的一个基础流程：

其中每个框都代表一个线程，当然，播放并未体现在本文中。而且值得注意的是：读包后塞入编码器，和获取解码数据可以放在不同的线程中，特别是在做视频工作的时候。因为在做解码工作和重采样时，是一件十分耗时的事情，我们不应该让解码阻塞住读包的过程。 相对于视频解码，音频解码是一个快速的事情。

![img](./codec/39ff5837ef71431cacee28953a194dc8~noop.image)



2.主要API介绍

![img](./codec/cae8ee91920b4d0da06784eb6d3bdc7f~noop.image)



3.备注

由于笔者这边使用的是ffmpeg 4.4，与老版本是有一些差别的，例如：

一些API是已经废弃的，例如以下API是为了初始化ffmpeg的库：

av_register_all

avformat_network_init

又有一些API是被替换了的，例如以下API是为了对于寻解码器、释放包等：

avcodec_decode_audio4

av_free_packet

avcodec_alloc_context3

虽然已经废弃，但是还是接口还是保留下来的，只要在使用的时候小心一点即可



# 二、代码实例

# 1.头文件

```
#pragma once

extern "C" {
#include "include/libavformat/avformat.h"
#include "include/libavcodec/avcodec.h"
#include "include/libavutil/avutil.h"
#include "include/libswresample/swresample.h"
}

#include <iostream>
#include <mutex>
#include <Windows.h> 

namespace AudioReadFrame
{

#define MAX_AUDIO_FRAME_SIZE	192000 // 1 second of 48khz 16bit audio 2 channel

	//自定义结构体存储信息
	struct FileAudioInst
	{
		long long duration;    ///< second
		long long curl_time;   ///< second
		int sample_rate;       ///< samples per second
		int channels;          ///< number of audio channels
		FileAudioInst()
		{
			duration = 0;
			curl_time = 0;
			sample_rate = 0;
			channels = 0;
		}
	};

	//拉流线程状态
	enum ThreadState
	{
		run = 1,
		exit,
	};

	class CAudioReadFrame
	{
	public:
		CAudioReadFrame();
		~CAudioReadFrame();

	public:
		//加载流文件
		bool LoadAudioFile(const char* pAudioFilePath);
		//开始读流
		bool StartReadFile();
		//停止读流
		bool StopReadFile();

	private:
		//释放资源
		bool FreeResources();
		//改变拉流线程的装填
		void ChangeThreadState(ThreadState eThreadState);
		//拉流线程
		void ReadFrameThreadProc();
		//utf转GBK
		std::string UTF8ToGBK(const std::string& strUTF8);

	private:
		typedef std::unique_ptr<std::thread> ThreadPtr;

		//目的是为了重定向输出ffmpeg日志到本地文件
#define PRINT_LOG 0
#ifdef PRINT_LOG
	private:
		static FILE* m_pLogFile;
		static void LogCallback(void* ptr, int level, const char* fmt, va_list vl);
#endif

		//目的是为了将拉流数据dump下来
#define DUMP_AUDIO 1
#ifdef DUMP_AUDIO
		FILE*					decode_file;
#endif // DUMP_FILE


	private:
		bool					m_bIsReadyForRead;
		int						m_nStreamIndex;
		uint8_t*				m_pSwrBuffer;
		std::mutex				m_lockResources;
		std::mutex				m_lockThread;
		FileAudioInst*			m_pFileAudioInst;
		ThreadPtr				m_pReadFrameThread;
		ThreadState				m_eThreadState;

	private:
		SwrContext*				m_pSwrContext;		//重采样
		AVFrame*				m_pAVFrame;			//音频包
		AVCodec*				m_pAVCodec;			//编解码器
		AVPacket*				m_pAVPack;			//读包
		AVCodecParameters *		m_pAVCodecParameters; //编码参数
		AVCodecContext*			m_pAVCodecContext;	//解码上下文
		AVFormatContext*		m_pAVFormatContext;	//IO上下文
	};
}
```

2.源文件

```
#include "CAudioReadFrame.h"
#include <sstream>

namespace AudioReadFrame
{
#ifdef FFMPEG_LOG_OUT
	FILE* CAudioReadFrame::m_pLogFile = nullptr;
	void CAudioReadFrame::LogCallback(void* ptr, int level, const char* fmt, va_list vl)
	{
		if (m_pLogFile == nullptr)
		{
			m_pLogFile = fopen("E:\\log\\log.txt", "w+");
}

		if (m_pLogFile)
		{
			vfprintf(m_pLogFile, fmt, vl);
			fflush(m_pLogFile);
		}
	}
#endif

	CAudioReadFrame::CAudioReadFrame()
	{
		std::cout << av_version_info() << std::endl;
#if DUMP_AUDIO
		decode_file = fopen("E:\\log\\decode_file.pcm", "wb+");
#endif
	}

	CAudioReadFrame::~CAudioReadFrame()
	{
#if DUMP_AUDIO
		if (decode_file) {
			fclose(decode_file);
			decode_file = nullptr;
		}
#endif
		StopReadFile();
	}

	bool CAudioReadFrame::LoadAudioFile(const char* pAudioFilePath)
	{
#ifdef FFMPEG_LOG_OUT
		if (m_pLogFile != nullptr)
		{
			fclose(m_pLogFile);
			m_pLogFile = nullptr;
		}
		time_t t = time(nullptr);
		struct tm* now = localtime(&t);

		std::stringstream time;

		time << now->tm_year + 1900 << "/";
		time << now->tm_mon + 1 << "/";
		time << now->tm_mday << "/";
		time << now->tm_hour << ":";
		time << now->tm_min << ":";
		time << now->tm_sec << std::endl;

		std::cout << time.str();
		av_log_set_level(AV_LOG_TRACE); //设置日志级别
		av_log_set_callback(LogCallback);
		av_log(NULL, AV_LOG_INFO, time.str().c_str());
#endif

		ChangeThreadState(ThreadState::exit);
		FreeResources();

		av_log_set_level(AV_LOG_TRACE); //设置日志级别
		av_log(NULL, AV_LOG_DEBUG, "the debug line:%d, string:%s", __LINE__, "hello");

		m_nStreamIndex = -1;
		m_pAVFormatContext = avformat_alloc_context();
		m_pAVFrame = av_frame_alloc();
		m_pSwrContext = swr_alloc();
		m_pFileAudioInst = new FileAudioInst;
		m_pSwrBuffer = (uint8_t *)av_malloc(MAX_AUDIO_FRAME_SIZE);
		m_pAVPack = av_packet_alloc();

		//Open an input stream and read the header
		if (avformat_open_input(&m_pAVFormatContext, pAudioFilePath, NULL, NULL) != 0) {
			av_log(NULL, AV_LOG_ERROR, "Couldn't open input stream.\n");
			return false;
		}

		//Read packets of a media file to get stream information
		if (avformat_find_stream_info(m_pAVFormatContext, NULL) < 0) {
			av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information.\n");
			return false;
		}

		for (unsigned int i = 0; i < m_pAVFormatContext->nb_streams; i++)
		{
			//因为一个url可以包含多股，如果存在多股流，找到音频流,因为现在只读MP3，所以只找音频流
			if (m_pAVFormatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
				m_nStreamIndex = i;
				break;
			}
		}

		if (m_nStreamIndex == -1) {
			av_log(NULL, AV_LOG_ERROR, "Didn't find a audio stream.\n");
			return false;
		}

		m_pAVCodecParameters = m_pAVFormatContext->streams[m_nStreamIndex]->codecpar;
		m_pAVCodec = (AVCodec *)avcodec_find_decoder(m_pAVCodecParameters->codec_id);

		// Open codec
		m_pAVCodecContext = avcodec_alloc_context3(m_pAVCodec);
		avcodec_parameters_to_context(m_pAVCodecContext, m_pAVCodecParameters);
		if (avcodec_open2(m_pAVCodecContext, m_pAVCodec, NULL) < 0) {
			av_log(NULL, AV_LOG_ERROR, "Could not open codec.\n");
			return false;
		}

		//初始化重采样 采样率为双通 short， 48k
		AVChannelLayout outChannelLayout;
		AVChannelLayout inChannelLayout;
		outChannelLayout.nb_channels = 2;
		inChannelLayout.nb_channels = m_pAVCodecContext->ch_layout.nb_channels;
		if (swr_alloc_set_opts2(&m_pSwrContext, &outChannelLayout, AV_SAMPLE_FMT_S16, 48000,
			&inChannelLayout, m_pAVCodecContext->sample_fmt, m_pAVCodecContext->sample_rate, 0, NULL)
			!= 0)
		{
			av_log(NULL, AV_LOG_ERROR, "swr_alloc_set_opts2 fail.\n");
			return false;
		}
		swr_init(m_pSwrContext);
		//保留流信息
		m_pFileAudioInst->duration = m_pAVFormatContext->duration / 1000;//ms
		m_pFileAudioInst->channels = m_pAVCodecParameters->ch_layout.nb_channels;
		m_pFileAudioInst->sample_rate = m_pAVCodecParameters->sample_rate;

		m_bIsReadyForRead = true;

		return true;
	}

	bool CAudioReadFrame::StartReadFile()
	{
		if (!m_bIsReadyForRead)
		{
			av_log(NULL, AV_LOG_ERROR, "File not ready");
			return false;
		}

		if (m_pReadFrameThread != nullptr)
		{
			if (m_pReadFrameThread->joinable())
			{
				m_pReadFrameThread->join();
				m_pReadFrameThread.reset(nullptr);
			}
		}

		ChangeThreadState(ThreadState::run);
		m_pReadFrameThread.reset(new std::thread(&CAudioReadFrame::ReadFrameThreadProc, this));
		return true;
	}

	bool CAudioReadFrame::StopReadFile()
	{
		ChangeThreadState(ThreadState::exit);
		if (m_pReadFrameThread != nullptr)
		{
			if (m_pReadFrameThread->joinable())
			{
				m_pReadFrameThread->join();
				m_pReadFrameThread.reset(nullptr);
			}
		}

		FreeResources();
		return true;
	}

	void CAudioReadFrame::ReadFrameThreadProc()
	{
		while (true)
		{
			if (m_eThreadState == ThreadState::exit)
			{
				break;
			}

			//读取一个包
			int nRet = av_read_frame(m_pAVFormatContext, m_pAVPack);
			if (nRet != 0)
			{
				std::stringstream logInfo;
				logInfo << "read frame no data error:" << nRet << std::endl;
				av_log(NULL, AV_LOG_ERROR, logInfo.str().c_str());
				ChangeThreadState(ThreadState::exit);
				continue;
			}

			//判断读取流是否正确
			if (m_pAVPack->stream_index != m_nStreamIndex)
			{
				std::stringstream logInfo;
				logInfo << "read frame no data error:" << std::endl;
				av_log(NULL, AV_LOG_ERROR, logInfo.str().c_str());
				continue;
			}
			
			//将一个包放入解码器
			nRet = avcodec_send_packet(m_pAVCodecContext, m_pAVPack);
			if (nRet < 0) {
				std::stringstream logInfo;
				logInfo << "avcodec_send_packet error:" << nRet << std::endl;
				av_log(NULL, AV_LOG_ERROR, logInfo.str().c_str());
				continue;
			}

			//从解码器读取解码后的数据
			nRet = avcodec_receive_frame(m_pAVCodecContext, m_pAVFrame);
			if (nRet != 0) {
				std::stringstream logInfo;
				logInfo << "avcodec_receive_frame error:" << nRet << std::endl;
				av_log(NULL, AV_LOG_ERROR, logInfo.str().c_str());
				continue;
			}

			//重采样，采样率不变
			memset(m_pSwrBuffer, 0, MAX_AUDIO_FRAME_SIZE);
			nRet = swr_convert(m_pSwrContext, &m_pSwrBuffer, MAX_AUDIO_FRAME_SIZE, (const uint8_t **)m_pAVFrame->data, m_pAVFrame->nb_samples);
			if (nRet <0)
			{
				std::stringstream logInfo;
				logInfo << "swr_convert error:" << nRet << std::endl;
				av_log(NULL, AV_LOG_ERROR, logInfo.str().c_str());
				continue;
			}


#if DUMP_AUDIO
			//获取重采样之后的buffer大小
			int buffSize = av_samples_get_buffer_size(NULL, 2, nRet, AV_SAMPLE_FMT_S16, 1);
			fwrite((char*)m_pSwrBuffer, 1, buffSize, decode_file);
#endif

			av_packet_unref(m_pAVPack);
		}
	}

	bool CAudioReadFrame::FreeResources()
	{
		std::lock_guard<std::mutex> locker(m_lockResources);

		if (m_pSwrBuffer)
		{
			av_free(m_pSwrBuffer);
			m_pSwrBuffer = nullptr;
		}

		if (m_pFileAudioInst)
		{
			delete m_pFileAudioInst;
			m_pFileAudioInst = nullptr;
		}

		if (m_pSwrContext)
		{
			swr_free(&m_pSwrContext);
			m_pSwrContext = nullptr;
		}

		if (m_pAVFrame)
		{
			av_frame_free(&m_pAVFrame);
			m_pAVFrame = nullptr;
		}

		if (m_pAVPack)
		{
			av_packet_free(&m_pAVPack);
			m_pAVPack = nullptr;
		}

		if (m_pAVFormatContext)
		{
			avformat_free_context(m_pAVFormatContext);
			m_pAVFormatContext = nullptr;
		}

		if (m_pAVCodecParameters)
		{
			avcodec_parameters_free(&m_pAVCodecParameters);
			m_pAVCodecParameters = nullptr;
		}

		if (m_pAVCodecContext)
		{
			avcodec_close(m_pAVCodecContext);
			m_pAVCodecContext = nullptr;
		}

		m_bIsReadyForRead = false;

		return true;
	}

	void CAudioReadFrame::ChangeThreadState(ThreadState eThreadState)
	{
		std::lock_guard<std::mutex> locker(m_lockThread);
		if (m_eThreadState != eThreadState)
		{
			m_eThreadState = eThreadState;
		}
	}

	std::string CAudioReadFrame::UTF8ToGBK(const std::string& strUTF8)
	{
		int len = MultiByteToWideChar(CP_UTF8, 0, strUTF8.c_str(), -1, NULL, 0);
		wchar_t* wszGBK = new wchar_t[len + 1];
		memset(wszGBK, 0, len * 2 + 2);
		MultiByteToWideChar(CP_UTF8, 0, strUTF8.c_str(), -1, wszGBK, len);

		len = WideCharToMultiByte(CP_ACP, 0, wszGBK, -1, NULL, 0, NULL, NULL);
		char *szGBK = new char[len + 1];
		memset(szGBK, 0, len + 1);
		WideCharToMultiByte(CP_ACP, 0, wszGBK, -1, szGBK, len, NULL, NULL);
		//strUTF8 = szGBK;
		std::string strTemp(szGBK);
		delete[]szGBK;
		delete[]wszGBK;
		return strTemp;
	}
}
```

3.使用

```
#include "CAudioReadFrame.h"

int main()
{
	AudioReadFrame::CAudioReadFrame cTest;
	cTest.LoadAudioFile("E:\\原音_女声.mp3");
	cTest.StartReadFile();
	system("pause");
	return 0;
}
```

现在看一下音谱：

![img](./codec/2d0708a75f674c29a2161bb292582054~noop.image)



总结

以上就是对于音频的拉流、解码以及重采样的流程了，该例子中，拉取的是本地流，不过如果给一个远端直播流是同样可以成功的。

当然这些只是入门的操作，在实际使用，在拉起直播流、本地流、远端文件流的处理方案都应该是不同的，毕竟场景不同，方案也不同。至于为什么使用不同的方案，会在接下来的文章中再做解释。



原文链接：开源ffmpeg（三）--音频拉流、解码以及重采样_ffmpeg音频推流_山河君的博客-CSDN博客