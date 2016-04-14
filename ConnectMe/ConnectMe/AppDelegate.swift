//
//  AppDelegate.swift
//  Aquaint
//
//  Created by Austin Vaday on 11/21/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Parse
import Bolts
import FBSDKCoreKit
import FBSDKLoginKit
//import AWSCore
//import AWSCognito

import AWSS3
import AWSCore



// Begin using Firebase framework
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        

        
        // Connect to Amazon Core Services
//        let credentialsProvider = AWSCognitoCredentialsProvider(
//            regionType: AWSRegionType.USEast1, identityPoolId: "aquaint_MOBILEHUB_1504998897")
//        
//        let defaultServiceConfiguration = AWSServiceConfiguration(
//            region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
//        
//        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = defaultServiceConfiguration
        
        
        // Set up OneAll for sole-access to various social media APIs
        OAManager.sharedInstance().setupWithSubdomain("Aquaint")
    
        
        
//        OAManager.sharedInstance().loginWithSuccess({ (user, booleanVal) in
//            print("SUCCESS", user)
//        }, andFailure: { (error) in
//                print("ERROR", error.localizedDescription)
//        })
        
        
        let testURL = NSURL(fileReferenceLiteral: "https://aquaint.api.oneall.com/socialize/connect/mobile/facebook/?nonce=6ba7b810-9dad-11d1-80b4-00c04fd430c8&callback_uri=aquaint://callback")
        
        OAManager.sharedInstance().handleOpenUrl(testURL, sourceApplication: "Aquaint")
//
//        UIApplication.sharedApplication().openURL(testURL)
//        
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
    
        
        return true
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

