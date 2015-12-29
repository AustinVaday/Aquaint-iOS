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
        
//        print(userEmailString)
//        print(userPasswordString)

        PFUser.logInWithUsernameInBackground(userEmailString, password: userPasswordString)
        
//        PFUser.logInWithUsernameInBackground("Austin", password: "123")
        
        var currentUser = PFUser.currentUser()

        if(currentUser != nil)
        {
            
            currentUser = currentUser!

            print("User logged in!")
            performSegueWithIdentifier("HomeViewController", sender: nil)
            
        }
        else
        {
            // Create alert to send to user
            let alert = UIAlertController(title: "Please try again...", message: "The email and password do not match.", preferredStyle: UIAlertControllerStyle.Alert)

            // Create the action to add to alert
            let alertAction = UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default, handler: nil)
           
            // Add the action to the alert
            alert.addAction(alertAction)
            
            // Show the alert
            showViewController(alert, sender: nil)
        
            
            print("LogIn Error")
        }

        
    }
    
    
}
