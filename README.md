# polyv-ios-liveplayer

​	参考文档： [Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

## 最近更新

- `IJKMediaFramework.framework`、`PLVLiveAPI.framework`、`PLVChatManager.framework` 可直接下载或通过 CocoaPods 安装
- 从Github仓库中移除 `IJKMediaFramework.framework.zip`、`PLVLiveAPI.framework`、`PLVChatManager.framework` 包，减小下载体积


## 最新版本

SDK版本历史： [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)



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

完整可运行Pods项目：[v2.2.0-beta2](http://repo.polyv.net/ios/download/livesdk-demo/2.2.0-beat2/polyv-ios-liveplayer.zip)

## Features

- 直播播放
- 竖屏小屏/横屏全屏
- 弹幕
- 聊天室
- 咨询提问
- 在线列表
