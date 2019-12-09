//  ConnectInterstitialView.swift

import UIKit
import WebKit

class ConnectInterstitialView: UIViewController {
  var html: String!
  var delegate: ConnectAdInterstitialDelegate!
  override func loadView() {
    super.loadView()
    setUpWeb()
  }
}

extension ConnectInterstitialView {

  private func setupSubViews() {
    let buttonSize = CGFloat(40)
    let closeButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - buttonSize - buttonSize/2, y: 20, width: buttonSize, height: buttonSize))

    let frameworkBundle = Bundle(for: ConnectInterstitialView.self)
    let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("ConnectAd.bundle")
    let resourceBundle = Bundle(url: bundleURL!)
    let image = UIImage(named: "exit", in: resourceBundle, compatibleWith: nil)
    closeButton.setImage(image, for: .normal)
    closeButton.addTarget(self, action:  #selector(self.closePressed(sender:)), for: .touchUpInside)
    self.view.addSubview(closeButton)
    self.view.bringSubviewToFront(closeButton)
  }

  private func setUpWeb() {
    if let htmlString = self.html {
      DispatchQueue.main.async {
        let webView: WKWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        webView.loadHTMLString(htmlString, baseURL: Bundle.main.bundleURL)
        self.setupSubViews()
      }
    }
  }

  @objc private func closePressed(sender: UIButton!) {
    self.dismiss(animated: true, completion: nil)
    self.delegate.onInterstitialClosed(AdType.CONNECT)
  }
}

extension ConnectInterstitialView {
  class func createInstance(html: String, delegate: ConnectAdInterstitialDelegate) -> UIViewController {
    let vc = ConnectInterstitialView()
    vc.delegate = delegate
    vc.html = html
    return vc
  }
}

extension ConnectInterstitialView: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.delegate.onInterstitialDone(AdType.CONNECT)
  }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    self.delegate.onInterstitialFailed(adType: AdType.CONNECT, error: error)
  }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    self.delegate.onInterstitialFailed(adType: AdType.CONNECT, error: error)
  }
}
