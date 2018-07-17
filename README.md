# polyv-ios-liveplayer

  参考文档：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

## 最近更新

- 新增连麦功能
- 新增多码率功能
- 聊天室添加新消息提醒
- 直播接口更新（PolyvIJKPlayer、PolyvLiveAPI）

## 最新版本

2.4.0 [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

#### Podfile：

```ruby
platform :ios, "9.0"
use_frameworks!

target 'IJKLivePlayer' do
  pod 'PolyvLiveAPI', '~> 0.4.1'      # Polyv live api
  pod 'PolyvSocketAPI', '~> 0.4.1'    # Polyv socket.io api
  pod 'PolyvIJKPlayer', '~> 0.1.0'    # Polyv ijkPlayer
  pod 'AgoraRtcEngine_iOS', '~>2.0.0' # Agora rtc engine
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

![POLYV 直播观看](https://www.pgyer.com/app/qrcode/Cibx)

[下载地址](https://www.pgyer.com/Cibx)