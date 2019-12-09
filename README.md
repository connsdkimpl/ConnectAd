# ConnectAd for iOS(Swift)
## Installation
### Installation with CocoaPods
[CocoaPods](https://cocoapods.org/) is a dependency manager for Swift and Objective-C Cocoa projects, which automates and simplifies the process of using 3rd-party libraries like the ConnectAdSDK in your projects. You can install it with the following command:
```
$ sudo gem install cocoapods
```

**Podfile**  To integrate ConnectAd into your Xcode project using CocoaPods, specify it in your Podfile:
```
pod 'ConnectAd', :git => 'https://github.com/connsdkimpl/ConnectAd.git'

```

Then, run the following command:
```
$ pod install
```
Note: Make sure  [ConnectAd](https://github.com/connsdkimpl/ConnectAd) is public.

## Integration
### 1. Configure Ad Units in Your App
In your app’s `AppDelegate.swift` file, in  `didFinishLaunchingWithOptions:` method,  use the following code:
```
ConnectAd.shared.connectAdInit("APP_ID"){ (result, error) -> () in
      if let error = error {
        print(error.localizedDescription)
      } else {
        print(result)
      }

    }
```
### 2. Loading Banner Ads
First, import the SDK into your ViewController.

```
import ConnectAd
```

There are two ways to create a **ConnectAdBanner** as below,

 - programmatically:

```	
var banner = ConnectAdBanner(frame: BANNER_FRAME)
```


 - xib/storyboard:
Create a **UIView** in storyboard and change its class to **ConnectAdBanner**. Connect the object to your ```UIViewController``` to use it.
```
@IBOutlet  weak  var banner: ConnectAdBanner!
```
	
Initialise the following properties to your ConnectAdBanner.

```
banner.adMobConnectIds = ["ADMOB_BANNER_CONNECT_ID_1", "ADMOB_BANNER_CONNECT_ID_2"]
banner.moPubConnectIds = ["MOPUB_BANNER_CONNECT_ID_1", "MOPUB_BANNER_CONNECT_ID_2"]
banner.rootViewController = self
banner.delegate = self
self.view.addSubview(banner)  
```
Whenever you need to present your banner, call ```loadAds()``` of your **ConnectAdBanner** to load and display a banner ad.
```
banner.loadAds()
```
Note: If you don't have any of the CONNECT_IDs, then there is no need to set values to corresponding properties.

### 3. Loading Interstitial Ads
First, import the SDK into your ViewController.

```
import ConnectAd
```

Create a **ConnectAdInterstitial** instance:
```
var interstitial = ConnectAdInterstitial()
banner.adMobConnectIds = ["ADMOB_INTERSTITIAL_CONNECT_ID_1", "ADMOB_INTERSTITIAL_CONNECT_ID_2"]
banner.moPubConnectIds = ["MOPUB_INTERSTITIAL_CONNECT_ID_1", "MOPUB_INTERSTITIAL_CONNECT_ID_2"]
interstitial.delegate = self
```
Whenever you need to show your interstitial ad, call ```loadFrom()``` of your **ConnectAdInterstitial** to load and display the same.
```
interstitial.loadFrom(self)
```
Note: If you don't have any of the CONNECT_IDs, then there is no need to set values to corresponding properties.

### 4. Loading Rewarded Video Ads
First, import the SDK into your ViewController.

```
import ConnectAd
```

Create a **ConnectAdRewarded** instance:
```
var rewardedVideo = ConnectAdRewarded()
rewardedVideo.adMobConnectIds = ["ADMOB_REWARDED_CONNECT_ID_1", "ADMOB_REWARDED_CONNECT_ID_2"]
rewardedVideo.moPubConnectIds = ["MOPUB_REWARDED_CONNECT_ID_1", "MOPUB_REWARDED_CONNECT_ID_2"]
rewardedVideo.delegate = self
```
Whenever you need to show your interstitial ad, call ```loadFrom()``` of your **ConnectAdRewarded** to load and display the same.
```
rewardedVideo.loadFrom(self)
```
Note: If you don't have any of the CONNECT_IDs, then there is no need to set values to corresponding properties.

### 5. Implementing Delegates
#### Conform your ViewController to ```ConnectAdBannerDelegate``` protocol and implement all the methods.
```
extension MyViewController: ConnectAdBannerDelegate {
  func onBannerDone(_ adType: AdType) {
  	print("Banner received ad from:\(adType)")
  }
  func onBannerFailed(adType: AdType, error: Error) {
  	print("Banner ad error from:\(adType), Error:\(error.localizedDescription)")
  }
  func onBannerClicked(_ adType: AdType) {
  	print("Banner OnClick \(adType)")
  }
  func onBannerExpanded(_ adType: AdType) {
  	print("Banner will present \(adType)")
  }
  func onBannerCollapsed(_ adType: AdType) {
  	print("Banner did dismiss\(adType)")
  }
}
```
#### Conform your ViewController to ```ConnectAdInterstitialDelegate``` protocol and implement all the methods.
```
extension MyViewController: ConnectAdInterstitialDelegate {
  func connectAdInterstitialReceivedAd(_ adType: AdType) {
  	print("Interstitial video received \(adType)")
  }
  func onInterstitialDone(_ adType: AdType) {
  	print("Interstitial video appear \(adType)")
  }
  func onInterstitialFailed(adType: AdType, error: Error) {
  	print("Interstitial video failed: Error:\(error.localizedDescription) \(adType)")
  }
  func onInterstitialClicked(_ adType: AdType) {
  	print("Interstitial video tapped \(adType)")
  }
  func onInterstitialClosed(_ adType: AdType) {
  	print("Interstitial video disappear \(adType)")
  }
}
```
#### Conform your ViewController to ```ConnectAdRewardedDelegate``` protocol and implement all the methods.
```
extension MyViewController: ConnectAdRewardedDelegate {
  func onRewardFail(adType: AdType, error: Error) {
  	print("RewardedVideo failed to load:\(adType), Error:\(error.localizedDescription)")
  }
  func onRewardVideoStarted(_ adType: AdType) {
  	print("RewardedVideo started playing \(adType)")
  }
  func onRewardedVideoCompleted(_ adType: AdType) {
  	print("RewardedVideo completed playing \(adType)")
  }
  func onRewardVideoClosed(_ adType: AdType) {
  	print("RewardedVideo closed \(adType)")
  }
  func onRewarded(adType: AdType, rewardItem: ConnectAdReward) {
  	print("Rewarded: \(adType), amount\(rewardItem.rewardAmount), type\(rewardItem.rewardType)")
  }
  func onRewardVideoClicked(_ adType: AdType) {
  	print("RewardedVideo video tapped \(adType)")
  }
}
```
## License
MIT License

Copyright (c) 2019 connsdkimpl

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
