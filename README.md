# polyv-ios-liveplayer

## 注意事项

 - 下载后需要将IJKMediaFramework.framework.zip 文件解压缩
   
 - 聊天室功能需要在工程中配置AppId和AppSecrect参数（一般在AppDelegate中）

        1. Github限制单个文件不超过100M，同时也为了减少传输的数据量，将SDK包中的`IJKMediaFramework.framework`文件进行了压缩，在工程目录的PolyvLiveSDK\lib文件夹下
        2. AppId和AppSecrect 需要登录自己的账号在保利威视后台获取，http://my.polyv.net/v2/login
  - SDK中`PLVChatManager.frame` 聊天室依赖`SocketIO`库，目前比较建议使用[cocopod](https://cocoapods.org)方式添加[SocketIO](socket.io-client-swift)(使用cocopod方式后需要将工程中`SocketIO.framework`移除)
       
  - 更新Xcode版本后编译或运行出错可查看`SocketIO` 是否有新版本，查询链接：https://cocoapods.org/?q=Socket.IO-Client-Swift
   
## 概述

  `polyv-ios-liveplayer` 工程是包括POLYV直播SDK在内的一个DEMO，下载后可直接在Xcode上编译运行，下载大小70M左右。此工程基于IJKPlayer播放器，可播放FLV视频，有**延迟低、加载快**等优点，也有**聊天室的SDK**和**弹幕功能**等。
   
   原iOS直播播放器基于`MPMovieViewPlayer` 的封装，如继续使用原SDK(不建议，MPMoviePlayerController无法播放FLV格式视频，播放m3u8格式视频，延迟比FLV高)，可移步[dev_moviePlayer分支](https://github.com/easefun/polyv-ios-liveplayer/tree/dev_moviePlayer)。
   
   建议最低系统支持iOS8.0（苹果最新的三代系统）, 非系统播放器在iOS8.0之后支持使用硬解码；SDK中`socketIO`库为swift版本，在iOS8.0之后混编更易。
   
## 文件结构和功能介绍

```
IJKLivePlayer
| -- PolyvLiveSDK（Polyv 直播SDK）
|        | -- lib
|        |       | -- IJKMediaFramework.framework（IJK播放器）
|        |       | -- PLVChatManager.framework（聊天室相关接口）
|        |       | -- PLVLiveAPI.framework（直播相关接口）
|        |       | -- SocketIO.framework（SocketIO库）
|        |
|        | -- player
|        |       | -- PLVLivePlayerSkin.bundle（皮肤资源）
|        |       | -- PLVLivePlayerController.h（直播播放器）
|        |       | -- PLVLivePlayerControllerSkin.h（播放器皮肤）
|  
|  -- IJKLivePlayer（SDK DEMO主体部分）   
        | -- PLVChatRoom（聊天室）
        |       | -- BCKeyBoard（聊天室表情键盘）
        |       | -- PLVTableViewCell.h
        |       | -- PLVChatRoomManager.h（聊天室控制器）
        |
        | -- ZJZDanmu（弹幕）
        | -- LivePlayerViewController.h（初始化播放器、聊天室、弹幕）
        | -- ViewController.h
        | -- AppDelegate.h
        .
        .
```

 1. IJKMediaFramework.framework

    `IJKMediaFramework.framework` 已经编译好的framework，参考ijkplayer[Build iOS](https://github.com/Bilibili/ijkplayer)。这个编译过程较久，需要耐心等候。PLVLivePlayerSDK中的`IJKMediaFramework.framework` 对i386、x86_64、armv7、arm64架构CUP都支持，可以在虚拟机和真机上进行调试。

     此版本framework支持HTTPS地址视频播放；支持HLS AES-126加密视频；修改部分代码修复后台返回前台时视频画面不动的问题，如忽略此问题亦可自行编译
    
 2. PLVChatManager.framework
    
    POLYV 聊天室相关接口的封装，包括聊天室的连接、接受、发送信息等
    
 3. SocketIO.framework

    SocketIO Swift版本库，用于连接POLYV聊天室进行通讯，建议使用cocopod添加
    
 4. PLVLivePlayerController

    IJK上二次封装的POLYV直播播放器
    `PLVLivePlayerControllerSkin` 为播放器的视图皮肤类
    
## 工程配置

 如果将PolyvLiveSDK导入自己工程中，需要以下的配置
 
 1. 导入PolyvLiveSDK
    
    包括其中的`IJKMediaFramework.framework`和`PLVLiveAPI.framework`两个framework。需要导入以下依赖库
    
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
     #         libstdc++.tbd
    ```
    
 2. 导入PolyvLiveSDK包中的`SocketIO.framework`库

   **如果使用cocopod则不需要导入`SocketIO.framework`, 在podfile中添加`pod 'Socket.IO-Client-Swift'`**
   
   `SocketIO.framework`需要添加到工程的`Embedded Binaries`中，同时需要在工程中打开使用Swift的标准库（默认关闭），具体操作如下
  ![](https://github.com/easefun/polyv-ios-liveplayer/blob/master/images/plv_1.png)
   
   Target -> Build Settings -> Aways Embed Swift Standard Libraries 设置`YES` 
  ![](https://github.com/easefun/polyv-ios-liveplayer/blob/master/images/plv_2.png)
    
 3. 选择工程Target -> Build Setting -> Other Link Flags 中添加"-ObjC"标记

 4. 在info.plist文件中,添加`View controller-based status bar appearance`,属性为`bool`,设为`NO`，不添加则在全屏时状态栏不显示。

 5. 添加第三方库

 使用cocopod 在Podfile中添加`Masonry`，格式如下

 ```
 source 'https://github.com/CocoaPods/Specs.git'
 platform :ios, "8.0"

 use_frameworks!

 target 'IJKLivePlayer' do
     pod 'Masonry', '~> 1.0.2'
     pod 'MBProgressHUD', '~> 1.0.0'
 end
 ```
 `Masonry` 在直播播放器的视图类中使用到

 `MBProgressHUD` 在demo使用到的库（网络加载处的等待效果），视自己工程情况添加

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

3. 开启/关闭视频硬解码

  视频硬解码需要在最低iOS8.0的系统。默认在`PLVLivePlayerController.m` 中初始化开启设备的硬解码，如不使用可以关闭（不建议，占用较多的cpu运算资源）
  
  ```
  // 设置参数为0 或 不设置此参数则关闭硬解
  [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"]; // 打开硬解
  ```
 
## FAQ

 1. 导入PLVLiveSDK 登录时报"解析加密内容失败"
    
    需要在工程build setting的 Other Link Flags 中配置添加`-ObjC`标识
 
 2. 打开IJKLivePlayer.xcworkspace (注意：不是IJKLivePlayer 工程文件)，发现工程中`IJKMediaFramework.framework` 为红色，直接运行会报`PLVLivePlayerController.h:9:9: 'IJKMediaFramework/IJKMediaFramework.h' file not found`，

    参看文档“注意事项”，重新添加`IJKMediaFramework.framework` 库即可。
    
 3. 使用`SocketIO.framework`库连接聊天室出错、运行出错、打包程序出错
    
    可在自己工程的cocopod中添加`Socket.IO-Client-Swift`源库，去掉工程中导入的`SocketIO.framework`，使用cocopod生成的`SocketIO.framework`库文件。添加`pod 'Socket.IO-Client-Swift', '~> 8.2.0'` ，Xcode8.3 需要指定'~> 8.3'，可参考[Socket.IO-Client-Swift](https://github.com/socketio/socket.io-client-swift) Github 库中的版本更新。
    
    ```
    use_frameworks!

    target 'YourApp' do
        pod 'Socket.IO-Client-Swift', '~> 8.2.0'
    end
    ```
    
## 更新历史
  
### [polyv-ios-liveplayer release v2.0](https://github.com/easefun/polyv-ios-liveplayer/releases/tag/v2.0)
  
  - 优化文件目录，调整工程结构
  - 更新IJKMediaFramework.framework 库至0.7.7.1；支持HTTPS视频地址播放
    
### [polyv-ios-liveplayer v2.0-beta](https://github.com/easefun/polyv-ios-liveplayer/releases/tag/v2.0-beta)

  `IJKMediaFramework.framework` 版本 `0.7.5.170105`

  - 新增弹幕功能
  - 新增聊天室，可发送、接受实时聊天信息
  - 直播播放器基于IJKPlayer，支持多种格式视频，直播视频格式为FLV
    
### [polyv-ios-liveplayer release v1.0](https://github.com/easefun/polyv-ios-liveplayer/releases/tag/v1.0)
    
  直播播放器基于MPMoviePlayerController的封装，使用userId 和channel 获取直播观看地址即可观看保利威视的直播视频，直播视频流为HLS。
