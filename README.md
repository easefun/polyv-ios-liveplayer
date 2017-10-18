# polyv-ios-liveplayer
   
> 1.0 直播 SDK 版本基于 `MPMovieViewPlayer` 的封装，如继续使用原 SDK 项目，可移步 [dev_moviePlayer 分支](https://github.com/easefun/polyv-ios-liveplayer/tree/dev_moviePlayer)。`MPMovieViewPlayer` 播放器播放 m3u8 地址，延迟比 FLV 高，所以不建议使用 `MPMovieViewPlayer`。

## 最近更新

- `SocketIO` 当前版本为 `12.0` ，支持Xcode 9.0 编译环境。

## (一) 下载须知

- 支持最低系统版本：iOS 8.0

- 下载后需要将 IJKMediaFramework.framework.zip 文件解压缩

- 使用聊天室功能需要在 AppDeleagte 中配置 AppId 和 AppSecrect 参数
      
- `SocketIO` 库的更新较为频繁，升级 Xcode 后编译或运行出错可查询是否存在新版本或可用版本。链接：https://cocoapods.org/?q=Socket.IO-Client-Swift
   
        1. Github 限制单个文件不超过100M，同时也为了减少传输的数据量，将 SDK 包中的 `IJKMediaFramework.framework` 文件进行了压缩，在工程目录 PolyvLiveSDK\lib 下

        2. AppId 和 AppSecrect 可以在保利威视后台获取，http://my.polyv.net/v2/login（需要登录）  
   
## （二）概述

`polyv-ios-liveplayer` 工程是包括POLYV直播SDK在内的一个DEMO，下载后可直接在Xcode上编译运行，下载大小70M左右。此工程基于IJKPlayer播放器，可播放FLV视频，有**延迟低、加载快**等优点，也有**聊天室的 SDK**和**弹幕功能**等。
   

   
## （三）文件结构和功能介绍

```
IJKLivePlayer
| -- PolyvLiveSDK（Polyv 直播 SDK）
|        | -- lib
|        |       | -- IJKMediaFramework.framework（IJK 播放器）
|        |       | -- PLVChatManager.framework（聊天室相关接口）
|        |       | -- PLVLiveAPI.framework（直播相关接口）
|        |
|        | -- player
|        |       | -- PLVLivePlayerSkin.bundle（皮肤资源）
|        |       | -- PLVLivePlayerController.h（直播播放器）
|        |       | -- PLVLivePlayerControllerSkin.h（播放器皮肤）
|  
|  -- IJKLivePlayer（SDK DEMO 主体部分）   
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
```

### 3.1 IJKMediaFramework.framework

`IJKMediaFramework.framework` 已经编译好的 framework，参考 ijkplayer [Build iOS](https://github.com/Bilibili/ijkplayer)。这个编译过程较久，需要耐心等候。PLVLivePlayerSDK 中的`IJKMediaFramework.framework` 对i386、x86_64、armv7、arm64 架构CUP 都支持，可以在虚拟机和真机上进行调试。

此版本framework支持HTTPS地址视频播放；支持HLS AES-126加密视频；修改部分代码修复后台返回前台时视频画面不动的问题，如忽略此问题亦可自行编译
    
### 3.2 PLVChatManager.framework
    
POLYV 聊天室相关接口的封装，包括聊天室的连接、接受、发送信息等
    
### 3.3 PLVLivePlayerController

IJK上二次封装的POLYV直播播放器
`PLVLivePlayerControllerSkin` 为播放器的视图皮肤类
    
## （四）工程配置

如果将PolyvLiveSDK导入自己工程中，需要以下的配置
 
### 4.1 导入 PolyvLiveSDK
    
包括其中的 `IJKMediaFramework.framework` 和`PLVLiveAPI.framework` 两个 framework。需要导入以下依赖库
    
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
    
### 4.2 选择工程Target -> Build Setting -> Other Link Flags 中添加"-ObjC"标记

### 4.3 配置状态栏属性

在info.plist文件中,添加`View controller-based status bar appearance`,属性为`bool`,设为`NO`，不添加则在全屏时状态栏不显示。

### 4.4 添加第三方库

使用 cocopod 在 Podfile 中添加 `Masonry`，格式如下

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, "8.0"

use_frameworks!

target 'IJKLivePlayer' do
pod 'Masonry', '~> 1.0.2'
pod 'MBProgressHUD', '~> 1.0.0'
    pod 'Socket.IO-Client-Swift', 12.0
end
```
 
- `Masonry` 在直播播放器的视图类中使用到
 
- `MBProgressHUD` demo 使用到的库（网络加载处的等待效果），视项目需求添加
 
- `Socket.IO-Client-Swift`  SocketIO 库，用于聊天室的连接  
  
**完成以上操作后在真机和虚拟机下分别编译检查是否通过**
    
## （五）其他

### 5.1 iOS 10 下调试时控制台输出系统的调试信息可设置关闭
   
选择工程 Target -> Edit Scheme -> Run -> Arguments 的Environment Variables 中添加 name `OS_ACTIVITY_MODE` value `disable` 之后点击 close 即可。

### 5.2 程序日志中的版本信息

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

### 5.3 开启/关闭视频硬解码

视频硬解码需要在最低iOS8.0的系统。默认在`PLVLivePlayerController.m` 中初始化开启设备的硬解码，如不使用可以关闭（不建议，占用较多的cpu运算资源）
  
```
 // 设置参数为0 或 不设置此参数则关闭硬解
 [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"]; // 打开硬解
```
  
## （六）FAQ

### 6.1 运行程序登录时报"解析加密内容失败" 错误信息
    
需要在工程 build setting 的 Other Link Flags 中配置添加 `-ObjC` 标识
 
### 6.2 工程中 `IJKMediaFramework.framework` 不可用
   
打开 IJKLivePlayer.xcworkspace (注意：不是 IJKLivePlayer 工程文件)，发现工程中 `IJKMediaFramework.framework` 为红色，直接运行会报`PLVLivePlayerController.h:9:9: 'IJKMediaFramework/IJKMediaFramework.h' file not found`，

参看文档“注意事项”，重新添加 `IJKMediaFramework.framework` 库即可。
    
### 6.3 编译或运行出错，出错内容含有 "SocketIO.framework" 字符串

检查是否存在新版本或可用版本，使用 cocopod 更新。链接：https://cocoapods.org/?q=Socket.IO-Client-Swift
    
```
use_frameworks!

target 'YourApp' do
   pod 'Socket.IO-Client-Swift', 12.0
end
```
    
## （七）更新历史
  
### [polyv-ios-liveplayer release v2.0](https://github.com/easefun/polyv-ios-liveplayer/releases/tag/v2.0)
  
- 优化文件目录，调整工程结构
- 更新 IJKMediaFramework.framework 库至0.7.7.1；支持HTTPS视频地址播放
    
### [polyv-ios-liveplayer v2.0-beta](https://github.com/easefun/polyv-ios-liveplayer/releases/tag/v2.0-beta)

`IJKMediaFramework.framework` 版本 `0.7.5.170105`

- 新增弹幕功能
- 新增聊天室，可发送、接受实时聊天信息
- 直播播放器基于 IJKPlayer，支持多种格式视频，直播视频格式为FLV
    
### [polyv-ios-liveplayer release v1.0](https://github.com/easefun/polyv-ios-liveplayer/releases/tag/v1.0)
    
直播播放器基于 MPMoviePlayerController 的封装，使用 userId 和channel 获取直播观看地址即可观看保利威视的直播视频，直播视频流为 HLS。

