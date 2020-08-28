# polyv-ios-liveplayer

文档说明：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

####注意⚠️

该 sdk-demo 目前已不做常规功能维护，为了您的更好使用体验，请移步至 [云课堂SDK](https://github.com/polyv/polyv-ios-cloudClass-sdk-demo)（含普通直播模式）

### 最近更新

- 文件结构调整，结构更清晰
- 更新聊天室登录逻辑和获取chattoken接口
- PolyvLiveAPI 升级至 0.7.5，修复Qos参数过长问题
- 移除 PolyvSocketAPI 库，更新为 PolyvBusinessSDK

#### 最新版本

 已发布版本： [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

#### demo 中私有 API 上架被拒问题

影响版本：v2.4.0 ~ v2.5.4

已受影响版本处理可参见 [FAQ 4.1 相关内容](https://github.com/easefun/polyv-ios-liveplayer/wiki/FAQ)

#### Podfile：

```ruby
platform :ios, "9.0"
use_frameworks!

target 'PolyvLiveSDKDemo' do
  # Pods for PolyvLiveSDKDemo
  pod 'Masonry', '~> 1.1'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'SDWebImage', '~> 4.4.0'

  # PolyvLiveSDK 依赖库
  pod 'PolyvLiveAPI', '~> 0.7.5'
  pod 'PolyvBusinessSDK', '~> 0.15.0'
  pod 'PolyvIJKPlayer', '~> 0.4.0'
  pod 'AgoraRtcEngine_iOS', '~>2.0.0'
end
```

## Features

- 直播播放
- 暖场播放（视频/图片）
- 竖屏小屏/横屏全屏
- 多码率切换
- 弹幕
- 聊天室
- 咨询提问
- 在线列表
- 音视频连麦


### 下载安装

手机扫码安装，密码：polyv

![POLYV 直播观看](https://www.pgyer.com/app/qrcode/vYJj)

[下载地址](https://www.pgyer.com/vYJj)

