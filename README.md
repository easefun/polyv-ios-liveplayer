# polyv-ios-liveplayer

> 保利威视直播播放器video player基于MPMoviePlayerController的封装，提供接口使用userid 和 channel 进行直播播放


> 建议使用Xcode8.0以上开发工具


## 文件结构

- PLVLivePlayerSDK 文件结构

	-  PLVChannel.framework 中有两个接口文件： 

  	 - PLVChannel.h(加载直播视频信息、和判断直播是否正在进行)
     - PLVReportManager.h(日志信息的上传)

    - PLVLivePlayer.bundle 皮肤等图片资源库

  - SkinVideoController 播放器逻辑处理类，进行播放相关和交互相关的逻辑处理等

  - SkinVideoControllerView 播放器皮肤类


- LivePlayerViewController 管理及显示播放器的视图控制器类

## 程序配置

1. 导入MediaPlayer.framework静态库

	选择项目->Build Phases->Link Binary With Libraries，点击下方+号，添加MediaPlayer.framework

2. 配置info.plist文件

  - 允许https连接访问。iOS 9只允许访问https内容，需要特殊配置下

   右键点击项目的plist文件->Open As Source Code:
  ```xml
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    
  ```
   加入以上内容，允许app访问http内容。

  - 设置状态栏默认不显示。和播放器皮肤视图相关
 
 	 同样在plist文件中添加  

  ```xml
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    
  ```

3. 导入PLVLivePlayerSDK文件包

	将此文件拷贝至工程目录下


## SkinVideoController初始化及配置

1. 使用`initWithFrame:videoLiveType:`方法初始化SkinVideoController

	直播播放器根据实际应用有**不断流类型**(电视直播类型)和**会断流类型**(课堂、会议、演讲等)两种，初始化时建议使用`initWithFrame:videoLiveType:`方法指明此播放器进行哪种类型的直播。使用`-initWithFrame: `方式初始化的播放器类型为默认的SkinVideoLiveTypeContinuing类型(不断流类型)。

2. 添加播放器view在当前控制器下

3. 设置videoPlayer播放器的控制器**或**实现播放器的goBack属性
	
	-	方法一: `setParentViewController:`(当前控制器通过present方式呈现)或`setNavigationController:`(当前控制器通过push方式呈现)

	- 方法二: pressent方式示例

  ```objective-c
  __weak typeof(self) weakSelf = self;
  self.videoPlayer.goBackBlock = ^(){
  	[weakSelf dismissViewControllerAnimated:YES completion:nil];
  };
  
  ```

  > 通过以上两种方式在释放当前控制器后均不会造成播放器的内存泄漏


 部分代码如下：

  ```objective-c
  CGFloat width = self.view.bounds.size.width;
  self.videoPlayer = [[SkinVideoController alloc] initWithFrame:CGRectMake(0, 0, width, width*(3.0/4.0))  videoLiveType:SkinVideoLiveTypeContinuing];
  [self.view addSubview:self.videoPlayer.view];
  [self.videoPlayer setParentViewController:self];

  //self.videoPlayer.goBackBlock = ^(){
  //   [weakSelf dismissViewControllerAnimated:YES completion:nil];
  //};
  
  ```

 
4. 设置videoPlayer的channel和URL等属性

  ```objective-c

self.videoPlayer.channel = channel;
[self.videoPlayer setHeadTitle:self.channel.name];
[self.videoPlayer setContentURL:[NSURL URLWithString:self.channel.contentURL]];

  ```

5. 播放视频

  `[self.videoPlayer play];`


  部分代码如下：

  ```objective-c
    // 加载直播频道信息
    [PLVChannel loadVideoUrl:self.channel.userId channelId:self.channel.channelId completion:^(PLVChannel*channel){
        if (channel==nil) {
            //error handle
            NSLog(@"channel load error");
        }else{
            self.channel = channel;
            self.videoPlayer.channel = channel;
            [self.videoPlayer setHeadTitle:self.channel.name];
            [self.videoPlayer setContentURL:[NSURL URLWithString:self.channel.contentURL]];
           
            [self.videoPlayer play];            // 播放视频
        }
    }];

  ```
  
  > 以上配置可参考demo中的代码实现

