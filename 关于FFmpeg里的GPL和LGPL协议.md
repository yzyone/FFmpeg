
# 关于FFmpeg里的GPL和LGPL协议 #

**参考博文**

谢谢博主的分享：http://www.cnblogs.com/findumars/p/3556883.html

**GPL介绍**

我们很熟悉的Linux就是采用了GPL。GPL协议和BSD, Apache Licence等鼓励代码重用的许可很不一样。GPL的出发点是代码的开源/免费使用和引用/修改/衍生代码的开源/免费使用，但不允许修改后和衍生的代 码做为闭源的商业软件发布和销售。这也就是为什么我们能用免费的各种linux，包括商业公司的linux和linux上各种各样的由个人，组织，以及商 业软件公司开发的免费软件了。
GPL协议的主要内容是只要在一个软件中使用(”使用”指类库引用，修改后的代码或者衍生代码)GPL 协议的产品，则该软件产品必须也采用GPL协议，既必须也是开源和免费。这就是所谓的”传染性”。GPL协议的产品作为一个单独的产品使用没有任何问题， 还可以享受免费的优势。
由于GPL严格要求使用了GPL类库的软件产品必须使用GPL协议，对于使用GPL协议的开源代码，商业软件或者对代码有保密要求的部门就不适合集成/采用作为类库和二次开发的基础。
其它细节如再发布的时候需要伴随GPL协议等和BSD/Apache等类似。

**LGPL介绍**

LGPL 是GPL的一个为主要为类库使用设计的开源协议。和GPL要求任何使用/修改/衍生之GPL类库的的软件必须采用GPL协议不同。LGPL 允许商业软件通过类库引用(link)方式使用LGPL类库而不需要开源商业软件的代码。这使得采用LGPL协议的开源代码可以被商业软件作为类库引用并 发布和销售。
但是如果修改LGPL协议的代码或者衍生，则所有修改的代码，涉及修改部分的额外代码和衍生的代码都必须采用LGPL协议。因 此LGPL协议的开源 代码很适合作为第三方类库被商业软件引用，但不适合希望以LGPL协议代码为基础，通过修改和衍生的方式做二次开发的商业软件采用。
GPL/LGPL都保障原作者的知识产权，避免有人利用开源代码复制并开发类似的产品。

**总结**

采用LGPL的代码，一般情况下它本身就是一个第三方库（别忘了LGPL最早的名字就是Library GPL），这时候开发人员仅仅用到了它的功能，而没有对库本身进行任何修改，那么开发人员也不必公布自己的商业源代码。但是如果你修改了这个库的代码，那么对不起，你修改的代码必须全部开源，并且协议也是LGPL，但除了库源码之外的商业代码，仍不必公布。我是这样理解的，呵呵。以前一直以为LGPL就是商业用的时候要购买，个人用就不必购买，原来搞错了。

**FFmpeg中的GPL开关**

默认FFmpeg的configure编译是不带GPL部分代码的，我们可以基于FFmpeg的库进行第三方程序的开发而不需要开源。但是如果我们修改了FFmpeg的部分代码，则需要开源这部分代码；
如果需要使用GPL协议的部分代码，则在configure时添加如下选项：

    --enable-gpl


下面是FFmpeg中涉及到 license 的3个选项，大家使用开源代码时，记得遵循开源许可协议，这样既能保护作者的权益，也能促进开源项目持续良性的发展。

```
Licensing options:
  --enable-gpl             allow use of GPL code, the resulting libs
                           and binaries will be under GPL [no]
  --enable-version3        upgrade (L)GPL to version 3 [no]
  --enable-nonfree         allow use of nonfree code, the resulting libs
                           and binaries will be unredistributable [no]
```