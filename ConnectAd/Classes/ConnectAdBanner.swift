//  ConnectAdBanner.swift

import UIKit
import GoogleMobileAds
import MoPub

public class ConnectAdBanner: UIView {

  public var rootViewController: UIViewController!
  var adMobBannerView: GADBannerView!
  var moPubBannerView: MPAdView!
  var connectBannerView: ConnectBannerView!
  var adType: AdType!
  var adMobBanners = [AdId]()
  var moPubBanners = [AdId]()
  var connectAdBanners = [String]()
  public var delegate: ConnectAdBannerDelegate!
  public var bannerOrders = [AdOrder]()
  public var adMobConnectIds = [String]()
  public var moPubConnectIds = [String]()

  //initWithFrame to init view from code
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }

  //initWithCode to init view from xib or storyboard
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public func loadAds() {
    self.bannerOrders = ConnectAd.shared.bannerOrder
    if let ad = ConnectAd.shared.ad {
      if let adUnitIds = ad.adUnitIds {
        if let adUnit = adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first {
          if let banners = adUnit.banner {
            adMobBanners = banners
          }
        }
        if let adUnit = adUnitIds.filter({ $0.adUnitName == AdKey.MoPub.rawValue }).first {
          if let banners = adUnit.banner {
            moPubBanners = banners
          }
        }
      }
      if let connectAdUnit = ad.connectedAdUnit {
        if let banners = connectAdUnit.banner {
          connectAdBanners = banners
        }
      }
    }

    self.loadNewAds()
  }

  private func loadNewAds() {
    guard let bannerOrder = self.bannerOrders.first else {
      print("No banner found!")
      return
    }
    switch bannerOrder {
    case .AdMob:
      self.adType = .ADMOB
      self.setAdMobBanner()
    case .MoPub:
      self.adType = .MOPUB
      self.setMoPubBanner()
    case .Connect:
      self.adType = .CONNECT
      self.setConnectAd()
    }
  }

}
extension ConnectAdBanner {
  private func setAdMobBanner() {
    adMobBannerView = GADBannerView(adSize: kGADAdSizeBanner)
    addBannerView(adMobBannerView)
    var bannerAdUnitId = ""
    if let adMobConnectId = self.adMobConnectIds.first, let banner = adMobBanners.filter({ $0.connectedId == adMobConnectId }).first, let adUnitId = banner.adUnitId {
      bannerAdUnitId = adUnitId
    }
    adMobBannerView.adUnitID = bannerAdUnitId
    adMobBannerView.delegate = self
    adMobBannerView.rootViewController = rootViewController
    adMobBannerView.load(GADRequest())
  }

  private func setMoPubBanner() {
    var bannerAdUnitId = ""
    if let moPubConnectId = self.moPubConnectIds.first, let banner = moPubBanners.filter({ $0.connectedId == moPubConnectId }).first, let adUnitId = banner.adUnitId {
      bannerAdUnitId = adUnitId
    }
    moPubBannerView = MPAdView(adUnitId: bannerAdUnitId)
    moPubBannerView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    addBannerView(moPubBannerView)
    moPubBannerView.delegate = self
    moPubBannerView.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
  }

  private func setConnectAd() {
    var bannerAdUnitUrl = ""
    if let adUnitUrl = connectAdBanners.first {
      bannerAdUnitUrl = adUnitUrl
    }
    if let url = URL(string: bannerAdUnitUrl) {
      URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let error = error else {
          do {
            let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
            if let status = json["status"] as? String, status == "success", let components = json["components"] as? [String: Any], let htmlString = components["html"] as? String  {
              self.showConnectBanner(htmlString: htmlString)
            } else {
              let error = AdError("JSON Error")
              self.delegate.onBannerFailed(adType: self.adType, error: error)
            }
          } catch {
            let error = AdError("JSON Serialization error")
            self.delegate.onBannerFailed(adType: self.adType, error: error)
          }
          return
        }
        self.delegate.onBannerFailed(adType: self.adType, error: error)
        print("error: ", error)
      }.resume()
    } else {
      let error = AdError("No url found!r")
      self.delegate.onBannerFailed(adType: self.adType, error: error)
    }

  }

  private func showConnectBanner(htmlString: String) {
    DispatchQueue.main.async {
      self.connectBannerView = ConnectBannerView(frame: CGRect(origin: CGPoint.zero, size: self.frame.size))
      self.connectBannerView.delegate = self.delegate
      self.connectBannerView.load(html: htmlString)
      self.addBannerView(self.connectBannerView)
    }
  }

  private func addBannerView(_ bannerView: UIView) {
    self.addSubview(bannerView)
  }

  private func removeBannerView(_ bannerView: UIView) {
    bannerView.removeFromSuperview()
  }
}

extension ConnectAdBanner: GADBannerViewDelegate {
  /// Tells the delegate an ad request loaded an ad.
  public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
    bannerView.alpha = 0
    UIView.animate(withDuration: 1, animations: {
      bannerView.alpha = 1
    })
    self.delegate.onBannerDone(self.adType)
  }

  /// Tells the delegate an ad request failed.
  public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
    if !self.bannerOrders.isEmpty {
      self.delegate.onBannerFailed(adType: self.adType, error: error)
      removeBannerView(adMobBannerView)
      adMobBannerView = nil
      if !self.adMobConnectIds.isEmpty{
        self.adMobConnectIds.removeFirst()
        if !self.adMobConnectIds.isEmpty {
          self.setAdMobBanner()
        } else {
          self.bannerOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.bannerOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }

  /// Tells the delegate that a full-screen view will be presented in response
  /// to the user clicking on an ad.
  public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
    self.delegate.onBannerExpanded(self.adType)
    self.delegate.onBannerClicked(self.adType)
  }

  /// Tells the delegate that the full-screen view has been dismissed.
  public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
    self.delegate.onBannerCollapsed(self.adType)
  }

  /// Tells the delegate that a user click will open another app (such as
  /// the App Store), backgrounding the current app.
  public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
    self.delegate.onBannerClicked(self.adType)
  }
}

extension ConnectAdBanner: MPAdViewDelegate {
  public func viewControllerForPresentingModalView() -> UIViewController! {
    return rootViewController
  }

  public func adViewDidLoadAd(_ view: MPAdView!) {
    self.delegate.onBannerDone(self.adType)
  }
  public func adViewDidFail(toLoadAd view: MPAdView!) {
    if !self.bannerOrders.isEmpty {
      view.stopAutomaticallyRefreshingContents()
      removeBannerView(moPubBannerView)
      let error = AdError("Issue unknown.")
      self.delegate.onBannerFailed(adType: self.adType, error: error)
      if !self.moPubConnectIds.isEmpty{
        self.moPubConnectIds.removeFirst()
        if !self.moPubConnectIds.isEmpty {
          self.setMoPubBanner()
        } else {
          self.bannerOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.bannerOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }
  public func willPresentModalView(forAd view: MPAdView!) {
    self.delegate.onBannerClicked(self.adType)
  }
  public func willLeaveApplication(fromAd view: MPAdView!) {
    self.delegate.onBannerClicked(self.adType)
  }
}
