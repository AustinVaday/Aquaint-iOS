//
//  LogInController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/27/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import AWSCognitoIdentityProvider
import AWSMobileHubHelper


class LogInController: UIViewController {
        
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var emblem: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var logInButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var isKeyboardShown = false
    
    var checkMarkFlippedCopy: UIImageView!
    var pool : AWSCognitoIdentityUserPool!
    
    let segueDestination = "toMainContainerViewController"
    
    // Counts how many times the user has incorrectly logged in.
    /* var wrongLogInCount: Int = 0 */
    
    override func viewDidLoad() {
        
        // GET AWS IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        self.emblem.hidden = false
        
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        
        flipImageHorizontally(checkMarkFlippedCopy)
        
        // Set up pan gesture recognizer for when the user wants to swipe left/right
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .Left
        view.addGestureRecognizer(edgePan)

    }

    
    /*=======================================================
     * BEGIN : Keyboard/Button Animations
     =======================================================*/
    // Add and Remove NSNotifications!
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        deregisterForKeyboardNotifications()
    }
    
    // KEYBOARD shift-up buttons functionality
    func registerForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MenuController.keyboardWasShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MenuController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func deregisterForKeyboardNotifications()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification!)
    {
        // If keyboard shown already, no need to perform this method
        if isKeyboardShown
        {
            return
        }
        
        self.isKeyboardShown = true
        
        let userInfo = notification.userInfo!
        let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey])!.CGRectValue.size
        
        UIView.animateWithDuration(0.5) {
    
            print("KEYBOARD SHOWN")

            self.logInButtonBottomConstraint.constant = -keyboardSize.height
            self.view.layoutIfNeeded()

            // FOR THE SCROLL VIEW
            let adjustmentHeight = keyboardSize.height
            
            // Prevent abuse. If too much content inset, do not do anything
            if self.scrollView.contentInset.bottom < adjustmentHeight
            {
                self.scrollView.contentInset.bottom += adjustmentHeight
                self.scrollView.scrollIndicatorInsets.bottom += adjustmentHeight
            }
            
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification!)
    {
        isKeyboardShown = false

        print("KEYBOARD HIDDEN")
        
        // Set constraint back to default
        self.logInButtonBottomConstraint.constant = 0
        self.view.layoutIfNeeded()

    }
    
    /*=======================================================
     * END : Keyboard/Button Animations
     =======================================================*/
    
    func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == .Ended
        {
            print("Screen swiped!")
            dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
//    @IBAction func emailEditingDidEnd(sender: UITextField) {
//        let userEmailString:String = userEmail.text!
//        
//        if (userEmailString.isEmpty)
//        {
//            print("Empty email string")
//        }
//        else if(verifyEmailFormat(userEmailString))
//        {
//            print("PROPER EMAIL")
//        }
//        else
//        {
//            //TODO: make email field red.
//            print("IMPROPER EMAIL")
//        }
//        
//        
//    }
    
    @IBAction func passwordEditingDidEnd(sender: UITextField) {

        let userPasswordString:String = userPassword.text!
        
        if (userPasswordString.isEmpty)
        {
            print("Empty password string")
        }
        else if (verifyPasswordFormat(userPasswordString))
        {
            print("PROPER PASSWORD")
        }
        else
        {
            //TODO: make password field red
            print("Please have at least 4 characters")
        }
        
    }

    @IBAction func userNameEditingDidEnd(sender: AnyObject) {
    }
  
    // When user clicks "Next" on keyboard
    @IBAction func userNameEditingDidEndOnExit(sender: AnyObject) {
        userPassword.becomeFirstResponder()
    }
    
    // When user clicks "Go" on keyboard
    @IBAction func passwordEditingDidEndOnExit(sender: UITextField) {
        // Mimic clicking the log in button
        loginButtonClicked(logInButton.self)
    }
    
    @IBAction func forgotPasswordButtonClicked(sender: AnyObject) {
//        
//        print("CLICKED!!")
//        
//        let currentUser = "austin"
//        let userPool = getAWSCognitoIdentityUserPool()
//        userPool.getUser(currentUser).forgotPassword().continueWithSuccessBlock { (resultTask) -> AnyObject? in
//            print ("forgotPassword successfully initiated")
//            
//            return nil
//        }
        
    }
    
    
    
    @IBAction func loginButtonClicked(sender: UIButton) {
        
        // Disable log in button so that user can only send one request at a time
        logInButton.enabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        let userNameString:String = userName.text!.lowercaseString
        let userPasswordString:String =  userPassword.text!
        
        
        // Attempt to log user in
        pool.getUser(userNameString).getSession(userNameString, password: userPasswordString, validationData: nil, scopes: nil).continueWithBlock({ (sessionResultTask) -> AnyObject? in
            
            // If success login
            if sessionResultTask.error == nil
            {
                //let userId = ?
        
                //TODO: Map username to user ID?
                
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    // Stop showing activity indicator (spinner)
                    self.checkMarkFlipped.hidden = false
                    
                    self.emblem.hidden = true
                    self.spinner.stopAnimating()
                    
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
                

                // Print credentials provider
                let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
                
                
                
                // Fetch new identity ID
                credentialsProvider.getIdentityId().continueWithBlock({ (task) -> AnyObject? in
                    print("^^^USER LOGGED IN:", task.result)
  
                    // Cache username, user full name, user image, and user accounts
                    setCurrentCachedUserName(userNameString)
                    setCachedUserFromAWS(userNameString)
                    
                    return nil
                })

            }
            else // If failure to login
            {
                
                // Sign out?
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.spinner.stopAnimating()

                    // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the log-in button before it is disabled. This if statement prevents the display of multiple alerts).
                    if (self.presentedViewController == nil)
                    {
                        showAlert("Please try again...", message: "The username and password do not match.", buttonTitle: "Try again", sender: self)
                        
                    }
                    
                    // Stop showing activity indicator (spinner)
                    self.spinner.stopAnimating()
                    
                    print("LogIn Error")
                    
                })

            }
            
            return nil
        })
        

        // Enable the log-in button again
        logInButton.enabled = true
        
    }
}