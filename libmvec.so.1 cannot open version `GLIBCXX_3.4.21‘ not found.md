
# libmvec.so.1: cannot open version `GLIBCXX_3.4.21‘ not found #

**一、解决报错“libmvec.so.1: cannot open shared object file: no such file or directory”**

1、安装依赖

    yum install gcc gcc-c++

2、下载编译库

    wget http://ftp.gnu.org/gnu/glibc/glibc-2.25.tar.gz

3、编译

    tar xvzf glibc-2.25.tar.gz
    cd glibc-2.25
    mkdir build
    cd build
    ../configure --prefix=/usr/local
    make
    make install
4、修改软链接

    #cd /lib64
    #LD_PRELOAD=/lib64/libc-2.25.so ln -sf libc-2.25.so libc.so.6
    #LD_PRELOAD=/lib64/libc-2.25.so ln -sf libm-2.25.so libm.so.6
    #LD_PRELOAD=/lib64/libc-2.25.so ln -sf libpthread-2.25.so libpthread.so.0
    #LD_PRELOAD=/lib64/libc-2.25.so ln -sf librt-2.25.so librt.so.1

5、验证

    #ldd --version

6、参考链接

    http://blog.csdn.net/officercat/article/details/39520227
    https://www.ibm.com/developerworks/cn/linux/l-cn-glibc-upd/

**二、解决报错“/usr/lib64/libstdc++.so.6: version `GLIBCXX_3.4.21’ not found”**

解决： 升级GCC

    1、yum groupinstall "Development Tools"
    2、yum install glibc-static libstdc++-static
    3、wget http://ftp.gnu.org/gnu/gcc/gcc-8.3.0/gcc-8.3.0.tar.gz
    4、tar -zxvf gcc-8.3.0.tar.gz
    5、cd gcc-8.3.0

6、利用源码包里自带的工具下载依赖项

    ./contrib/download_prerequisites

7、生成Makefile

    mkdir build
    cd build
    ../configure --enable-checking=release --enable-languages=c,c++ --disable-multilib

8、编译

    make
    make install

9、定位并找到gcc生成的文件(文件路径/usr/local/lib64/libstdc++.so.6.0.25)

    cp /usr/local/lib64/libstdc++.so.6.0.25 /usr/lib64/
    cd /usr/lib64
    rm libstdc++.so.6
    ln -s libstdc++.so.6.0.25 libstdc++.so.6

也可以直接拿我编译好的libstdc++.so.6.0.25放到你自己的路径然后建立软连接
链接：https://pan.baidu.com/s/1_f-l2CyxwdgZ0n6Ri6o4zQ
提取码：hdsu

————————————————

版权声明：本文为CSDN博主「苑先森」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。

原文链接：https://blog.csdn.net/yuantao18800/article/details/107327163/