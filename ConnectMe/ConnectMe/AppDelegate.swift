//
//  AppDelegate.swift
//  Aquaint
//
//  Created by Austin Vaday on 11/21/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
//import Parse
//import Bolts
import FBSDKCoreKit
import FBSDKLoginKit
//import AWSCore
//import AWSCognito

//import AWSS3
//import AWSCore

import SimpleAuth

// Begin using Firebase framework
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

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
            "client_id" : "08e0622dff7846d2850a506dfbc723a3",
            SimpleAuthRedirectURIKey : "aquaint://"
        ]
                
        
        // Connect to Amazon Core Services
//        let credentialsProvider = AWSCognitoCredentialsProvider(
//            regionType: AWSRegionType.USEast1, identityPoolId: "aquaint_MOBILEHUB_1504998897")
//        
//        let defaultServiceConfiguration = AWSServiceConfiguration(
//            region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
//        
//        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = defaultServiceConfiguration
        
        
        
        // If user is already logged into Firebase, go to home page instead of log-in/sign-up pages
        let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com"
        
        // Get the firebase ref so that we can logout on firebase
        let firebaseRootRef = Firebase(url: firebaseRootRefString)

        // If user is authenticated already, show correct view controller
        if (firebaseRootRef.authData != nil)
        {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            let viewControllerIdentifier = "MainContainerViewController"

            // Go to home page, as if user was logged in already!
            self.window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerIdentifier)
            print("user already logged in")
        }
        else
        {
            print("no user logged in yet!")
        }
        
        
        FIRApp.configure()

        
        return true
    }
    
    // Process results & set up for Facebook API integration
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        let handled = FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication , annotation: annotation)
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

