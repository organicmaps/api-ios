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
* Automatically display [*Download Organic Maps*][linkDownloadOMDialog] dialog if [Organic Maps][linkOm] is not installed.

In general it is possible to establish a one way or two way communication between *Organic Maps* and your app.

### Prerequisites

* Your application must target *iOS version 12.0* or above.
* For two way communication, you should add unique [URL scheme][linkAppleCustomUrlSchemes] to your app (see below)

### Integration

First step is to clone [repository][linkRepo] or download it as an archive.

When your are done you find two folders: *api* and *capitals-example*.
First one contains .h and .m files which you need to include into your project. You can always modify them according to your needs.

If you want to get results of API calls, please add unique URL scheme to your app. You can do it with [XCode][linkAddUrlScheme] or by editing Info.plist file in your project. To make things simple, use *om* keyword in scheme ID, like *my_om_scheme*, and create an unique scheme name (or use your existing one).
*om* keyword in scheme ID simply helps API code to detect it automatically. See more details in [Apple's documentation][linkAppleCustomUrlSchemes].

Organic Maps supports one API scheme: "om://"

You also need to add [LSApplicationQueriesSchemes][linkAppleLSApplicationQueriesSchemes] key into your plist with value *om* to correctly query if Organic Maps is already installed.

*capitals-example* folder contains sample application which demonstrates some API features.

*NOTE: If you are using Automatic References Counting (ARC) in your project, you can use [this solution][linkFixARC] or simply fix code by yourself.*

### API Calls Overview and HOW TO

* All methods are static for *OMApi* class, *BOOL* methods return *NO* if call is failed.
* If id for given pin contains valid url, it will be opened from Organic Maps after selecting *More Info* button.
  For any other content, id will be simply passed back to the caller's [*AppDelegate application:openURL:sourceApplication:annotation:*][linkAppleDelegate] method

#### Open [Organic Maps Application][linkOm]

Simply opens Organic Maps app:

    + (BOOL)showMap;

Example:

    [OMApi showMap];

#### Show specified location on the map

Displays given point on a map:

    + (BOOL)showLat:(double)lat lon:(double)lon title:(NSString *)title and:(NSString *)idOrUrl;

The same as above but using pin wrapper:

    + (BOOL)showPin:(OMPin *)pin;

Pin wrapper is a simple helper to wrap pins displayed on the map:

    @interface OMPin : NSObject
      @property (nonatomic, assign) double lat;
      @property (nonatomic, assign) double lon;
      @property (nonatomic, retain) NSString * title;
      @property (nonatomic, retain) NSString * idOrUrl;
      - (id)initWithLat:(double)lat lon:(double)lon title:(NSString *)title and:(NSString *)idOrUrl;
    @end

Example:

    [OMApi showLat:53.9 lon:27.56667 title:@"Minsk - the capital of Belarus" and:@"http://wikipedia.org/wiki/Minsk"];
    …
    OMPin * goldenGate = [[OMPin alloc] init] autorelease];
    goldenGate.lat = 37.8195;
    goldenGate.lon = -122.4785;
    goldenGate.title = @"Golden Gate in San Francisco";
    goldenGate.idOrUrl = @"any number or string here you want to receive back in your app, or any url you want to be opened from Organic Maps";
    [OMApi showPin:goldenGate];

#### Show any number of pins on the map

    + (BOOL)showPins:(NSArray *)pins;

#### Receiving results of API calls

When users presses *Back* button in Organic Maps, or selects *More Info* button, he is redirected back to your app.
Here are helper methods to obtain API call results:

Returns YES if url is received from Organic Maps and can be parsed:

    + (BOOL)isOrganicMapsUrl:(NSURL *)url;

Returns nil if user didn't select any pin and simply pressed *Back* button:

    + (OMPin *)pinFromUrl:(NSURL *)url;

Example:

    if ([OMApi isOrganicMapsUrl:url])
    {
      // Good, here we know that your app was opened from Organic Maps
      OMPin * pin = [OMApi pinFromUrl:url];
      if (pin)
      {
        // User selected specific pin, and we can get it's properties
      }
      else
      {
        // User pressed "Back" button and didn't select any pin
      }
    }

Note, that you can simply check that *sourceApplication* contains *app.organicmaps* substring to detect that your app is opened from Organic Maps.

#### Check that Organic Maps is installed

Returns NO if Organic Maps is not installed or outdated version doesn't support API calls:

    + (BOOL)isApiSupported;

With this method you can check that user needs to install Organic Maps and display your custom UI.
Alternatively, you can do nothing and use built-in dialog which will offer users to install Organic Maps.

### Set value if you want to open pin URL on balloon click

    + (void)setOpenUrlOnBalloonClick:(BOOL)value;

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
* **balloonAction** - pass openUrlOnBalloonClick as a parameter, if you want to open pin url on balloon click (usually pin url opens when "Show more info" button is pressed).

Note that you can display as many pins as you want, the only rule is that **ll** parameter comes before **n** and **id** for each point.

When user selects a pin, your app is called like this:

    YourAppUniqueUrlScheme://pin?ll=lat,lon&n=PinName&id=PinId

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
[linkAddUrlScheme]: https://raw.github.com/organicmaps/api-ios/site-resources/add_custom_url_scheme.png "How to add url scheme in XCode"
[linkDownloadOMDialog]: https://raw.github.com/organicmaps/api-ios/site-resources/download_om_dialog.png "Donwload Organic Maps Dialog"
[linkIssues]: https://github.com/organicmaps/api-ios/issues "Post a bug or feature request"
[linkAppleCustomUrlSchemes]: https://developer.apple.com/library/ios/#DOCUMENTATION/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50 "Custom URL Scheme Apple documentation"
[linkAppleDelegate]: https://developer.apple.com/library/ios/documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html#//apple_ref/occ/intfm/UIApplicationDelegate/application:openURL:sourceApplication:annotation: "AppDelegate Handle custom URL Schemes"
[linkFixARC]: http://stackoverflow.com/a/6658549/1209392 "How to compile non-ARC code in ARC projects"
[linkAppleLSApplicationQueriesSchemes]: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW14 "LSApplicationQueriesSchemes"
