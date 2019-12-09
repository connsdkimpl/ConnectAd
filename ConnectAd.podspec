Pod::Spec.new do |s|
  s.name             = 'ConnectAd'
  s.version          = '1.0.2'
  s.summary          = 'ConnectAd for iOS.'
  s.description      = 'This pod is used for integrating ConnectAd in Swift iOS projects.'

  s.homepage         = 'https://github.com/connsdkimpl/ConnectAd'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'connsdkimpl' => 'sdkimpl@gmail.com' }
  s.source           = { :git => 'https://github.com/connsdkimpl/ConnectAd.git', :tag => s.version.to_s }
  s.swift_version = '4.2'
  s.ios.deployment_target = '11.0'

  s.source_files = 'ConnectAd/**/*.{h,m,swift,png}'
  s.exclude_files = 'ConnectAd/**/*.plist'
  s.resource_bundles = {
    'ConnectAd' => ['ConnectAd/Assets/*.png']
  }

  s.static_framework = true
  s.dependencies = { "mopub-ios-sdk/Core": ">= 5.3.0", "Google-Mobile-Ads-SDK": ">= 7.14.0" }
end
