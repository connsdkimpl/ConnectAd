//  ConnectAdInterstitial.swift

import Foundation
import UIKit
import GoogleMobileAds
import MoPub

public class ConnectAdInterstitial: NSObject {

  var adType: AdType!
  public var rootViewController: UIViewController!
  var adMobInterstitial: GADInterstitial!
  var moPubInterstitial: MPInterstitialAdController!
  var adMobInterstitials = [AdId]()
  var moPubInterstitials = [AdId]()
  var connectAdInterstitials = [String]()
  public var interstitialOrders = [AdOrder]()
  public var delegate: ConnectAdInterstitialDelegate!
  public var adMobConnectIds = [String]()
  public var moPubConnectIds = [String]()

  public func loadFrom(_ viewController: UIViewController) {
    self.interstitialOrders = ConnectAd.shared.interstitialOrder
    self.rootViewController = viewController
    if let ad = ConnectAd.shared.ad {
      if let adUnitIds = ad.adUnitIds {
        if let adUnit = adUnitIds.filter({ $0.adUnitName == AdKey.AdMob.rawValue }).first, let interstitials = adUnit.interstitial {
          adMobInterstitials = interstitials
        }
        if let adUnit = adUnitIds.filter({ $0.adUnitName == AdKey.MoPub.rawValue }).first, let interstitials = adUnit.interstitial {
          moPubInterstitials = interstitials
        }
      }
      if let connectAdUnit = ad.connectedAdUnit, let interstitials = connectAdUnit.interstitial {
        connectAdInterstitials = interstitials
      }
    }
    self.loadNewAds()
  }

  private func loadNewAds() {
    guard let interstitialOrder = self.interstitialOrders.first else {
      print("No interstitial found!")
      return
    }
    switch interstitialOrder {
    case .AdMob:
      self.adType = .ADMOB
      self.setAdMobInterstitial()
    case .MoPub:
      self.adType = .MOPUB
      self.setMoPubInterstitial()
    case .Connect:
      self.adType = .CONNECT
      self.setConnectAd()
    }
  }
}

extension ConnectAdInterstitial {
  private func setConnectAd() {
    var interstitialAdUnitUrl = ""
    if let adUnitUrl = connectAdInterstitials.first {
      interstitialAdUnitUrl = adUnitUrl
    }
    let url = URL(string: interstitialAdUnitUrl)
    URLSession.shared.dataTask(with: url!) { (data, response, error) in
      guard let error = error else {
        do {
          let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
          if let status = json["status"] as? String, status == "success", let components = json["components"] as? [String: Any], let htmlString = components["html"] as? String  {
            self.showConnectInterstitial(htmlString: htmlString)
          } else {
            let error = AdError("JSON Error")
            self.delegate.onInterstitialFailed(adType: self.adType, error: error)
          }
        } catch {
          self.delegate.onInterstitialFailed(adType: self.adType, error: error)
        }
        return
      }
      self.delegate.onInterstitialFailed(adType: self.adType, error: error)
    }.resume()

  }

  private func setAdMobInterstitial() {
    var interstitialAdUnitId = ""
    if let adMobConnectId = self.adMobConnectIds.first, let interstitial = adMobInterstitials.filter({ $0.connectedId == adMobConnectId }).first, let adUnitId = interstitial.adUnitId {
      interstitialAdUnitId = adUnitId
    }
    adMobInterstitial = GADInterstitial(adUnitID: interstitialAdUnitId)
    adMobInterstitial.delegate = self
    adMobInterstitial.load(GADRequest())
  }

  private func setMoPubInterstitial() {
    var interstitialAdUnitId = ""
    if let moPubConnectId = self.moPubConnectIds.first, let interstitial = moPubInterstitials.filter({ $0.connectedId == moPubConnectId }).first, let adUnitId = interstitial.adUnitId {
      interstitialAdUnitId = adUnitId
    }
    moPubInterstitial = MPInterstitialAdController(forAdUnitId: interstitialAdUnitId)
    moPubInterstitial.delegate = self
    moPubInterstitial.loadAd()
  }

  private func showConnectInterstitial(htmlString: String) {
    self.rootViewController.present(ConnectInterstitialView.createInstance(html: htmlString, delegate: delegate), animated: true, completion: nil)
  }
}

extension ConnectAdInterstitial: GADInterstitialDelegate{
  /// Tells the delegate an ad request succeeded.
  public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
    if adMobInterstitial.isReady {
      adMobInterstitial.present(fromRootViewController: rootViewController)
    }
  }

  /// Tells the delegate an ad request failed.
  public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
    if !self.interstitialOrders.isEmpty {
      self.delegate.onInterstitialFailed(adType: self.adType, error: error)
      if !self.adMobConnectIds.isEmpty{
        self.adMobConnectIds.removeFirst()
        if !self.adMobConnectIds.isEmpty {
          self.setAdMobInterstitial()
        } else {
          self.interstitialOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.interstitialOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }
  /// Tells the delegate that an interstitial will be presented.
  public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
    self.delegate.onInterstitialDone(self.adType)
  }
  /// Tells the delegate the interstitial had been animated off the screen.
  public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
    self.delegate.onInterstitialClosed(self.adType)

  }
}

extension ConnectAdInterstitial: MPInterstitialAdControllerDelegate {
  public func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
    if moPubInterstitial.ready {
      moPubInterstitial.show(from: self.rootViewController)
    }
  }
  public func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!) {
    if !self.interstitialOrders.isEmpty {
      let error = AdError("Issue unknown.")
      self.delegate.onInterstitialFailed(adType: self.adType, error: error)
      MPInterstitialAdController.removeSharedInterstitialAdController(interstitial)
      if !self.moPubConnectIds.isEmpty{
        self.moPubConnectIds.removeFirst()
        if !self.moPubConnectIds.isEmpty {
          self.setMoPubInterstitial()
        } else {
          self.interstitialOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.interstitialOrders.removeFirst()
        self.loadNewAds()
      }
    }
  }
  public func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!, withError error: Error!) {
    if !self.interstitialOrders.isEmpty {
      self.delegate.onInterstitialFailed(adType: self.adType, error: error)
      MPInterstitialAdController.removeSharedInterstitialAdController(interstitial)
      if !self.moPubConnectIds.isEmpty {
        self.moPubConnectIds.removeFirst()
        if !self.moPubConnectIds.isEmpty {
          self.setMoPubInterstitial()
        } else {
          self.interstitialOrders.removeFirst()
          self.loadNewAds()
        }
      } else {
        self.interstitialOrders.removeFirst()
        self.loadNewAds()
      }

    }
  }
  public func interstitialDidAppear(_ interstitial: MPInterstitialAdController!) {
    self.delegate.onInterstitialDone(self.adType)
  }
  public func interstitialDidDisappear(_ interstitial: MPInterstitialAdController!) {
    self.delegate.onInterstitialClosed(self.adType)
  }
  public func interstitialDidReceiveTapEvent(_ interstitial: MPInterstitialAdController!) {
    self.delegate.onInterstitialClicked(self.adType)
  }
}
