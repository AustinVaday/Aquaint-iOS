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


class ProfileViewController: UIViewController {
    
    
    @IBAction func onGetFacebookInfoButtonClicked(sender: UIButton) {
        

        if (FBSDKAccessToken.currentAccessToken() == nil)
        {
            print ("Log in token is NIL. Fixing this.")
            let login = FBSDKLoginManager.init()
            
            login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
                
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

}
