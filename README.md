# polyv-ios-liveplayer
  
  新用户集成或升级建议使用新的 [云课堂SDK](https://github.com/polyv/polyv-ios-cloudClass-sdk-demo)
  
  参考文档：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

### 最近更新

- 优化部分UI显示
- 播放器上添加弹幕开关
- 修复播放暖场后可能直播失败的问题
- 修复【聊天室】部分聊天表情与PC观看页不同问题
- 修复后台开启多码率时可能播放失败的问题（PolyvLiveAPI 版本更新至 0.7.1）

#### 最新版本

 已发布版本： [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

#### demo 中私有 API 上架被拒问题

影响版本：v2.4.0 ~ v2.5.4

已受影响版本处理可参见 [FAQ 4.1 相关内容](https://github.com/easefun/polyv-ios-liveplayer/wiki/FAQ)

#### Podfile：

```ruby
platform :ios, "9.0"
use_frameworks!

target 'IJKLivePlayer' do
  pod 'Masonry', '~> 1.1'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'SDWebImage', '~> 4.4.0'

  pod 'PolyvLiveAPI', '~> 0.7.1'      # Polyv live api
  pod 'PolyvSocketAPI', '~> 0.6.0'    # Polyv socket.io api
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
