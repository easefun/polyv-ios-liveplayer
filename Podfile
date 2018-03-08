source 'https://github.com/CocoaPods/Specs.git'
platform :ios, "8.0"

use_frameworks!

target 'IJKLivePlayer' do
    
    pod 'Masonry', '~> 1.1'
    pod 'MBProgressHUD', '~> 1.1.0'
    
    pod 'PolyvLiveAPI', '~> 0.1.3'      # Polyv live api.
    pod 'PolyvSocketAPI', '~> 0.3.0'    # Polyv socket.io api.
    pod 'PolyvIJKPlayer', '~> 0.0.3'    # Polyv ijkPlayer.
end

# 以下设置 Pods 子 Target 的 Swift 版本为 4.0
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['SWIFT_VERSION'] = "4.0"
        end
    end
end
