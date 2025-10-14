platform :ios, '18.0'

target 'ChulsaGo' do
  use_frameworks! :linkage => :dynamic

  # 최신 Firebase Core & Analytics
  pod 'FirebaseCore'
  pod 'FirebaseAnalytics'

  # ✅ 최신 MLKit - 바코드 스캐너 & 비전 포함
  pod 'GoogleMLKit/BarcodeScanning'
  pod 'GoogleMLKit/MLKitCore'
  pod 'MLKitVision'

  pod 'SDWebImage'

  # Kakao SDK
  pod 'KakaoSDKCommon', '~> 2.22.7'
  pod 'KakaoSDKAuth', '~> 2.22.7'
  pod 'KakaoSDKUser', '~> 2.22.7'

  # ML Kit (예: 바코드 스캐너)
  pod 'GoogleMLKit/BarcodeScanning'

  target 'ChulsaGoTests' do
    inherit! :search_paths
  end

  target 'ChulsaGoUITests' do
    inherit! :search_paths
  end
end

# Pods의 deployment target 강제 설정
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
end
