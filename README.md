# polyv-ios-liveplayer

  参考文档：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

## 最近更新

- iPhone X 适配
- 新增自定义 TAB 功能
- 新增聊天室历史记录
- 增加播放前是否可播放判断
- 主备接口更新及登录接口优化((自动重试及切换主备接口)

## 最新版本

2.5.0 [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

#### Podfile：

```ruby
platform :ios, "9.0"
use_frameworks!

target 'IJKLivePlayer' do
  pod 'Masonry', '~> 1.1'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'SDWebImage', '~> 4.4.0'

  pod 'PolyvLiveAPI', '~> 0.6.0'      # Polyv live api
  pod 'PolyvSocketAPI', '~> 0.4.1'    # Polyv socket.io api
  pod 'PolyvIJKPlayer', '~> 0.3.0'    # Polyv ijkPlayer
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