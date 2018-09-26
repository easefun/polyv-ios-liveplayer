# polyv-ios-liveplayer

  参考文档：[Wiki](https://github.com/easefun/polyv-ios-liveplayer/wiki)

## 最近更新

- 聊天室新增点赞、踢人功能
- 添加获取聊天室在线人数接口
- 升级 PolyvSocketAPI 至 0.5.0 版本
- 观看页资源添加至同级 Resources 下
- 修复菜单页点击URL不能跳转到 safari 的问题

#### 最新版本

 已发布版本： [Release](https://github.com/easefun/polyv-ios-liveplayer/releases)

#### Podfile：

```ruby
platform :ios, "9.0"
use_frameworks!

target 'IJKLivePlayer' do
  pod 'Masonry', '~> 1.1'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'SDWebImage', '~> 4.4.0'

  pod 'PolyvLiveAPI', '~> 0.6.0'      # Polyv live api
  pod 'PolyvSocketAPI', '~> 0.5.0'    # Polyv socket.io api
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