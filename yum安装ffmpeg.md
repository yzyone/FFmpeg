# yum安装ffmpeg #

1.升级系统

	sudo yum install epel-release -y

2.安装Nux Dextop Yum 源

由于CentOS没有官方FFmpeg rpm软件包。但是，我们可以使用第三方YUM源（Nux Dextop）完成此工作。

	sudo rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
	sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

3.安装FFmpeg 和 FFmpeg开发包

	sudo yum install ffmpeg ffmpeg-devel -y

4.测试是否安装成功

	ffmpeg

或

	ffmpeg -version