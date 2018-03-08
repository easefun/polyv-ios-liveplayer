# polyv-ios-liveplayer

  参考文档：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

## 最近更新

- 修复使用中文键盘时自动补正功能导致输入框位置错误的问题
- 修复在iPhone 5s iOS 11下，进入观看页当前显示表情键盘时退出可能存在的问题

## 最新版本

[Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

Pods库版本：

```ruby
platform :ios, "8.0"
use_frameworks!

target 'IJKLivePlayer' do
  pod 'PolyvIJKPlayer', '~> 0.0.3'    # Polyv ijkPlayer.
  pod 'PolyvLiveAPI', '~> 0.1.3'      # Polyv live api.
  pod 'PolyvSocketAPI', '~> 0.3.0'    # Polyv socket.io api.
end
```

完整可运行Pods项目：[v2.2.1](http://repo.polyv.net/ios/download/livesdk-demo/polyv-ios-liveplayer_2.2.1+180308.zip)

## Features

- 直播播放
- 竖屏小屏/横屏全屏
- 弹幕
- 聊天室
- 咨询提问
- 在线列表
- 暖场视频(待)
