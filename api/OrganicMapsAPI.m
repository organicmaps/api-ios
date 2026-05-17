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

#import "OrganicMapsAPI.h"

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#define OM_API_VERSION 1

static NSString * const kOMUrlScheme = @"om://";
static NSString * const kOMNotInstalledPageUrl = @"https://omaps.app/get";
static BOOL kOpenUrlOnBalloonClick = NO;

@implementation OMPin

- (nullable instancetype)init
{
  self = [super init];
  if (self)
  {
    _lat = INFINITY;
    _lon = INFINITY;
  }
  return self;
}

- (nullable instancetype)initWithLat:(double)lat
                                 lon:(double)lon
                               title:(nullable NSString *)title
                             idOrUrl:(nullable NSString *)idOrUrl
{
  self = [super init];
  if (self)
  {
    _lat = lat;
    _lon = lon;
    _title = title;
    _idOrUrl = idOrUrl;
  }
  return self;
}

@end

// Embedded fallback HTML shown when omaps.app cannot be reached (e.g. user is offline).
static NSString * const kOrganicMapsIsNotInstalledPage =
@"<html>"
"<head>"
"<title>Please install Organic Maps: free, open-source, detailed and fast offline maps</title>"
"<meta name='viewport' content='width=device-width, initial-scale=1.0'/>"
"<meta charset='UTF-8'/>"
"<style type='text/css'>"
"body { font-family: Roboto,Helvetica; background-color:#fafafa; text-align: center;}"
".description { text-align: center; font-size: 0.85em; margin-bottom: 1em; }"
".button { border-radius: 20px; padding: 10px; text-decoration: none; display:inline-block; margin: 0.5em; }"
".shadow { box-shadow: 3px 3px 5px 0 #444; }"
".download  { color: white; background-color: green; }"
".om { color: green; text-decoration: none; }"
"</style>"
"</head>"
"<body>"
"<div class='description'>Organic Maps app is required to proceed. We integrated with <a href='https://organicmaps.app' target='_blank' class='om'>Organic Maps</a> to provide you with offline maps of the entire world.</div>"
"<div class='description'>To continue please download the app:</div>"
"<a href='https://apps.apple.com/app/organic-maps/id1567437057' class='download button shadow'>Download Organic Maps</a>"
"</body>"
"</html>";

// Private view controller wrapping a WKWebView to display the "install Organic Maps" page.
@interface OMNViewController : UIViewController <WKNavigationDelegate>
@property (nonatomic, strong) WKWebView * webView;
@end

@implementation OMNViewController

- (WKWebView *)webView
{
  if (!_webView)
  {
    _webView = [[WKWebView alloc] init];
    _webView.navigationDelegate = self;
  }
  return _webView;
}

- (void)loadView
{
  self.view = self.webView;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
  [webView loadHTMLString:kOrganicMapsIsNotInstalledPage baseURL:nil];
}

// Route link taps to Safari / App Store so the user can actually install Organic Maps.
// Without this, WKWebView follows the link in-place and nothing visible happens.
- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if (navigationAction.navigationType == WKNavigationTypeLinkActivated)
  {
    NSURL * url = navigationAction.request.URL;
    if (url)
      [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)onCloseButtonClicked:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end


@implementation OMApi

+ (BOOL)isOrganicMapsUrl:(nonnull NSURL *)url
{
  NSString * appScheme = [OMApi detectBackUrlScheme];
  return appScheme && [url.scheme isEqualToString:appScheme];
}

+ (nullable OMPin *)pinFromUrl:(nonnull NSURL *)url
{
  if (![OMApi isOrganicMapsUrl:url])
    return nil;
  if (![url.host isEqualToString:@"pin"])
    return nil;

  OMPin * pin = [[OMPin alloc] init];
  NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  for (NSURLQueryItem * item in components.queryItems)
  {
    NSString * key = item.name;
    NSString * value = item.value;
    if (value == nil)
      continue;

    if ([key isEqualToString:@"ll"])
    {
      NSArray<NSString *> * coords = [value componentsSeparatedByString:@","];
      if (coords.count == 2)
      {
        // -doubleValue is locale-independent (always treats '.' as the decimal separator),
        // unlike NSDecimalNumber which honours the user's current locale.
        pin.lat = coords[0].doubleValue;
        pin.lon = coords[1].doubleValue;
      }
    }
    else if ([key isEqualToString:@"n"])
    {
      pin.title = value;
    }
    else if ([key isEqualToString:@"id"])
    {
      pin.idOrUrl = value;
    }
    else
    {
      NSLog(@"Unsupported url parameter: %@=%@", key, value);
    }
  }
  // Reject invalid coordinates.
  if (pin.lat > 90. || pin.lat < -90. || pin.lon > 180. || pin.lon < -180.)
    return nil;
  return pin;
}

+ (BOOL)isApiSupported
{
  return [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:kOMUrlScheme]];
}

+ (BOOL)showMap
{
  NSURL * url = [NSURL URLWithString:kOMUrlScheme];
  if (![UIApplication.sharedApplication canOpenURL:url])
    return NO;
  [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  return YES;
}

+ (BOOL)showLat:(double)lat lon:(double)lon title:(nullable NSString *)title idOrUrl:(nullable NSString *)idOrUrl
{
  OMPin * pin = [[OMPin alloc] initWithLat:lat lon:lon title:title idOrUrl:idOrUrl];
  return [OMApi showPin:pin];
}

+ (BOOL)showPin:(nullable OMPin *)pin
{
  return pin ? [OMApi showPins:@[pin]] : NO;
}

+ (BOOL)showPins:(nonnull NSArray<OMPin *> *)pins
{
  if (![OMApi isApiSupported])
  {
    [OMApi showOrganicMapsNotInstalledDialog];
    return NO;
  }

  NSURLComponents * components = [[NSURLComponents alloc] init];
  components.scheme = @"om";
  components.host = @"map";

  NSMutableArray<NSURLQueryItem *> * queryItems = [NSMutableArray array];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"v"
                                                    value:[NSString stringWithFormat:@"%d", OM_API_VERSION]]];

  NSString * appName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
  if (appName.length > 0)
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"appname" value:appName]];

  NSString * backUrlScheme = [OMApi detectBackUrlScheme];
  if (backUrlScheme.length > 0)
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"backurl" value:backUrlScheme]];

  for (OMPin * point in pins)
  {
    // The parser requires `ll` to come before `n` and `id` for each point.
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"ll"
                                                      value:[NSString stringWithFormat:@"%f,%f",
                                                             point.lat, point.lon]]];
    if (point.title.length > 0)
      [queryItems addObject:[NSURLQueryItem queryItemWithName:@"n" value:point.title]];
    if (point.idOrUrl.length > 0)
      [queryItems addObject:[NSURLQueryItem queryItemWithName:@"id" value:point.idOrUrl]];
  }

  if (kOpenUrlOnBalloonClick)
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"balloonaction" value:@"openUrlOnBalloonClick"]];

  components.queryItems = queryItems;
  NSURL * url = components.URL;
  if (url == nil)
    return NO;

  [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
  return YES;
}

// Returns the first URL scheme registered by the host app in Info.plist
// (CFBundleURLTypes > CFBundleURLSchemes). This scheme is passed to Organic Maps
// as `backurl=` so it can call the host app back when the user finishes interacting
// with the map. Apps with multiple registered URL types should place the scheme they
// want Organic Maps to use first.
+ (NSString *)detectBackUrlScheme
{
  NSArray * urlTypes = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  for (NSDictionary * urlType in urlTypes)
  {
    NSArray<NSString *> * schemes = urlType[@"CFBundleURLSchemes"];
    for (NSString * scheme in schemes)
      return scheme;
  }
  NSLog(@"WARNING: No URL scheme is registered in CFBundleURLTypes. Add one to allow Organic Maps to return the user to your app.");
  return nil;
}

+ (void)showOrganicMapsNotInstalledDialog
{
  OMNViewController * webController = [[OMNViewController alloc] init];
  webController.title = @"Install Organic Maps";
  [webController.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kOMNotInstalledPageUrl]]];

  UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:webController];
  webController.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                       style:UIBarButtonItemStyleDone
                                      target:webController
                                      action:@selector(onCloseButtonClicked:)];

  [[OMApi keyWindow].rootViewController presentViewController:navController animated:YES completion:nil];
}

+ (UIWindow *)keyWindow
{
  for (UIScene * scene in UIApplication.sharedApplication.connectedScenes)
  {
    if (![scene isKindOfClass:UIWindowScene.class])
      continue;
    for (UIWindow * window in ((UIWindowScene *)scene).windows)
    {
      if (window.isKeyWindow)
        return window;
    }
  }
  return nil;
}

+ (void)setOpenUrlOnBalloonClick:(BOOL)value
{
  kOpenUrlOnBalloonClick = value;
}

@end
