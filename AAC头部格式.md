# AAC头部格式 #

一共有2种AAC头格式，一种是StreamMuxConfig，另一种是AudioSpecificConfig

## 1、AudioSpecificConfig ##

读写header的代码参考

    ffmpeg libavcodec\aacenc.c put_audio_specific_config()
    ffmpeg libavcodec\mpeg4audio.c avpriv_mpeg4audio_get_config()
    fdk-aac libMpegTPEnc\src\tpenc_asc.cpp transportEnc_writeASC()
    libaacplus aacplusenc.c aacplusEncGetDecoderSpecificInfo()
 

ISO文档 14496-3
    1.6.2.1 "Syntax - AudioSpecificConfig"
http://www.nhzjj.com/asp/admin/editor/newsfile/2010318163752818.pdf
 
该Header的主要成员

- audioObjectType: 基本的object type用5个比特表示。2是AAC-LC，5是SBR，29是PS。
- samplingFrequencyIndex: 4个比特，用来表示采样率表中的索引号
- channelConfiguration: 4个比特，声道数

```
  if (audioObjectType == 5 || audioObjectType == 29)
    extensionSamplingFrequencyIndex: 4个比特，表明实际的音频采样率
    audioObjectType:  5个比特，表明基本层编码的AOT
  GASpecificConfig
    frameLengthFlag: 1个比特，0表示帧长为1024，1表示帧长为960
    DependsOnCoreCoder: 1个比特
    extensionFlag: 1个比特
```

剩余的扩展字段 

- syncExtensionType:  11个比特，0x2b7表示HE-AAC的扩展

```
  if (syncExtensionType == 0x2b7) {
    extensionAudioObjectType: 5个比特
    if ( extensionAudioObjectType == 5 ) {
      sbrPresentFlag: 1个比特
      if (sbrPresentFlag == 1) {
        extensionSamplingFrequencyIndex: 4个比特
      }
    }
  }
```

object type、sample rate详细表格可以参考

http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio
 
如果是HE-AAC，有两种explicit和implicit一共三种声明模式。在explicit模式一（hierarchical signaling），AOT是5，然后在channels之后会有扩展的采样率和AOT字段（这里的AOT用于表明基本层编码，一般是2 AAC-LC），fdk_aac采用的这种方式；在explicit模式二（backward compatible signaling），AOT仍然是2（AAC-LC），但在GASpecificConfig后会有同步字0x2b7和sbrPresentFlag，libaacplus采用的是这种方式；在implicit模式，AOT仍然是2（AAC-LC），AudioSpecificConfig没有任何扩展，仍只是2个字节，需要靠解码器在AAC码流中找到SBR的数据

参考论文《A closer look into MPEG-4 High Efficiency AAC》

http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.129.4563&rep=rep1&type=pdf

http://developer.apple.com/library/ios/#technotes/tn2236/_index.html
 
 
## 2、StreamMuxConfig ##

写header的代码参考

    ffmpeg libavformat\latmenc.c latm_write_frame_heade()
    ffmpeg libavcodec\aacdec.c read_stream_mux_config()
    fdk-aac libMpegTPEnc\src\tpenc_latm.cpp CreateStreamMuxConfig()
 
ISO文档 14496-3

    1.7.3 Multiplex Layer
 
 
其他相关的

1、TS流可以使用ADTS和LATM两种封装格式。在ffmpeg的mpegtsenc中，用了一个amux的AVFormatContext，先把非ADTS的raw aac流写成ADTS或者LATM格式，然后再写入TS流

2、FLV/RTMP有两种AAC AUDIO DATA，0是AudioSpecificConfig，1是raw的AAC流。可以参考flv格式的官方说明文档
http://download.macromedia.com/f4v/video_file_format_spec_v10_1.pdf

3、AAC的LATM over RTP打包格式定义在RFC 3016。SDP中几个参数含义：object，就是AAC的AOT；cpresent=0，表示StreamMuxConfig不出现在码流中；config，就是StreamMuxConfig用base16进行编码。每个RTP包的载荷，最前面是PayloadLengthInfo，每出现一个0xFF表示帧长度+255，直至非0xFF就是剩余的长度；然后就是PayloadMux即AAC的裸流

4、AAC的另外一种RTP打包格式是mpeg4-generic，定义在RFC 3640。SDP中几个参数含义：config，就是AudioSpecificConfig的十六进制表示；sizeLength=13; indexLength=3，这是每个rtp包头都是固定的。每个RTP包的载荷，最前面2个字节一般是0x00 10，这是 AU-headers-length，表示AU header的长度是16个比特也就是2个字节。后面2个字节，高13位是AAC帧的长度，低3位为0。