# polyv-ios-liveplayer

**首次下载需要将IJKMediaFramework.framework.zip 文件解压缩**，从Github 将工程下载到本地后打开IJKLivePlayer.xcworkspace (注意：不是IJKLivePlayer 工程文件)，会发现工程中`IJKMediaFramework.framework` 为红色，直接运行会报`PLVLivePlayerController.h:9:9: 'IJKMediaFramework/IJKMediaFramework.h' file not found`，重新导入`IJKMediaFramework.framework` 库即可。

### FAQ

1. 导入PLVLiveSDK 登录时报"解析加密内容失败"
    
需要在工程设置 Other Link Flags 中配置添加"-ObjC"标识
