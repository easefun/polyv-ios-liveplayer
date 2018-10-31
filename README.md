# polyv-ios-liveplayer

  参考文档：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

### 最近更新

- 升级 PolyvLiveAPI 至 0.7.0 版本
- 修复使用苹果私有API影响上架的问题
- 修复聊天室历史记录可能丢失数据的问题
- 添加【聊天室】【在线列表】自定义头衔功能
- 聊天室新增点赞、踢人功能
- 添加获取聊天室在线人数接口

#### 最新版本

 已发布版本： [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

#### demo 中私有 API 上架被拒问题

见 [FAQ 4.1 相关内容](https://github.com/easefun/polyv-ios-liveplayer/wiki/FAQ)

#### Podfile：

```ruby
platform :ios, "9.0"
use_frameworks!

target 'IJKLivePlayer' do
  pod 'Masonry', '~> 1.1'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'SDWebImage', '~> 4.4.0'

  pod 'PolyvLiveAPI', '~> 0.7.0'      # Polyv live api
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