//
//  LogInController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/27/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit
import Parse

class LogInController: UIViewController {
        
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var checkMark: UIImageView!
    
    
    @IBAction func emailEditingDidEnd(sender: UITextField) {
    }
    
    @IBAction func passwordEditingDidEnd(sender: UITextField) {
    }

    @IBAction func loginButtonClicked(sender: UIButton) {
        
        let userEmailString:String = userEmail.text!
        let userPasswordString:String =  userPassword.text!
        
        print(userEmailString)
        print(userPasswordString)
        PFUser.logOut()
        PFUser.logInWithUsernameInBackground(userEmailString, password: userPasswordString)
        
        let currentUser = PFUser.currentUser()

        if(currentUser != nil)
        {
            
            print(currentUser?.email)
            print(currentUser?.username)
            print("User logged in!")
            performSegueWithIdentifier("HomeViewController", sender: nil)
            
        }
        else
        {
//            let alert = UIAlertController(title: "Error", message: "Email or Password does not exist", preferredStyle: UIAlertControllerStyle.Alert)
//            
//            alert.showViewController(alert, sender: nil)
            
            print("LogIn Error")
        }

        
    }
    
    
}
