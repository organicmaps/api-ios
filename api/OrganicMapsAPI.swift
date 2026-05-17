/*******************************************************************************

 Copyright (c) 2026, Organic Maps OÜ
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 ******************************************************************************/

import UIKit
import WebKit

/// A single point displayed on the Organic Maps map.
public struct OMPin {
  public let latitude: Double
  public let longitude: Double
  /// Optional pin label shown on the map.
  public let title: String?
  /// Echoed back to the calling app when the pin is selected. If this is a valid URL,
  /// Organic Maps opens it on "More Info" instead of returning to the calling app.
  public let identifier: String?

  public init(latitude: Double, longitude: Double, title: String? = nil, identifier: String? = nil) {
    self.latitude = latitude
    self.longitude = longitude
    self.title = title
    self.identifier = identifier
  }
}

/// Swift interface to the Organic Maps URL Scheme API.
public enum OrganicMaps {
  private static let apiVersion = 1
  private static let scheme = "om"
  private static let installPageURL = URL(string: "https://omaps.app/get")!

  /// `true` if Organic Maps is installed and can handle `om://` URLs. Requires
  /// `om` to be listed under `LSApplicationQueriesSchemes` in your Info.plist.
  public static var isInstalled: Bool {
    UIApplication.shared.canOpenURL(URL(string: "\(scheme)://")!)
  }

  /// Opens the Organic Maps app (no points, just brings it to the foreground).
  @discardableResult
  public static func openApp() -> Bool {
    let url = URL(string: "\(scheme)://")!
    guard UIApplication.shared.canOpenURL(url) else { return false }
    UIApplication.shared.open(url)
    return true
  }

  /// Shows one pin on the map. Convenience over `showPins(_:)`.
  @discardableResult
  public static func showPin(latitude: Double, longitude: Double,
                             title: String? = nil, identifier: String? = nil) -> Bool {
    showPins([OMPin(latitude: latitude, longitude: longitude, title: title, identifier: identifier)])
  }

  /// Shows any number of pins. If Organic Maps isn't installed, presents the
  /// "Install Organic Maps" dialog and returns `false`.
  @discardableResult
  public static func showPins(_ pins: [OMPin], openUrlOnBalloonClick: Bool = false) -> Bool {
    guard isInstalled else {
      presentInstallDialog()
      return false
    }
    guard !pins.isEmpty, let url = buildMapURL(pins: pins, openUrlOnBalloonClick: openUrlOnBalloonClick) else {
      return false
    }
    UIApplication.shared.open(url)
    return true
  }

  /// `true` if `url`'s scheme matches the host app's first registered URL scheme,
  /// i.e. the callback scheme Organic Maps was told to use.
  public static func isOrganicMapsCallback(url: URL) -> Bool {
    guard let backScheme = firstRegisteredURLScheme() else { return false }
    return url.scheme == backScheme
  }

  /// Returns the pin the user selected. `nil` means the user pressed "Back"
  /// without selecting a pin, or the URL is malformed.
  public static func pin(from url: URL) -> OMPin? {
    guard isOrganicMapsCallback(url: url),
          url.host == "pin",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return nil }

    var lat: Double = .infinity
    var lon: Double = .infinity
    var title: String?
    var identifier: String?

    for item in components.queryItems ?? [] {
      guard let value = item.value else { continue }
      switch item.name {
      case "ll":
        let parts = value.split(separator: ",")
        if parts.count == 2, let la = Double(parts[0]), let lo = Double(parts[1]) {
          lat = la
          lon = lo
        }
      case "n":  title = value
      case "id": identifier = value
      default:   break
      }
    }
    guard (-90.0...90.0).contains(lat), (-180.0...180.0).contains(lon) else { return nil }
    return OMPin(latitude: lat, longitude: lon, title: title, identifier: identifier)
  }

  // MARK: - Internals

  private static func buildMapURL(pins: [OMPin], openUrlOnBalloonClick: Bool) -> URL? {
    var components = URLComponents()
    components.scheme = scheme
    components.host = "map"

    var items: [URLQueryItem] = [URLQueryItem(name: "v", value: "\(apiVersion)")]
    if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !appName.isEmpty {
      items.append(URLQueryItem(name: "appname", value: appName))
    }
    if let backScheme = firstRegisteredURLScheme() {
      items.append(URLQueryItem(name: "backurl", value: backScheme))
    }
    for pin in pins {
      // The map parser requires `ll` before `n` and `id` for each point.
      items.append(URLQueryItem(name: "ll", value: "\(pin.latitude),\(pin.longitude)"))
      if let t = pin.title, !t.isEmpty { items.append(URLQueryItem(name: "n", value: t)) }
      if let i = pin.identifier, !i.isEmpty { items.append(URLQueryItem(name: "id", value: i)) }
    }
    if openUrlOnBalloonClick {
      items.append(URLQueryItem(name: "balloonaction", value: "openUrlOnBalloonClick"))
    }
    components.queryItems = items
    return components.url
  }

  /// The first scheme listed under CFBundleURLTypes -> CFBundleURLSchemes. Place the
  /// scheme you want Organic Maps to call back on first if you register multiple types.
  private static func firstRegisteredURLScheme() -> String? {
    let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
    for urlType in urlTypes {
      if let schemes = urlType["CFBundleURLSchemes"] as? [String], let first = schemes.first {
        return first
      }
    }
    print("WARNING: No URL scheme is registered in CFBundleURLTypes. " +
          "Add one to allow Organic Maps to return the user to your app.")
    return nil
  }

  // MARK: - Install dialog

  public static func presentInstallDialog() {
    guard let root = keyWindow()?.rootViewController else { return }
    let vc = OMInstallDialogController(url: installPageURL)
    root.present(UINavigationController(rootViewController: vc), animated: true)
  }

  private static func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }
}

private final class OMInstallDialogController: UIViewController, WKNavigationDelegate {
  private let url: URL
  private lazy var webView: WKWebView = {
    let v = WKWebView()
    v.navigationDelegate = self
    return v
  }()

  init(url: URL) {
    self.url = url
    super.init(nibName: nil, bundle: nil)
    title = "Install Organic Maps"
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func loadView() { view = webView }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(close))
    webView.load(URLRequest(url: url))
  }

  @objc private func close() { dismiss(animated: true) }

  // Fallback to embedded HTML when omaps.app is unreachable (e.g. offline).
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    webView.loadHTMLString(Self.fallbackHTML, baseURL: nil)
  }

  // Route link taps to Safari / App Store so the user can actually install Organic Maps.
  // Without this, WKWebView follows the link in-place and nothing visible happens.
  func webView(_ webView: WKWebView,
               decidePolicyFor navigationAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated,
       let url = navigationAction.request.url {
      UIApplication.shared.open(url)
      decisionHandler(.cancel)
      return
    }
    decisionHandler(.allow)
  }

  private static let fallbackHTML = """
  <html><head><meta charset='UTF-8'/><meta name='viewport' content='width=device-width, initial-scale=1.0'/>
  <style>body{font-family:-apple-system,Helvetica;text-align:center;background:#fafafa}
  .btn{display:inline-block;padding:10px 20px;margin:1em;border-radius:20px;color:#fff;background:#2a8;
  text-decoration:none;box-shadow:3px 3px 5px 0 #444}</style></head>
  <body><p>Organic Maps is required to continue.</p>
  <a class='btn' href='https://apps.apple.com/app/organic-maps/id1567437057'>Download Organic Maps</a></body></html>
  """
}
