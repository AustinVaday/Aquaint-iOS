//
//  ViewController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 11/21/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit
import Parse

import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//
//        let testObject = PFObject(className: "Friend")
//        testObject["swagggggg"] = "SWAGGG"
//        
//        testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
//            print("Object has been saved.")
//            
//        }
    
        // Do any additional setup after loading the view, typically from a nib.
        
        /**** FB BUTTON *****
        var loginButton: FBSDKLoginButton = FBSDKLoginButton()
        
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        */
    
        
    }
    
    /**
    // FACEBOOK SDK
    func applicationDidBecomeActive(application: UIApplication!) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String, annotation: AnyObject?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    **/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

