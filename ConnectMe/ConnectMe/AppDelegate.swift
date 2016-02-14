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
import AWSCore
//import AWSCognito

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        print("LAUNCH EMBLEM PAGE HERE")
        
        // Power app with Local Datastore. For more info, go to
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("nGRlNCMIIO6mhGcWD5inHrGwzyZT4T4LYH3otLLz",
            clientKey: "ypytbHHS1NBGgrQgZLOcAXwpHbYx62YXxUhUHKs3")
        
        // Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        PFUser.logOutInBackground()
        
/*
        // Create AWS credentials provider
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:178e3120-b277-4864-9654-094f674e582b")
        
        // Set configurations
        let configurations = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        
        // Can only set the configurations once
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configurations
        
        // Get Amizon Cognito ID
        credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject? in
            
            
            if (task.error != nil)
            {
                print("Error: ", task.error?.localizedDescription)
            }
            else
            {
                // Task will contain identity id
                let cognitoID = task.result
            }
            return nil
        }
  */      
        
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

