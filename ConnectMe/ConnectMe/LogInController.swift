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


class LogInController: ViewControllerPannable, AWSCognitoIdentityPasswordAuthentication {
  /**
   Obtain username and password from end user.
   @param authenticationInput input details including last known username
   @param passwordAuthenticationCompletionSource set passwordAuthenticationCompletionSource.result
   with the username and password received from the end user.
   */
  func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
    // [Swift 3 Migration] reqquired by AWSCognitoIdentityPasswordAuthentication
    return
  }

        
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
        super.viewDidLoad()
      
        // GET AWS IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        
        self.checkMark.isHidden = true
        self.checkMarkFlipped.isHidden = true
        self.emblem.isHidden = false
        
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        
        flipImageHorizontally(checkMarkFlippedCopy)
        
//        // Set up pan gesture recognizer for when the user wants to swipe left/right
//        let edgePan = UIPanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
////        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
////        edgePan.edges = .Left
//      
//        view.addGestureRecognizer(edgePan)

    }
  
    override func viewDidAppear(_ animated: Bool) {
      awsMobileAnalyticsRecordPageVisitEventTrigger("LoginController", forKey: "page_name")
    }

    
    /*=======================================================
     * BEGIN : Keyboard/Button Animations
     =======================================================*/
    // Add and Remove NSNotifications!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        deregisterForKeyboardNotifications()
    }
    
    // KEYBOARD shift-up buttons functionality
    func registerForKeyboardNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MenuController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func deregisterForKeyboardNotifications()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWasShown(_ notification: Notification!)
    {
//        // If keyboard shown already, no need to perform this method
//        if isKeyboardShown
//        {
//            return
//        }
        
        
        self.isKeyboardShown = true
        
        let userInfo = notification.userInfo!
        let keyboardSize = ((userInfo[UIKeyboardFrameBeginUserInfoKey])! as AnyObject).cgRectValue.size
        
        UIView.animate(withDuration: 0.5, animations: {
    
            print("KEYBOARD SHOWN")

            // Only show the 'submit' bar if very last entry!
            if self.userPassword.isFirstResponder
            {
                self.logInButtonBottomConstraint.constant = -keyboardSize.height
                self.view.layoutIfNeeded()
            }

            // FOR THE SCROLL VIEW
            let adjustmentHeight = keyboardSize.height
            
            // Prevent abuse. If too much content inset, do not do anything
            if self.scrollView.contentInset.bottom < adjustmentHeight
            {
                self.scrollView.contentInset.bottom += adjustmentHeight
                self.scrollView.scrollIndicatorInsets.bottom += adjustmentHeight
            }
            
        }) 
    }
    
    func keyboardWillBeHidden(_ notification: Notification!)
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
    
    func screenEdgeSwiped(_ recognizer: UIPanGestureRecognizer)
    {
      
//      if recognizer.state == .Began || recognizer.state == .Changed {
//        
//        let translation = recognizer.translationInView(self.view)
//        // note: 'view' is optional and need to be unwrapped
//        recognizer.view!.center = CGPointMake(recognizer.view!.center.x + translation.x, recognizer.view!.center.y)
//        recognizer.setTranslation(CGPointMake(0,0), inView: self.view)
//      }
//      let percent = max(recognizer.translationInView(view).x, 0) / view.frame.width
//      
//      switch recognizer.state {
//        
//      case .Began:
//        self.dismissViewControllerAnimated(true, completion: nil)
//        print("BEGAN")
//      case .Changed:
////        UIPercentDrivenInteractiveTransition.updateInteractiveTransition(percent)
//        print("CHANGED")
//      case .Ended:
//        let velocity = recognizer.velocityInView(view).x
//        
//        // Continue if drag more than 50% of screen width or velocity is higher than 1000
//        if percent > 0.5 || velocity > 1000 {
////          percentDrivenInteractiveTransition.finishInteractiveTransition()
//        } else {
////          percentDrivenInteractiveTransition.cancelInteractiveTransition()
//        }
//        
//        print("ENDED")
//        
////      case .Cancelled, .Failed: break
////        percentDrivenInteractiveTransition.cancelInteractiveTransition()
//        
//      default:
//        break
//      }
      
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
    
    @IBAction func passwordEditingDidEnd(_ sender: UITextField) {

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

    @IBAction func userNameEditingDidEnd(_ sender: AnyObject) {
    }
  
    // When user clicks "Next" on keyboard
    @IBAction func userNameEditingDidEndOnExit(_ sender: AnyObject) {
        userPassword.becomeFirstResponder()
    }
    
    // When user clicks "Go" on keyboard
    @IBAction func passwordEditingDidEndOnExit(_ sender: UITextField) {
        // Mimic clicking the log in button
        loginButtonClicked(logInButton.self)
    }
    
    @IBAction func forgotPasswordButtonClicked(_ sender: AnyObject) {
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
    
    
    
    @IBAction func loginButtonClicked(_ sender: UIButton) {
        
        // Disable log in button so that user can only send one request at a time
        logInButton.isEnabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        let userNameString:String = userName.text!.lowercased()
        let userPasswordString:String =  userPassword.text!
        
        
        // Attempt to log user in
        pool.getUser(userNameString).getSession(userNameString, password: userPasswordString, validationData: nil).continueWith(block:
          { (sessionResultTask) -> AnyObject? in
            
            // If success login
            if sessionResultTask.error == nil
            {
                //let userId = ?
        
                //TODO: Map username to user ID?
                
                
                // Perform update on UI on main thread
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    // Stop showing activity indicator (spinner)
                    self.checkMarkFlipped.isHidden = false
                    
                    self.emblem.isHidden = true
                    self.spinner.stopAnimating()
                    
                    UIView.transition(with: self.checkMarkView, duration: 1, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: { () -> Void in
                        
                        self.checkMarkFlipped.isHidden = false
                        self.checkMarkFlipped.image = self.checkMark.image
                        
                        }, completion: nil)
                    
                    
                    delay(1.5)
                    {
                        self.performSegue(withIdentifier: self.segueDestination, sender: nil)
                        // Enable the log-in button again
                        self.logInButton.isEnabled = true
                    }
                    
                    self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                    
                })
                

                // Print credentials provider
                let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
                
                
                
                // Fetch new identity ID
                credentialsProvider.getIdentityId().continueWith(block: { (task) -> AnyObject? in
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
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.spinner.stopAnimating()

                    // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the log-in button before it is disabled. This if statement prevents the display of multiple alerts).
                    if (self.presentedViewController == nil)
                    {
                        showAlert("Please try again...", message: "The username and password do not match.", buttonTitle: "Try again", sender: self)
                        
                    }
                  
                    // Enable the log-in button again
                    self.logInButton.isEnabled = true
                      
                    // Stop showing activity indicator (spinner)
                    self.spinner.stopAnimating()
                    
                    print("LogIn Error")
                    
                })

            }
            
            return nil
        })
      
        
    }
  
  /*
  func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AnyObject>) {
    
  }
  */
  
  
  
  func didCompleteStepWithError(_ error: Error?) {
    
  }

}
