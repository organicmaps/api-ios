/*******************************************************************************

 Copyright (c) 2022, Organic Maps OU
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

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "CityDetailViewController.h"

#import "OrganicMapsAPI.h"

@implementation AppDelegate

// Organic Maps API entry point, when user comes back to your app
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  if ([OMApi isOrganicMapsUrl:url])
  {
    // if we got nil, it means that Back button was pressed without selecting any pin
    OMPin * pin = [OMApi pinFromUrl:url];
    if (pin)
    {
      NSInteger const cityId = [pin.idOrUrl integerValue];
      // display selected page based on passed id
      if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
      {
        [self.navigationController popToRootViewControllerAnimated:NO];
        MasterViewController * masterVC = self.navigationController.viewControllers[0];
        if (!masterVC.detailViewController)
          masterVC.detailViewController = [[CityDetailViewController alloc] initWithNibName:@"CityDetailViewController" bundle:nil];
        masterVC.detailViewController.city = masterVC.capitals[cityId];
        masterVC.detailViewController.cityIndex = cityId;
        [masterVC.navigationController pushViewController:masterVC.detailViewController animated:YES];
      }
      else
      {
        CityDetailViewController * detailVC = (CityDetailViewController *)self.splitViewController.delegate;
        detailVC.cityIndex = cityId;
      }
    }
    return YES;
  }
  return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
  {
    MasterViewController * masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    self.window.rootViewController = self.navigationController;
  }
  else
  {
    MasterViewController * masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
    UINavigationController * masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    CityDetailViewController * detailViewController = [[CityDetailViewController alloc] initWithNibName:@"CityDetailViewController" bundle:nil];
    UINavigationController * detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];

    masterViewController.detailViewController = detailViewController;

    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.delegate = detailViewController;
    self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];

    self.window.rootViewController = self.splitViewController;
  }

  [self.window makeKeyAndVisible];
  return YES;
}

@end
