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
import AWSCognitoIdentityProvider
import AWSLambda
import AWSDynamoDB
import KLCPopup

// Begin using Firebase framework
import Firebase

var userPool : AWSCognitoIdentityUserPool!
var credentialsProvider: AWSCognitoCredentialsProvider?


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AWSCognitoIdentityInteractiveAuthenticationDelegate {
  var window: UIWindow?
  let deviceIdNotificationKey = "com.aquaintapp.deviceIdNotificationKey"
  
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

    
    FBSDKApplicationDelegate.sharedInstance().application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    
    let serviceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: nil)
    let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "41v7gese46ar214saeurloufe7", clientSecret: "1lr1abieg6g8fpq06hngo9edqg4qtf63n3cql1rgsvomc11jvs9b", poolId: "us-east-1_yyImSiaeD")
    
    AWSCognitoIdentityUserPool.registerCognitoIdentityUserPoolWithConfiguration(serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
    
    userPool =  AWSCognitoIdentityUserPool(forKey: "UserPool")
    
    // Get credentials provider
    credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e", identityProviderManager: userPool)
    
    // Initialize Amazon Cognito Credentials Provider
    // let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
    let configuration = AWSServiceConfiguration(
      region: AWSRegionType.USEast1,
      credentialsProvider: credentialsProvider
    )
    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
    
    userPool.delegate = self
    
    /*
    print("application(didFinishLaunchingWithOptions) called. ")
    if let payload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary, identifier = payload["identifier"] as? String {
      print("Handling push notification in application(didFinishLaunchingWithOptions). ")
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      let vc = storyboard.instantiateViewControllerWithIdentifier(identifier)
      window?.rootViewController = vc
    }
    */
    // handling push notificiations when app is killed and relaunched
    if let payload = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary, identifier = payload["identifier"] as? String {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vcMain = storyboard.instantiateViewControllerWithIdentifier("MainContainerViewController")
        
        window?.rootViewController = vcMain
        
        if let mainViewController = vcMain as? MainContainerViewController {
          if identifier == "newFollower" {
            mainViewController.goToPage2OfSection(0)
          } else if identifier == "followRequestAcceptance" {
            mainViewController.goToPage2OfSection(1)
          } else if identifier == "newFollowRequests" {
            
            let vcFollowRequests = storyboard.instantiateViewControllerWithIdentifier("followRequestsViewController")
            window?.rootViewController = vcFollowRequests
          }
        }
    }
    
    return AWSMobileClient.sharedInstance.didFinishLaunching(
      application,
      withOptions: launchOptions
    )
  }

  func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
    
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let controller = storyboard.instantiateViewControllerWithIdentifier("loginController") as! LogInController
    
    dispatch_async(dispatch_get_main_queue()) {
      self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
    }
    
      return controller
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
  
  // Apple Push Notifications
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    print("CORRECT - didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
    //let deviceTokenStr = String(data: deviceToken, encoding: NSUTF8StringEncoding);
    //print("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceTokenStr)")
    //let deviceTokenStr = deviceToken.base64EncodedDataWithOptions([])
    //print("didRegisterForRemoteNotificationsWithDeviceToken: ", deviceTokenStr)
    var deviceTokenStr = "\(deviceToken)"
    deviceTokenStr.removeAtIndex(deviceTokenStr.endIndex.predecessor())
    deviceTokenStr.removeAtIndex(deviceTokenStr.startIndex)
    deviceTokenStr = deviceTokenStr.stringByReplacingOccurrencesOfString(" ", withString: "")
    
    print("didRegisterForRemoteNotificationsWithDeviceToken: ", deviceTokenStr)
    setCurrentCachedDeviceID(deviceTokenStr)
    
    uploadDeviceIDDynamoDB(deviceTokenStr)
  }

  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    print("Failed to register for remote notification: ", error)
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    print("didReceiveRemoteNotification", userInfo)
    
    // handle push notifications when app is in foreground or background
    let PNContent = userInfo["aps"]!
    print(PNContent)
    
    if let aps = userInfo["aps"] as? NSDictionary {
      if let identifier = aps["identifier"] as? NSString {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vcMain = storyboard.instantiateViewControllerWithIdentifier("MainContainerViewController")
        
        window?.rootViewController = vcMain
        
        if let mainViewController = vcMain as? MainContainerViewController {
          if identifier == "newFollower" {
            mainViewController.goToPage2OfSection(0)
          } else if identifier == "followRequestAcceptance" {
            mainViewController.goToPage2OfSection(1)
          } else if identifier == "newFollowRequests" {
            
            /*
            let vcFollowRequests = storyboard.instantiateViewControllerWithIdentifier("followRequestsViewController") as? FollowRequestsViewController
            window?.rootViewController = vcFollowRequests
             
            mainViewController.presentViewController(vcFollowRequests!, animated: true, completion: nil)
            */
            
            let vc = self.window?.rootViewController as! MainContainerViewController
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
            let vcHome = vc.mainPageViewController.arrayOfViewControllers[0] as! HomeContainerViewController
            //vcHome.performSegueWithIdentifier("toFollowRequestsViewController", sender: vc)
            
            let vcFollowRequest = storyboard.instantiateViewControllerWithIdentifier("followRequestsViewController")
            //vcHome.presentViewController(vcFollowRequest, animated: true, completion: nil)
            vcHome.showViewController(vcFollowRequest, sender: vcHome)
          }
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
    }
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
  
  // Called when a notification is delivered to a foreground app. iOS 10+ only
  /*
  optional func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(UNNotificationPresentationOptions.alert)
  }
  */
}
