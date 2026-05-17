## Organic Maps iOS API: Getting Started

### Introduction

Organic Maps offline maps API for iOS (hereinafter referred to as *API*) provides an interface for other applications to perform the following tasks (even while in offline):

* Open [Organic Maps Application][linkOm]
* Check that [Organic Maps][linkOm] is installed
* Show one or more points on an offline map of [Organic Maps][linkOm] with *Back* button and client app name in the title
* Return the user back to the client application:
 * after pressing *Back* button on the map
 * after selecting specific point on the map if user asks for more information by pressing *More Info* button in [Organic Maps][linkOm]
* Open any given url or url scheme after selecting specific point on the map if user asks for more information by pressing *More Info* button in [Organic Maps][linkOm]
* Automatically display *Download Organic Maps* dialog if [Organic Maps][linkOm] is not installed.

In general it is possible to establish a one way or two way communication between *Organic Maps* and your app.

### Prerequisites

* Your application must target *iOS version 15.0* or above.
* For two way communication, you should add a unique [URL scheme][linkAppleCustomUrlSchemes] to your app (see below).

### Integration

First step is to clone the [repository][linkRepo] or download it as an archive.

The library lives in the `api/` folder and comes in two flavours — pick whichever matches your project:

* **Objective-C** — copy `api/OrganicMapsAPI.h` and `api/OrganicMapsAPI.m` into your project. Both files are ARC-compatible.
* **Swift 5** — copy `api/OrganicMapsAPI.swift` into your project.

You can always modify them according to your needs. The two implementations are functionally equivalent and use the same URL scheme on the wire, so apps built with either one interoperate with Organic Maps in the same way.

If you want to get results of API calls, register a unique URL scheme for your app. You can do it with [XCode][linkAddUrlScheme] or by editing the Info.plist file in your project — see Apple's [documentation][linkAppleCustomUrlSchemes]. The API library automatically picks up the first scheme listed under `CFBundleURLTypes` → `CFBundleURLSchemes` and passes it to Organic Maps as the callback. If you register multiple URL types, place the one you want Organic Maps to use for callbacks first.

Organic Maps uses the `om://` URL scheme.

You also need to add [LSApplicationQueriesSchemes][linkAppleLSApplicationQueriesSchemes] key into your plist with value *om* to correctly query whether Organic Maps is already installed.

### Repository layout

```
api-ios/
├── api/
│   ├── OrganicMapsAPI.h         # Objective-C header
│   ├── OrganicMapsAPI.m         # Objective-C implementation
│   └── OrganicMapsAPI.swift     # Swift 5 implementation
├── shared-resources/
│   └── capitals.plist           # Sample data shared by both example apps
├── capitals-example/            # Objective-C sample app
└── swift-capitals-example/      # Swift sample app
```

Both example apps reference `shared-resources/capitals.plist` via a relative path in their Xcode projects, so the data file lives in one place. To share other resources across the two examples (icons, plists, etc.), add them under `shared-resources/` and reference them from each `.xcodeproj` the same way — no symlinks needed.

*NOTE: If you are using Automatic References Counting (ARC) in your project, you can use [this solution][linkFixARC] or simply fix the code by yourself.*

### API Calls Overview and HOW TO

* Public methods on the Objective-C `OMApi` class are static; `BOOL`-returning methods return `NO` on failure. The Swift equivalent is the `OrganicMaps` enum (used as a namespace) with the same methods.
* If `id` for a given pin contains a valid URL, it will be opened from Organic Maps after the user selects *More Info*. For any other content, the id is passed back to the caller's [`application:openURL:options:`][linkAppleDelegate] method.

#### Open [Organic Maps Application][linkOm]

Simply opens Organic Maps app:

Objective-C:

    + (BOOL)showMap;
    // …
    [OMApi showMap];

Swift:

    static func openApp() -> Bool
    // …
    OrganicMaps.openApp()

#### Show specified location on the map

Displays given point on a map:

Objective-C:

    + (BOOL)showLat:(double)lat lon:(double)lon title:(nullable NSString *)title idOrUrl:(nullable NSString *)idOrUrl;
    + (BOOL)showPin:(nullable OMPin *)pin;

    @interface OMPin : NSObject
      @property (nonatomic) double lat;
      @property (nonatomic) double lon;
      @property (nullable, copy, nonatomic) NSString * title;
      @property (nullable, copy, nonatomic) NSString * idOrUrl;
      - (nullable instancetype)initWithLat:(double)lat lon:(double)lon
                                    title:(nullable NSString *)title
                                  idOrUrl:(nullable NSString *)idOrUrl;
    @end

    // …
    [OMApi showLat:53.9 lon:27.56667 title:@"Minsk - the capital of Belarus" idOrUrl:@"https://wikipedia.org/wiki/Minsk"];

    OMPin * goldenGate = [[OMPin alloc] initWithLat:37.8195 lon:-122.4785
                                              title:@"Golden Gate in San Francisco"
                                            idOrUrl:@"any string or URL"];
    [OMApi showPin:goldenGate];

Swift:

    @discardableResult
    static func showPin(latitude: Double, longitude: Double,
                        title: String? = nil, identifier: String? = nil) -> Bool

    struct OMPin {
      let latitude: Double
      let longitude: Double
      let title: String?
      let identifier: String?
    }

    // …
    OrganicMaps.showPin(latitude: 53.9, longitude: 27.56667,
                        title: "Minsk - the capital of Belarus",
                        identifier: "https://wikipedia.org/wiki/Minsk")

#### Show any number of pins on the map

Objective-C:

    + (BOOL)showPins:(NSArray<OMPin *> *)pins;

Swift:

    @discardableResult
    static func showPins(_ pins: [OMPin], openUrlOnBalloonClick: Bool = false) -> Bool

#### Receiving results of API calls

When the user presses *Back* in Organic Maps or selects *More Info*, they are redirected back to your app. Helper methods to obtain the API call result:

Returns true if `url` is the Organic Maps callback (its scheme matches your app's first registered URL scheme):

Objective-C:

    + (BOOL)isOrganicMapsUrl:(NSURL *)url;

Swift:

    static func isOrganicMapsCallback(url: URL) -> Bool

Returns nil if the user pressed *Back* without selecting any pin:

Objective-C:

    + (nullable OMPin *)pinFromUrl:(NSURL *)url;

Swift:

    static func pin(from url: URL) -> OMPin?

Example handler in `application:openURL:options:`:

Objective-C:

    - (BOOL)application:(UIApplication *)application
                openURL:(NSURL *)url
                options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
    {
      if ([OMApi isOrganicMapsUrl:url])
      {
        OMPin * pin = [OMApi pinFromUrl:url];
        if (pin) {
          // User selected a specific pin; pin.title / pin.idOrUrl / pin.lat / pin.lon are available.
        } else {
          // User pressed "Back" without selecting any pin.
        }
        return YES;
      }
      return NO;
    }

Swift:

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      guard OrganicMaps.isOrganicMapsCallback(url: url) else { return false }
      if let pin = OrganicMaps.pin(from: url) {
        // pin.title / pin.identifier / pin.latitude / pin.longitude
      } else {
        // User pressed "Back" without selecting any pin.
      }
      return true
    }

Note, that you can simply check that `options[UIApplicationOpenURLOptionsSourceApplicationKey]` contains *app.organicmaps* substring to detect that your app was opened from Organic Maps.

#### Check that Organic Maps is installed

Returns false if Organic Maps is not installed or doesn't support API calls:

Objective-C:

    + (BOOL)isApiSupported;

Swift:

    static var isInstalled: Bool { get }

With this method you can check whether the user needs to install Organic Maps and display your custom UI. Alternatively, the library presents a built-in install dialog (`showOrganicMapsNotInstalledDialog` / `OrganicMaps.presentInstallDialog()`) which is invoked automatically by `showPins:` / `showPins(_:)` when the app isn't installed.

### Set value if you want to open pin URL on balloon click

Objective-C:

    + (void)setOpenUrlOnBalloonClick:(BOOL)value;

Swift (passed per call):

    OrganicMaps.showPins(pins, openUrlOnBalloonClick: true)

### Under the hood

If you prefer to use API directly, here are some details about the implementation.

Applications "talk" to each other using URL Scheme. API v1 supports the following parameters in the URL Scheme:

    om://map?v=1&ll=54.32123,12.34562&n=Point%20Name&id=AnyStringOrEncodedUrl&backurl=UrlToCallOnBackButton&appname=TitleToDisplayInNavBar

* **v** - API version, currently *1*
* **ll** - pin latitude and longitude, comma-separated
* **n** - pin title
* **id** - any string you want to receive back in your app, OR alternatively, any valid URL which will be opened on *More Info* button click
* **backurl** - usually, your unique app scheme to open back your app
* **appname** - string to display in navigation bar on top of the map in Organic Maps
* **balloonaction** - pass openUrlOnBalloonClick as a parameter, if you want to open pin url on balloon click (usually pin url opens when "Show more info" button is pressed).

Note that you can display as many pins as you want, the only rule is that **ll** parameter comes before **n** and **id** for each point.

When user selects a pin, your app is called like this:

    YourAppUniqueUrlScheme://pin?ll=lat,lon&n=PinName&id=PinId

Organic Maps also supports v2 route deep links. You can open them directly from
your app, for example to preview a route with intermediate stops:

    NSURL * url = [NSURL URLWithString:@"om://v2/dir?origin=52.5200,13.4050&origin_name=Warehouse%20Berlin&destination=52.5163,13.3777&destination_name=Customer&waypoints=52.5304,13.3850|52.5450,13.3920&waypoint_names=Pickup%201|Pickup%202&mode=drive"];
    [[UIApplication sharedApplication] openURL:url];

Use `om://v2/nav` instead of `om://v2/dir` to start navigation when the route is
ready. If `origin` is an explicit coordinate instead of `currentLocation`,
Organic Maps previews the route first so the user can confirm the start point.

------------------------------------------------------------------------------------------
### API Code is licensed under the BSD 2-Clause License

Copyright (c) 2022, Organic Maps OÜ
Copyright (c) 2019, MY.COM B.V.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[linkOm]: https://organicmaps.app/ "Organic Maps: free, privacy-focused, fast and detailed offline maps app"
[linkRepo]: https://github.com/organicmaps/api-ios "GitHub Repository"
[linkAddUrlScheme]: https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app "How to add url scheme in XCode"
[linkIssues]: https://github.com/organicmaps/api-ios/issues "Post a bug or feature request"
[linkAppleCustomUrlSchemes]: https://developer.apple.com/library/ios/#DOCUMENTATION/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50 "Custom URL Scheme Apple documentation"
[linkAppleDelegate]: https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:open:options:) "AppDelegate Handle custom URL Schemes"
[linkFixARC]: http://stackoverflow.com/a/6658549/1209392 "How to compile non-ARC code in ARC projects"
[linkAppleLSApplicationQueriesSchemes]: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW14 "LSApplicationQueriesSchemes"
