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
        
        
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = NSMutableDictionary()
        
        parameters.setValue("IT WORKED1!!", forKey: "action1")
        parameters.setValue("IT WORKED2!!", forKey: "action2")
        parameters.setValue("IT WORKED3!!", forKey: "action3")

        
        
        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error != nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
            }
            else if resultTask.exception != nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
                
            }
            else if resultTask.result != nil
            {
                print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
                
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }

        
        
        
        
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

