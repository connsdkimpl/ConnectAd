//  ConnectAd.swift

import Foundation
import UIKit
import GoogleMobileAds
import MoPub

struct AdError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
  public var localizedDescription: String {
    return message
  }
}

public enum AdKey: String {
  case AdMob = "admob"
  case MoPub = "mopub"
}
public enum BannerSize {
  case small
  case medium
}
public enum AdOrder: Int {
  case AdMob = 1 // AdMob
  case MoPub = 2 // MoPub
  case Connect = 3 // Connect
}
public enum AdType {
  case CONNECT
  case ADMOB
  case MOPUB
}
public protocol ConnectAdReward : class {
  var rewardType: String { get }
  var rewardAmount: Int { get }
}
public protocol ConnectAdBannerDelegate{
  func onBannerDone(_ adType: AdType)
  func onBannerFailed(adType: AdType, error: Error)
  func onBannerClicked(_ adType: AdType)
  func onBannerExpanded(_ adType: AdType)
  func onBannerCollapsed(_ adType: AdType)
}
public protocol ConnectAdRewardedDelegate{
  func onRewardFail(adType: AdType, error: Error)
  func onRewardVideoClicked(_ adType: AdType)
  func onRewardedVideoCompleted(_ adType: AdType)
  func onRewardVideoClosed(_ adType: AdType)
  func onRewardVideoStarted(_ adType: AdType)
  func onRewarded(adType: AdType, rewardItem: ConnectAdReward)
}
public protocol ConnectAdInterstitialDelegate{
  func onInterstitialFailed(adType: AdType, error: Error)
  func onInterstitialClicked(_ adType: AdType)
  func onInterstitialClosed(_ adType: AdType)
  func onInterstitialDone(_ adType: AdType)
}

public class ConnectAd: NSObject {
  public static let shared = ConnectAd()
  var rootViewController: UIViewController!
  var adMobBannerView: GADBannerView!
  var moPubBannerView: MPAdView!
  var connectBannerView: ConnectBannerView!
  public var adType: AdType!
  public var bannerOrder = [AdOrder]()
  public var interstitialOrder = [AdOrder]()
  public var rewardedOrder = [AdOrder]()
  public var ad: Ad!

  public func connectAdInit(_ appId: String ,completion: @escaping(ApiResponse?,Error?)->()) {
    let urlString = "http://35.235.88.118/appbyidnew/\(appId)"
    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { (data, response, error) in
      if let error = error {
        print(error.localizedDescription)
        completion(nil,error)
      }

      guard let data = data else { return }
      //Implement JSON decoding and parsing
      do {
        //Decode retrived data with JSONDecoder and assing type of Article object
        let adData = try JSONDecoder().decode(Ad.self, from: data)

        ConnectAd.shared.ad = adData
        if let order = ConnectAd.shared.ad.adOrder {
          ConnectAd.shared.bannerOrder = order.map { AdOrder(rawValue: $0)! }
          ConnectAd.shared.interstitialOrder = order.map { AdOrder(rawValue: $0)! }
          ConnectAd.shared.rewardedOrder = order.map { AdOrder(rawValue: $0)! }
        }
        if let adUnitIds = ConnectAd.shared.ad.adUnitIds {

          //mopub initialisation

          if let mopub = adUnitIds.filter({ $0.adUnitName == AdKey.MoPub.rawValue }).first {
            var mopubAppUnitId = ""
            if let banner = mopub.banner?.first, let appUnitId = banner.adUnitId {
              mopubAppUnitId = appUnitId
            } else if let interstitial = mopub.interstitial?.first, let appUnitId = interstitial.adUnitId {
              mopubAppUnitId = appUnitId
            } else if let rewardedVideo = mopub.rewardedVideo?.first, let appUnitId = rewardedVideo.adUnitId {
              mopubAppUnitId = appUnitId
            }
            if mopubAppUnitId != "" {
              let sdkConfig = MPMoPubConfiguration(adUnitIdForAppInitialization: mopubAppUnitId)
              DispatchQueue.main.async {
                MoPub.sharedInstance().initializeSdk(with: sdkConfig) {
                  print("MOPUB Initialisation success!")
                  if let adMob = adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first {
                    var adMobAppUnitId = ""
                    if let banner = adMob.banner?.first, let appUnitId = banner.adUnitId {
                      adMobAppUnitId = appUnitId
                    } else if let interstitial = adMob.interstitial?.first, let appUnitId = interstitial.adUnitId {
                      adMobAppUnitId = appUnitId
                    } else if let rewardedVideo = adMob.rewardedVideo?.first, let appUnitId = rewardedVideo.adUnitId {
                      adMobAppUnitId = appUnitId
                    }
                    if adMobAppUnitId != "" {
                      if adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first != nil {
                        GADMobileAds.sharedInstance().start(completionHandler: { (status) in
                          if status.adapterStatusesByClassName.values.filter({ $0.state == GADAdapterInitializationState.ready }).first != nil {
                            let mopubResult = Response(success: true, message:"MoPub initialization success")
                            let admobResult = Response(success: true, message: "Admob initialization success")
                            let response = ApiResponse(mopubResult: mopubResult, admobResult: admobResult)
                            completion(response,nil)
                          } else {
                            let mopubResult = Response(success: true, message:"MoPub initialization success")
                            let admobResult = Response(success: false, message: "Admob initialization failed")
                            let response = ApiResponse(mopubResult: mopubResult, admobResult: admobResult)
                            completion(response, nil)
                          } })
                      } else {
                        let mopubResult = Response(success: true, message:"MoPub initialization success")
                        let admobResult = Response(success: false, message: "Admob Data Not Found")
                        let response = ApiResponse(mopubResult: mopubResult, admobResult: admobResult)
                        completion(response, nil)
                      }
                    } else {
                      let mopubResult = Response(success: true, message:"MoPub initialization success")
                      let admobResult = Response(success: false, message: "Admob Data Not Found")
                      let response = ApiResponse(mopubResult: mopubResult, admobResult: admobResult)
                      completion(response, nil)
                    }
                  }
                }
              }
            } else {
              if let adMob = adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first {
                var adMobAppUnitId = ""
                if let banner = adMob.banner?.first, let appUnitId = banner.adUnitId {
                  adMobAppUnitId = appUnitId
                } else if let interstitial = adMob.interstitial?.first, let appUnitId = interstitial.adUnitId {
                  adMobAppUnitId = appUnitId
                } else if let rewardedVideo = adMob.rewardedVideo?.first, let appUnitId = rewardedVideo.adUnitId {
                  adMobAppUnitId = appUnitId
                }
                if adMobAppUnitId != "" {
                  if adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first != nil {
                    GADMobileAds.sharedInstance().start(completionHandler: { (status) in
                      if status.adapterStatusesByClassName.values.filter({ $0.state == GADAdapterInitializationState.ready }).first != nil {
                        print("ADMOB Initialisation success!")
                        let mopubResult = Response(success: false, message:"MoPub initialization failed")
                        let admobResult = Response(success: true, message: "Admob initialization success")
                        let response = ApiResponse(mopubResult: mopubResult, admobResult: admobResult)
                        completion(response, nil)
                      } else {
                        let error = AdError("Admob initialization failed & MoPub Data Not Found")
                        completion(nil, error)
                      }
                    })
                  } else {
                    let error = AdError("Admob & MoPub Data Not Found")
                    completion(nil, error)
                  }
                } else {
                  let error = AdError("Admob & MoPub Data Not Found")
                  completion(nil, error)
                }

              }
            }
          }
        } else {
          let error = AdError("Api Failure - Missing Ad UnitIds")
          completion(nil,error)
        }

      } catch let jsonError {
        print(jsonError)
        completion(nil, jsonError)
      }
    }.resume()

  }
}
public struct Ad: Codable {
  let adOrder: [Int]?
  let adUnitIds: [AdUnit]?
  let connectedAdUnit: connectedAdUnit?
  let vastAdUnits: [VASTAdUnit]?
}
public struct AdUnit: Codable {
  let adUnitName: String?
  let adUnitId: String?
  let banner: [AdId]?
  let interstitial: [AdId]?
  let rewardedVideo: [AdId]?
}
public struct connectedAdUnit: Codable {
  let banner: [String]?
  let interstitial: [String]?
}
public struct AdId: Codable {
  let connectedId: String?
  let adUnitId: String?
}
public struct VASTAdUnit: Codable {
  let vastUrl: String?
  let price: Float?
}
public struct ApiResponse {
  var mopubResult: Response
  var admobResult: Response
}
public struct Response {
  var success: Bool?
  var message: String?
}



