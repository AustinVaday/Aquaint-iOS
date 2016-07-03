//
//  SignUpVerificationController.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/3/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class SignUpVerificationController: UIViewController {
    
    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    
    var pool : AWSCognitoIdentityUserPool!
    var checkMarkFlippedCopy: UIImageView!
    var userPassword: String!

    let segueDestination = "toSignUpFetchMoreDataController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // get the IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        
        // Set up animation
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        flipImageHorizontally(checkMarkFlippedCopy)

    }
    
    // Prevent non-numeric characters from being put in
    @IBAction func onTextFieldEditingDidChange(sender: UITextField) {
        
        // Prevent upper-case characters
        // Prevent lower-case characters
        // Prevent spaces
        // Prevent special characters
        
        var inputString = verificationCodeField.text!
        
        if (!inputString.isEmpty)
        {
            // Get range of all characters in the string that are not digits
            let notAcceptableRange = inputString.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            // If range of characters in given string has any non-digit characters
            // Then we must remove them
            if (notAcceptableRange != nil)
            {
                // Remove all non-digits
                inputString.removeRange(notAcceptableRange!)
                
                // Enforce this on user, set text field to no digits (and make it lowercase too while we're at it!
                verificationCodeField.text = inputString
            }
        }
        

    }
    
    
    // // When user clicks "Go" on keyboard
    @IBAction func onTextFieldDidEndOnExit(sender: AnyObject) {
        // Mimic the "Sign Up" button being pressed
        self.onVerifyButtonClicked(verifyButton.self)
    }
    
    @IBAction func onVerifyButtonClicked(sender: UIButton) {
        
        let verificationString:String = verificationCodeField.text!

        
        /*********************************************************************
         * ALERTS - send alert and leave if user enters in improper input
         **********************************************************************/
        if (verificationString.isEmpty)
        {
            showAlert("Empty field", message: "Please enter in a verification code!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyVerificationCodeLength(verificationString))
        {
            showAlert("Improper verification code", message: "The verification code is invalid. Please try again.", buttonTitle: "Try again", sender: self)
            return
        }
        
        // Disable button so that user can only send one request at a time
//        verifyButton.enabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()

        let currentUser = getCurrentUser()
        print("Current user signed in: ", currentUser)
        
        pool.getUser(currentUser).confirmSignUp(verificationString).continueWithBlock { (resultTask) -> AnyObject? in
            
            // If success code
            if resultTask.error == nil
            {
                print("CODE SUCCESSFUL")
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in

                    // Stop showing activity indicator (spinner)
                    self.spinner.stopAnimating()
                    self.checkMarkFlipped.hidden = false
                    
                    UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
                        
                        self.checkMarkFlipped.hidden = false
                        self.checkMarkFlipped.image = self.checkMark.image
                        
                        }, completion: nil)
                    
                    
                    delay(1.5)
                    {
                        
                        self.performSegueWithIdentifier(self.segueDestination, sender: nil)
                        
                    }
                    
                    self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                })
            }
            else // If fail code
            {
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in

                    self.spinner.stopAnimating()

                    showAlert("Improper verification code", message: "The verification code is invalid. Please try again.", buttonTitle: "Try again", sender: self)
                })

            }
            
            return nil
        }
        
        
        
    }
    
    // Used to pass password to next view controller
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Pass the password to next view controller so we can log user in there
        if(segue.identifier == segueDestination)
        {
            let nextViewController = segue.destinationViewController as! SignUpFetchMoreDataController
            
            nextViewController.userPassword = self.userPassword
            
        }
    }

}
