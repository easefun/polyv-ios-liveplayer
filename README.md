# polyv-ios-liveplayer

**下载须知**

首次下载需要将IJKMediaFramework.framework.zip 文件解压缩。Github限制单个文件不超过100M，同时也为了减少传输的数据量，将SDK包中的`IJKMediaFramework.framework`文件进行了压缩，在工程目录的PLVLivePlayerSDK文件夹下。


## 概述

`polyv-ios-liveplayer`工程是包括POLYV直播SDK在内的一个DEMO，下载后在Xcode上运行使用，下载量在60M左右。 此工程基于IJKPlayer播放器，可以进行FLV视频的播放，具有**延迟低、加载快**等直播优点。同时也添加有**聊天室的SDK**和**弹幕功能**等。
原iOS直播播放器基于`MPMovieViewPlayer`的封装，如继续使用原SDK，可移步[dev_moviePlayer分支](https://github.com/easefun/polyv-ios-liveplayer/tree/dev_moviePlayer)。

## PLVLivePlayerSDK 功能介绍

1. IJKMediaFramework.framework

    `IJKMediaFramework.framework` 已经编译好的framework，自己编译可参考ijkplayer[Build iOS](https://github.com/Bilibili/ijkplayer)说明即可。这个编译过程较久，需要耐心等候。PLVLivePlayerSDK中的`IJKMediaFramework.framework` 对i386、x86_64、armv7、arm64架构CUP都支持，可以在虚拟机和真机上进行调试。

2. PLVLiveAPI.framework

    `PLVLiveAPI.framework`里面为POLYV的一些接口，包括登录和聊天室等。

3. PLVLivePlayerController

    `PLVLivePlayerController` 为IJK上二次封装的POLYV直播播放器
    `PLVLivePlayerControllerSkin`为`PLVLivePlayerController` 播放器的视图皮肤类

4. PLVChatRoom

    聊天室相关的类和资源等
    
## 工程配置

如果将PLVLivePlayerSDK导入自己工程中，需要以下的配置

1. 导入PLVLivePlayerSDK
    
    包括其中的`IJKMediaFramework.framework`和`PLVLiveAPI.framework`两个framework。同时需要导入以下库
    
    ```
    #     Select your Application's target.
    #     Build Phases -> Target Dependencies -> Select IJKMediaFramework
    #     Build Phases -> Link Binary with Libraries -> Add:
    #         AudioToolbox.framework
    #         AVFoundation.framework
    #         CoreGraphics.framework
    #         CoreMedia.framework
    #         CoreVideo.framework
    #         libbz2.tbd
    #         libz.tbd
    #         MediaPlayer.framework
    #         MobileCoreServices.framework
    #         OpenGLES.framework
    #         QuartzCore.framework
    #         UIKit.framework
    #         VideoToolbox.framework
    ```
 - 选择工程target -> build setting -> Other Link Flags 中添加"-ObjC"标记

2. 在info.plist文件中,添加`View controller-based status bar appearance`,属性为`bool`,设为`NO`，不添加则在全屏时状态栏不显示。

3. 添加第三方库

使用cocopod 在Podfile中添加`Masonry`和`Socket.IO-Client-Swift`，格式如下

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, "8.0"

use_frameworks!

target 'IJKLivePlayer' do
    pod 'Masonry', '~> 1.0.2'
    pod 'MBProgressHUD', '~> 1.0.0'
    pod 'Socket.IO-Client-Swift', '~> 8.1.2' 
end
```
`Masonry` 在直播播放器的视图类中使用到
`Socket.IO-Client-Swift`用于聊天室的连接
`MBProgressHUD` 是在demo使用到的库，根据自己工程情况添加。

完成以上操作后在真机和虚拟机下分别编译检查是否通过
    
## 其他

1. iOS10下调试时控制台输出系统的调试信息可设置关闭，选择工程Target -> Edit Scheme -> Run -> Arguments 的Environment Variables 中添加 name `OS_ACTIVITY_MODE` value `disable` 之后点击 close 即可。

2. 程序中的如下信息为调试信息，可忽略

```
ff3.2--ijk0.7.2-20161107--001
===== custom modules begin =====
register demuxer : ijklivehook
===== custom modules end =====
2016-12-08 14:04:28.549 PolyvIJKLivePlayer[3004:121765] 
!!!!!!!!!!
actual: ff3.2--ijk0.7.2-20161107--001
 expect: ff3.2--ijk0.7.4--20161116--001

!!!!!!!!!!
av_version_info: ff3.2--ijk0.7.2-20161107--001
ijk_version_info: k0.7.5
```

## FAQ

1. 导入PLVLiveSDK 登录时报"解析加密内容失败"
    
需要在工程build setting的 Other Link Flags 中配置添加`-ObjC`标识
 
 
2. 打开IJKLivePlayer.xcworkspace (注意：不是IJKLivePlayer 工程文件)，发现工程中`IJKMediaFramework.framework` 为红色，直接运行会报`PLVLivePlayerController.h:9:9: 'IJKMediaFramework/IJKMediaFramework.h' file not found`，

参看文档“下载须知”，重新导入`IJKMediaFramework.framework` 库即可。
 



