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
//import SimpleAuth
import AWSCore
import AWSCognito
import AWSCognitoIdentityProvider
import AWSLambda
import AWSDynamoDB
import KLCPopup
import AWSMobileAnalytics

// Begin using Firebase framework
//import Firebase

var userPool : AWSCognitoIdentityUserPool!
var credentialsProvider: AWSCognitoCredentialsProvider?


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AWSCognitoIdentityInteractiveAuthenticationDelegate {
  var window: UIWindow?
  let deviceIdNotificationKey = "com.aquaintapp.deviceIdNotificationKey"
  
  override init() {
    // Firebase Init
    //FIRDatabase.database().persistenceEnabled = true
//    FIRApp.configure()
  }
  
  // wrapper function for push notification handling
  func presentSectionfromPushNotification(withIdentifier identifier: NSString) {
    /* Debug note: never instantiating a new MainContainerViewController to present!
     This works with "newFollower" and "followRequestAcceptance", but triggers "fatal error: unexpectedly found nil when unwrapping an optional value" in "newFollowRequests", when performing segue/presenting "FollowRequestsViewController"
     */
    /*
     let storyboard = UIStoryboard(name: "Main", bundle: nil)
     let vcMain = storyboard.instantiateViewControllerWithIdentifier("MainContainerViewController")
     
     window?.rootViewController = vcMain
     */
    
    if let mainViewController = self.window?.rootViewController as? MainContainerViewController {
      
      if identifier == "newFollower" {
        mainViewController.goToPage4OfSection(0)
        
      } else if identifier == "followRequestAcceptance" {
        mainViewController.goToPage4OfSection(1)
        
      } else if identifier == "newFollowRequests" {
        
        let dummyButton = UIButton()
        mainViewController.goToPage0AndShowFollowRequests()
        
        /* approach #1: directly presenting FollowRequestsViewController
         let vcFollowRequests = storyboard.instantiateViewControllerWithIdentifier("followRequestsViewController") as? FollowRequestsViewController
         window?.rootViewController = vcFollowRequests
         
         mainViewController.presentViewController(vcFollowRequests!, animated: true, completion: nil)
         */
        
        /* approach #2: presenting FollowRequestsViewController from HomeContainerViewController
         let vcHome = vc.mainPageViewController.arrayOfViewControllers[0] as! HomeContainerViewController
         let vcFollowRequest = storyboard.instantiateViewControllerWithIdentifier("followRequestsViewController")
         
         vcHome.presentViewController(vcFollowRequest, animated: true, completion: nil)
         vcHome.showViewController(vcFollowRequest, sender: vcHome)
         */
        
        /*
         if (vc!.isKindOfClass(MainContainerViewController)) {
         debugPrint("rootViewController 1")
         } else if (vc!.isKindOfClass(MainPageViewController)) {
         debugPrint("rootViewController 2")
         } else if (vc!.isKindOfClass(HomeContainerViewController)) {
         debugPrint("rootViewController 3")
         } else {
         debugPrint("rootViewController 4")
         }
         */
        
      }
    } else {
      print("Push notification not handled correctly: self.window?.rootViewController is not of type MainContainerViewController. This might be caused by the app displaying some uncommon View Controller right now.")
    }
    
    /*
     let vcFollow = storyboard.instantiateViewControllerWithIdentifier(identifier as String)
     window?.rootViewController = vcFollow
     
     if let followViewController = vcFollow as? AquaintsContainerViewController {
     let dummyButton = UIButton()
     followViewController.goToPage1(dummyButton)
     }
     */
  }
 

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // Configure Google Analytics
    guard let gai = GAI.sharedInstance() else {
      assert(false, "Google Analytics not configured correctly")
      return false
    }
    gai.trackUncaughtExceptions = true  // report uncaught exceptions
    gai.logger.logLevel = GAILogLevel.verbose  // remove before app release
    gai.tracker(withTrackingId: "UA-61394116-2")
    
    // SimpleAuth is no longer compatible with Swift 3+ due to interface changes of dependent pods (ReactiveSwift, for example)
    // social media platform-specific OAuth2 authentication will be gradually added in
    /*
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
   */

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

    
    /* If cached users, then they are logged in already
       Note we do not use credentialsProvider for login persistance, as we are unable
       to properly log users out using credentialsProvider.clearKeychain() */

    let userName = getCurrentCachedUser()

    if (userName != nil) {
      print("User already logged in!")
      print (getCurrentCachedUser())

      let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
      let viewControllerIdentifier = "MainContainerViewController"
      
      // handle push notificiations when app is killed and relaunched
      let vcMainContainer = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! MainContainerViewController
      
      if let payload = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary, let identifier = payload["identifier"] as? NSString {
        print("application(didFinishLaunchingWithOptions): with RemoteNotificaitonKey: ", payload)
        
        if identifier == "newFollower" {
          vcMainContainer.arrivedFromPushNotification = vcMainContainer.NEW_FOLLOWER
        } else if identifier == "followRequestAcceptance" {
          vcMainContainer.arrivedFromPushNotification = vcMainContainer.FOLLOW_REQUEST_ACCEPTANCE
        } else if identifier == "newFollowRequests" {
          vcMainContainer.arrivedFromPushNotification = vcMainContainer.NEW_FOLLOW_REQUESTS
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
      }
      
      // Go to home page, as if user was logged in already!
      self.window?.rootViewController = vcMainContainer
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

    
    FBSDKApplicationDelegate.sharedInstance().application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    
    let serviceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: nil)
    let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "41v7gese46ar214saeurloufe7", clientSecret: "1lr1abieg6g8fpq06hngo9edqg4qtf63n3cql1rgsvomc11jvs9b", poolId: "us-east-1_yyImSiaeD")
    
    AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
    
    userPool =  AWSCognitoIdentityUserPool(forKey: "UserPool")
    
    // Get credentials provider
    credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e", identityProviderManager: userPool)
    
    // Initialize Amazon Cognito Credentials Provider
    // let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
    let configuration = AWSServiceConfiguration(
      region: AWSRegionType.USEast1,
      credentialsProvider: credentialsProvider
    )
    AWSServiceManager.default().defaultServiceConfiguration = configuration
    
    // App Analytics
    let analyticsConfiguration = AWSMobileAnalyticsConfiguration.init()
    analyticsConfiguration.serviceConfiguration = AWSServiceManager.default().defaultServiceConfiguration
    _ = AWSMobileAnalytics.init(forAppId: "806eb8fb1f0c4af39af73c945a87e108", configuration: analyticsConfiguration, completionBlock: nil)
    
    userPool.delegate = self
    
    return AWSMobileClient.sharedInstance.didFinishLaunching(
      application,
      withOptions: launchOptions
    )
  }

  func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
    
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let controller = storyboard.instantiateViewController(withIdentifier: "loginController") as! LogInController
    
    DispatchQueue.main.async {
      self.window?.rootViewController?.present(controller, animated: true, completion: nil)
    }
    
      return controller
  }
  
  // Process results & set up for Facebook API integration
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    let handled = FBSDKApplicationDelegate.sharedInstance().application(
      application,
      open: url,
      sourceApplication: sourceApplication,
      annotation: annotation
    )
    print("FBSDK HANDLED:", handled)

    return handled
  }
  
  // Apple Push Notifications  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    
    /* previous attempts at deviceToken parsing
    let deviceTokenStr = String(data: deviceToken, encoding: NSUTF8StringEncoding);
    print("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceTokenStr)")
    let deviceTokenStr = deviceToken.base64EncodedDataWithOptions([])
    print("didRegisterForRemoteNotificationsWithDeviceToken: ", deviceTokenStr)
    */
    
    var deviceTokenStr = "\(deviceToken)"
    deviceTokenStr.remove(at: deviceTokenStr.characters.index(before: deviceTokenStr.endIndex))
    deviceTokenStr.remove(at: deviceTokenStr.startIndex)
    deviceTokenStr = deviceTokenStr.replacingOccurrences(of: " ", with: "")
    
    print("application(didRegisterForRemoteNotificationsWithDeviceToken): deviceToken = ", deviceTokenStr)
    
    setCurrentCachedDeviceID(deviceTokenStr)
    uploadDeviceIDDynamoDB(deviceTokenStr)
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notification: ", error)
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    
    print("application(didReceiveRemoteNotification): ", userInfo)
    
    // handle push notifications when app is in foreground or background
    let state: UIApplicationState = UIApplication.shared.applicationState
    if (state == .background) || (state == .inactive) {
      if let identifier = userInfo["identifier"] as? NSString {
        presentSectionfromPushNotification(withIdentifier: identifier)
      }
    } else {
      print("\(state): application not in Background or Inactive state, not doing anything.")
    }
    
    UIApplication.shared.applicationIconBadgeNumber = 0
 }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  // Called when a notification is delivered to a foreground app. iOS 10+ only
  /*
  optional func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(UNNotificationPresentationOptions.alert)
  }
  */
}
