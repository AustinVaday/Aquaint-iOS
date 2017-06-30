//
//  SignUpFetchMoreDataController.swift
//
//
//  Created by Austin Vaday on 7/3/16.
//
//

import UIKit
import AWSCognitoIdentityProvider
import AWSS3
import AWSMobileHubHelper
import AWSDynamoDB

class PasswordResetViewController: ViewControllerPannable {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var buttonToFlip: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    var isKeyboardShown = false
    var pool : AWSCognitoIdentityUserPool!
    var checkMarkFlippedCopy: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        resetAnimations()
    }
    
    
    /*=======================================================
     * BEGIN : Keyboard/Button Animations
     =======================================================*/
    
    // Add and Remove NSNotifications!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        registerForKeyboardNotifications()
        
        // Set up pan gesture recognizer for when the user wants to swipe left/right
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
        
    }
  
    override func viewDidAppear(_ animated: Bool) {
      awsMobileAnalyticsRecordPageVisitEventTrigger("PasswordResetViewController", forKey: "page_name")
    }
    
    
    func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == .ended
        {
            print("Screen swiped!")
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        deregisterForKeyboardNotifications()
    }
    
    // KEYBOARD shift-up buttons functionality
    func registerForKeyboardNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(PasswordResetViewController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PasswordResetViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func deregisterForKeyboardNotifications()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWasShown(_ notification: Notification!)
    {
        // If keyboard shown already, no need to perform this method
        if isKeyboardShown
        {
            return
        }
        
        self.isKeyboardShown = true
        
        let userInfo = notification.userInfo!
        let keyboardSize = ((userInfo[UIKeyboardFrameBeginUserInfoKey])! as AnyObject).cgRectValue.size
        
        UIView.animate(withDuration: 0.5, animations: {
            
            print("KEYBOARD SHOWN")
            
            self.buttonBottomConstraint.constant = keyboardSize.height
            self.view.layoutIfNeeded()
            
            // FOR THE SCROLL VIEW
            let adjustmentHeight = CGFloat(20)
            
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
        self.buttonBottomConstraint.constant = 0
        self.view.layoutIfNeeded()
        
    }
    
    /*=======================================================
     * END : Keyboard/Button Animations
     =======================================================*/
    @IBAction func onOldPasswordEditingDidEndOnExit(_ sender: AnyObject) {
        newPassword.becomeFirstResponder()
    }

    // When user clicks "Go" on keyboard
    @IBAction func onNewPasswordEditingDidEndOnExit(_ sender: AnyObject) {
        self.onFinishButtonClicked(nextButton.self)
    }

    
    @IBAction func onFinishButtonClicked(_ sender: UIButton) {
        
        let oldPasswordString:String = oldPassword.text!
        let newPasswordString:String = newPassword.text!
        
        /*********************************************************************
         * ALERTS - send alert and leave if user enters in improper input
         **********************************************************************/
        if (oldPasswordString.isEmpty)
        {
            showAlert("Error with request", message: "Please enter in a proper old password!", buttonTitle: "Try again", sender: self)
            return
        }
        
        // API restriction: Password must be at least 6 characters... (or it will throw an error)
        if (oldPasswordString.characters.count < 6)
        {
            showAlert("Error with request", message: "Please enter in a proper old password that is more than 6 characters!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (newPasswordString.isEmpty)
        {
            showAlert("Error with request", message: "Please enter in a proper new password!", buttonTitle: "Try again", sender: self)
            return
        }
        
        // API restriction: Password must be at least 6 characters... (or it will throw an error)
        if (newPasswordString.characters.count < 6)
        {
            showAlert("Error with request", message: "Please enter in a proper new password that is more than 6 characters!", buttonTitle: "Try again", sender: self)
            return
        }
        
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        let currentUser = getCurrentCachedUser()
        
        pool.getUser(currentUser!).changePassword(oldPasswordString, proposedPassword: newPasswordString).continueWith { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil
            {
                // Show the special checkmark animation
                // Perform update on UI on main thread
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    // Stop showing activity indicator (spinner)
                    self.checkMarkFlipped.isHidden = false
                    
                    self.buttonToFlip.isHidden = true
                    self.spinner.stopAnimating()
                    
                    UIView.transition(with: self.checkMarkView, duration: 1, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: { () -> Void in
                        
                        self.checkMarkFlipped.isHidden = false
                        self.checkMarkFlipped.image = self.checkMark.image
                        
                        }, completion: nil)
                    
                    
                    delay(1.5)
                    {
                        
                        self.dismiss(animated: true, completion: nil)
                        
                    }
                    
                    self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                    
                })

                
            }
            else
            {
                // Error with request
                // Perform update on UI on main thread
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    // Stop showing activity indicator (spinner)
                    self.spinner.stopAnimating()
                    
                    // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the button before it is disabled. This if statement prevents the display of multiple alerts).
                    if (self.presentedViewController == nil)
                    {
                        
                        showAlert("Error changing password.", message: "Sorry, we could not change your password at this time. Please try again later!", buttonTitle: "Try again", sender: self)
                    }
                    
                })

            }
            return nil
        }
    }
    
    fileprivate func resetAnimations()
    {
        // Set up animation
        self.checkMark.isHidden = true
        self.checkMarkFlipped.isHidden = true
        self.buttonToFlip.isHidden = false
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        flipImageHorizontally(checkMarkFlippedCopy)
    }
    
}
