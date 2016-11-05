//
//  AppDelegate.swift
//  Aquaint
//
//  Created by Austin Vaday on 11/21/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import SimpleAuth
import AWSCore
import AWSCognito
import AWSLambda
import KLCPopup

// Begin using Firebase framework
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  override init() {
    // Firebase Init
    //FIRDatabase.database().persistenceEnabled = true
    FIRApp.configure()
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    SimpleAuth.configuration()["facebook"] = [
      "app_id"  : "544667035683597"
    ]

    SimpleAuth.configuration()["facebook-web"] = [
      "app_id"  : "544667035683597"
    ]

    SimpleAuth.configuration()["twitter"] = [
      "consumer_key": "idyf0Uxakx1q8r4dWA0Xs6sej",
      "consumer_secret": "cX23fqgPYzF82oloYIoxTRr6AfgQ0XhV40KyoV6KlHN81QxWht"
    ]

    SimpleAuth.configuration()["twitter-web"] = [
      "consumer_key": "idyf0Uxakx1q8r4dWA0Xs6sej",
      "consumer_secret": "cX23fqgPYzF82oloYIoxTRr6AfgQ0XhV40KyoV6KlHN81QxWht"
    ]

    SimpleAuth.configuration()["linkedin-web"] = [
      "client_id" : "75533hjqfplgv3",
      "client_secret" : "YjzhxmwGJlK4meBA",
      "redirect_uri": "http://aquaint"
    ]

    SimpleAuth.configuration()["instagram"] = [
      "client_id" : "5de275b3cf674c97b51a767e9ecdea66",
      SimpleAuthRedirectURIKey : "http://aquaint"
      // "redirect_uri" : "aquaint://"
    ]

    SimpleAuth.configuration()["tumblr"] = [
      "consumer_key": "tIjbRWwLaDWzczQ7OvD9afEzI9clVEBrRcPF3ll0ncoIhuhBfA",
      "consumer_secret": "aOWaAIe92RsV0ddP3yEDQLCwgF307CXOlyngosvbE28DLGCYVm"
    ]

    // Connect to Amazon Core Services
    /* let credentialsProvider = AWSCognitoCredentialsProvider(
      regionType: AWSRegionType.USEast1,
      identityPoolId: "aquaint_MOBILEHUB_1504998897"
    )

    let defaultServiceConfiguration = AWSServiceConfiguration(
      region: AWSRegionType.USEast1,
      credentialsProvider: credentialsProvider
    )

    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = defaultServiceConfiguration */

    // Get credentials provider
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")

    /* If cached users, then they are logged in already
       Note we do not use credentialsProvider for login persistance, as we are unable
       to properly log users out using credentialsProvider.clearKeychain() */

    let userName = getCurrentCachedUser()

    if (userName != nil) {
      print("User already logged in!")
      print (getCurrentCachedUser())

      let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
      let viewControllerIdentifier = "MainContainerViewController"
      // Go to home page, as if user was logged in already!
      self.window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerIdentifier)
      print("user already logged in")
    }

    /* credentialsProvider.getIdentityId().continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error != nil {
        print("Appdelegate: error with credentials provider", resultTask.error)
      } else if resultTask.exception != nil {
        print("Appdelegate: exception with credentials provider", resultTask.error)
      }
      else if resultTask.result == nil {
        print("Appdelegate: no result with credentials provider")
      } else {
        print("User already logged in!", resultTask.result)
        print (getCurrentUser())
        print (getCurrentUserID())

        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let viewControllerIdentifier = "MainContainerViewController"
        // Go to home page, as if user was logged in already!
        self.window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerIdentifier)
        print("user already logged in")
      }
      return nil
    } */

    // Initialize Amazon Cognito Credentials Provider
    // let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
    let configuration = AWSServiceConfiguration(
      region: AWSRegionType.USEast1,
      credentialsProvider: credentialsProvider
    )
    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration

    FBSDKApplicationDelegate.sharedInstance().application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    return AWSMobileClient.sharedInstance.didFinishLaunching(
      application,
      withOptions: launchOptions
    )
  }

  // Process results & set up for Facebook API integration
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    let handled = FBSDKApplicationDelegate.sharedInstance().application(
      application,
      openURL: url,
      sourceApplication: sourceApplication,
      annotation: annotation
    )
    print("FBSDK HANDLED:", handled)

    return handled
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}
