//
//  ViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 11/21/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import Parse

import FBSDKCoreKit
import FBSDKLoginKit
import AWSLambda

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
  
  @IBAction func loginWithFacebookButtonClicked(sender: AnyObject) {
    let login = FBSDKLoginManager.init()
    login.logOut()
    
    // Open in app instead of web browser!
    login.loginBehavior = FBSDKLoginBehavior.Native
    
    // Request basic profile permissions just to get user ID
    login.logInWithReadPermissions(["public_profile", "user_friends", "email"], fromViewController: self) { (result, error) in
      // If no error, store facebook user ID
      if (error == nil && result != nil) {
        if (FBSDKAccessToken.currentAccessToken() != nil) {
          print("Current access user id: ", FBSDKAccessToken.currentAccessToken().userID)
          print("RESULTOO: ", result)

//          let fbUID = FBSDKAccessToken.currentAccessToken().userID
          
          
          let request = FBSDKGraphRequest(graphPath: "/me?locale=en_US&fields=name,email", parameters: nil)
          request.startWithCompletionHandler { (connection, result, error) in
            if error == nil {
              print("Result is FB!!: ", result)
              let resultMap = result as! Dictionary<String, String>

              let userFullName = resultMap["name"]
              let userEmail = resultMap["email"]
              let fbUID = resultMap["id"]

              
              let a = "a"
              
            } else {
              print("Error getting **FB friends", error)
            }
          }

          
          // Attempt to find user
          
          
//          let currentUserName = getCurrentCachedUser()
//          uploadUserFBUIDToDynamo(currentUserName, fbUID: fbUID)
        }
      } else if (result == nil && error != nil) {
        print ("ERROR IS: ", error)
      } else {
        print("FAIL LOG IN")
      }
    }

  }
  
  


}

