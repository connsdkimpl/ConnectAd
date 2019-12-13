//  ConnectAdRewarded.swift

import Foundation
import UIKit
import GoogleMobileAds
import MoPub

public class ConnectAdRewarded: NSObject {

  var adType: AdType!
  public var rootViewController: UIViewController!
  var adMobRewardeds = [AdId]()
  var moPubRewardeds = [AdId]()
  public var delegate: ConnectAdRewardedDelegate!
  public var rewardedOrders = [AdOrder]()
  public var adMobConnectIds = [String]()
  public var moPubConnectIds = [String]()

  public func loadFrom(_ viewController: UIViewController) {
    self.rewardedOrders = ConnectAd.shared.rewardedOrder
    self.rootViewController = viewController
    if let ad = ConnectAd.shared.ad {
      if let adUnitIds = ad.adUnitIds {
        if let adUnit = adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first {
          if let rewardeds = adUnit.rewardedVideo {
            adMobRewardeds = rewardeds
          }
        }
        if let adUnit = adUnitIds.filter({ $0.adUnitName == AdKey.MoPub.rawValue }).first {
          if let rewardeds = adUnit.rewardedVideo {
            moPubRewardeds = rewardeds
          }
        }
      }
    }
    self.loadNewAds()
  }

  private func loadNewAds() {
    guard let rewardedOrder = self.rewardedOrders.first else {
      print("No reward found!")
      return
    }
    switch rewardedOrder {
    case .AdMob:
      self.adType = .ADMOB
      self.setAdMobRewarded()
    case .MoPub:
      self.adType = .MOPUB
      self.setMoPubRewarded()
    case .Connect:
      self.rewardedOrders.removeFirst()
      self.loadNewAds()
    }
  }
}

extension ConnectAdRewarded {

  private func setAdMobRewarded() {
    var rewardedAdUnitId = ""
    if let adMobConnectId = self.adMobConnectIds.first, let rewardedAd = adMobRewardeds.filter({ $0.connectedId == adMobConnectId }).first, let adUnitId = rewardedAd.adUnitId {
      rewardedAdUnitId = adUnitId
    }
    let request = GADRequest()
    GADRewardBasedVideoAd.sharedInstance().delegate = self
    GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: rewardedAdUnitId)
  }

  private func setMoPubRewarded() {
    var rewardedAdUnitId = ""
    if let moPubConnectId = self.moPubConnectIds.first, let rewardedAd = moPubRewardeds.filter({ $0.connectedId == moPubConnectId }).first, let adUnitId = rewardedAd.adUnitId {
      rewardedAdUnitId = adUnitId
    }
    MPRewardedVideo.setDelegate(self, forAdUnitId: rewardedAdUnitId)
    MPRewardedVideo.loadAd(withAdUnitID: rewardedAdUnitId, withMediationSettings: nil)
  }

}

extension ConnectAdRewarded: GADRewardBasedVideoAdDelegate {
  public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
    self.delegate.onRewardedVideoCompleted(adType: self.adType, rewardItem: reward)
  }
  public func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd:GADRewardBasedVideoAd) {
    if GADRewardBasedVideoAd.sharedInstance().isReady == true {
      GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: rootViewController)
    }
  }
  public func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    self.delegate.onRewardVideoStarted(self.adType)
  }
  public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    self.delegate.onRewardVideoClosed(self.adType)
  }

  public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
    if !self.rewardedOrders.isEmpty {
      self.delegate.onRewardFail(adType: self.adType, error: error)
      if !self.adMobConnectIds.isEmpty{
        self.adMobConnectIds.removeFirst()
        if !self.adMobConnectIds.isEmpty {
          self.setAdMobRewarded()
        } else {
          self.rewardedOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.rewardedOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }
}

extension ConnectAdRewarded: MPRewardedVideoDelegate {
  public func rewardedVideoAdDidLoad(forAdUnitID adUnitID: String!) {
    if MPRewardedVideo.hasAdAvailable(forAdUnitID: adUnitID) {
      MPRewardedVideo.presentAd(forAdUnitID: adUnitID, from: rootViewController, with: nil)
    }
  }
  public func rewardedVideoAdDidFailToLoad(forAdUnitID adUnitID: String!, error: Error!) {
    if !self.rewardedOrders.isEmpty {
      let error = AdError("Issue unknown.")
      self.delegate.onRewardFail(adType: self.adType, error: error)
      if !self.moPubConnectIds.isEmpty{
        self.moPubConnectIds.removeFirst()
        if !self.moPubConnectIds.isEmpty {
          self.setMoPubRewarded()
        } else {
          self.rewardedOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.rewardedOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }
  public func rewardedVideoAdDidFailToPlay(forAdUnitID adUnitID: String!, error: Error!) {
    if !self.rewardedOrders.isEmpty {
      let error = AdError("Issue unknown.")
      self.delegate.onRewardFail(adType: self.adType, error: error)
      if !self.moPubConnectIds.isEmpty{
        self.moPubConnectIds.removeFirst()
        if !self.moPubConnectIds.isEmpty {
          self.setMoPubRewarded()
        } else {
          self.rewardedOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.rewardedOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }
  public func rewardedVideoAdWillAppear(forAdUnitID adUnitID: String!) {
    self.delegate.onRewardVideoStarted(self.adType)
  }

  public func rewardedVideoAdDidDisappear(forAdUnitID adUnitID: String!) {
    self.delegate.onRewardVideoClosed(self.adType)
  }
  public func rewardedVideoAdShouldReward(forAdUnitID adUnitID: String!, reward: MPRewardedVideoReward!) {
    self.delegate.onRewardedVideoCompleted(adType: self.adType, rewardItem: reward)
  }
  public func rewardedVideoAdDidReceiveTapEvent(forAdUnitID adUnitID: String!) {
    self.delegate.onRewardVideoClicked(self.adType)
  }
}
extension GADAdReward: ConnectAdReward {
  public var rewardAmount: Int {
    get {
      return Int(truncating: self.amount)
    }
  }

  public var rewardType: String {
    get {
      return self.type
    }
  }
}

extension MPRewardedVideoReward: ConnectAdReward {
  public var rewardType: String {
    get {
      return self.currencyType
    }
  }

  public var rewardAmount: Int {
    get {
      return Int(truncating: self.amount)
    }
  }
}
