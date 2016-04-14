//
//  ProfileViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/7/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import SimpleAuth


class ProfileViewController: UIViewController {
    
    
    @IBAction func onGetFacebookInfoButtonClicked(sender: UIButton) {
//        
//        SimpleAuth.authorize("facebook-web") { (result, error) in
//            
//            print ("RESULT IS: ", result, error)
//            
//            if (error == nil)
//            {
//                print ("RESULT IS: ", result)
//            }
//            
//        }

        // If no user currently logged in with access token, get one
        if (FBSDKAccessToken.currentAccessToken() == nil)
        {
            let login = FBSDKLoginManager.init()
            
            // Open in app instead of web browser!
            login.loginBehavior = FBSDKLoginBehavior.Native
            
            // Request basic profile permissions just to get user ID
            login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
                
                // If no error, store facebook user ID
                if (error == nil)
                {
                    print("SUCCESS LOG IN!", result.debugDescription)
                    print(FBSDKAccessToken.currentAccessToken().userID)
                }
                else if (result.isCancelled)
                {
                    print ("LOG IN CANCELLED")
                }
                else
                {
                    print("FAIL LOG IN")
                }
            }
        }
        else
        {
            showAlert("Error", message: "You have already linked your Facebook account.", buttonTitle: "Undo?", sender: self)
        }
    }

    
    @IBAction func onGetTwitterInfoClicked(sender: UIButton) {
//        showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

        
        SimpleAuth.authorize("twitter-web") { (result, error) in

            if (result == nil)
            {
                print("CANCELLED REQUEST")
            }
            else if (error == nil)
            {
                print ("RESULT IS: ", result)
            }
            else
            {
                print ("FAILED TO PROCESS REQUEST")
            }
            
        }
    
    }
    
    @IBAction func onGetInstagramInfoClicked(sender: UIButton) {

        SimpleAuth.authorize("instagram") { (result, error) in
            
            if (result == nil)
            {
                print("CANCELLED REQUEST")
            }
            else if (error == nil)
            {
                print ("RESULT IS: ", result)
            }
            else
            {
                print ("FAILED TO PROCESS REQUEST")
            }
            
        }
    }
    
    @IBAction func onGetYoutubeInfoClicked(sender: UIButton) {
        showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

    }
    
    @IBAction func onGetLinkedinInfoClicked(sender: UIButton) {
        
        SimpleAuth.authorize("linkedin-web") { (result, error) in
            
            if (result == nil)
            {
                print("CANCELLED REQUEST")
            }
            else if (error == nil)
            {
                print ("RESULT IS: ", result)
            }
            else
            {
                print ("FAILED TO PROCESS REQUEST")
            }
            
        }

        
    }
    
}
