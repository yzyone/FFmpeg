# ffplay问题Protocol 'rtp' not on whitelist 'file,crypto'! #

相信很多人的视频编解码在网上找到的很多资料都是雷霄骅博士的文章，在这里补充一点。
雷霄骅博士的文章FFmpeg发送流媒体的命令（UDP，RTP，RTMP）写得很详细
http://blog.csdn.net/leixiaohua1020/article/details/38283297

而实际上，照着做行，提示 Protocol ‘rtp’ not on whitelist ‘file,crypto’!白名单一类的问题。其实是ffplay需要额外的参数，如：
-protocol_whitelist “file,http,https,rtp,udp,tcp,tls”

完整如下

发送rtp流 

	ffmpeg -re -i frame.h264 -vcodec copy -f rtp rtp://127.0.0.1:1239 > test.sdp

接收rtp流 

	ffplay -protocol_whitelist “file,http,https,rtp,udp,tcp,tls” test.sdp

具体的ip可自行修改，可先执行ffmpeg然后暂时，产生sdp文件，再运行ffplay,最后执行ffmpeg。

————————————————

版权声明：本文为CSDN博主「u014516174」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/u014516174/article/details/70338655