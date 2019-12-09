//  ConnectBannerView.swift

import UIKit
import WebKit

class ConnectBannerView: UIView {

  var html: String!
  let bannerHeight = CGFloat(100)
  var delegate: ConnectAdBannerDelegate!

  //initWithFrame to init view from code
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  //initWithCode to init view from xib or storyboard
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  //common func to init our view
  private func setupView() {
    self.alpha = 0
  }

  func load(html: String) {
    let webView: WKWebView = WKWebView(frame: self.frame)
    webView.navigationDelegate = self
    webView.isOpaque = false
    self.addSubview(webView)
    webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
  }
}
extension ConnectBannerView: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    UIView.animate(withDuration: 1, animations: {
      self.alpha = 1
    })
    self.delegate.onBannerDone(AdType.CONNECT)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    self.delegate.onBannerFailed(adType: AdType.CONNECT, error: error)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    self.delegate.onBannerFailed(adType: AdType.CONNECT, error: error)
  }
}
