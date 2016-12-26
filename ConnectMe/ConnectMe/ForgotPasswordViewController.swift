//
//  ForgotPasswordViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/25/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import AWSS3
import AWSMobileHubHelper
import AWSDynamoDB
import SCLAlertView

class ForgotPasswordViewController: UIViewController {

  
  //    @IBOutlet weak var realNameField: UITextField!
  //    @IBOutlet weak var realNameButton: UIButton!
  
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var checkMarkFlipped: UIImageView!
  @IBOutlet weak var checkMark: UIImageView!
  @IBOutlet weak var checkMarkView: UIView!
  @IBOutlet weak var buttonToFlip: UIButton!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var userPassword: UITextField!
  @IBOutlet weak var userName: UITextField!
  @IBOutlet weak var userPhone: UITextField!
  @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
  
  var isKeyboardShown = false
  var pool : AWSCognitoIdentityUserPool!
  var checkMarkFlippedCopy: UIImageView!
  
//  var userPhone : String!
//  var userEmail : String!

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // get the IDENTITY POOL
    pool = getAWSCognitoIdentityUserPool()
    
    resetAnimations()
    
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
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ForgotPasswordViewController.keyboardWasShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ForgotPasswordViewController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
    
  }
  
  func deregisterForKeyboardNotifications()
  {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
  }
  
  func keyboardWasShown(notification: NSNotification!)
  {
    //        // If keyboard shown already, no need to perform this method
    //        if isKeyboardShown
    //        {
    //            return
    //        }
    
    self.isKeyboardShown = true
    
    let userInfo = notification.userInfo!
    let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey])!.CGRectValue.size
    
    UIView.animateWithDuration(0.5) {
      
      print("KEYBOARD SHOWN")
      
      if self.userPassword.isFirstResponder()
      {
        self.buttonBottomConstraint.constant = keyboardSize.height
        self.view.layoutIfNeeded()
      }
      
      // FOR THE SCROLL VIEW
      let adjustmentHeight = CGFloat(20)
      
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
    self.buttonBottomConstraint.constant = 0
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
  
  // When user clicks "next" on keyboard
  @IBAction func onUserNameEditingDidEndOnExit(sender: AnyObject) {
    userPassword.becomeFirstResponder()
  }
  
  // When user clicks "Go" on keyboard
  @IBAction func onPasswordEditingDidEndOnExit(sender: AnyObject) {
    // Mimic the "Sign Up" button being pressed
    self.onFinishButtonClicked(nextButton.self)
    
  }
  
  // Actively edit phone number
  @IBAction func onPhoneEditingDidChange(sender: UITextField) {
    
    let phoneString = userPhone.text
    userPhone.text = removeAllNonDigits(phoneString!)
    
  }
  
  @IBAction func onFinishButtonClicked(sender: UIButton) {
    // Disable button so that user cannot click on it twice (this is how errors happen)
//    self.nextButton.enabled = false
    
    let userNameString:String = userName.text!
    let userPasswordString:String = userPassword.text!
    let userPhoneString:String = userPhone.text!

    /*********************************************************************
     * ALERTS - send alert and leave if user enters in improper input
     **********************************************************************/
    if (!verifyUserNameLength(userNameString))
    {
      showAlert("Improper username format", message: "Please create a username between 5 and 20 characters long!", buttonTitle: "Try again", sender: self)
      return
    }
    
    if (!verifyUserNameFormat(userNameString))
    {
      showAlert("Improper username format", message: "Please use a proper username format: no spaces and no special characters other than '-' and '_'!", buttonTitle: "Try again", sender: self)
      return
    }
    
    if (userPhoneString.isEmpty)
    {
      showAlert("Error with request", message: "Please enter in a phone number!", buttonTitle: "Try again", sender: self)
      return
    }
    
    if (!verifyPhoneFormat(userPhoneString))
    {
      showAlert("Error with request", message: "Please enter in a proper U.S. phone number.", buttonTitle: "Try again", sender: self)
      return
    }
    
    if (userPasswordString.isEmpty)
    {
      showAlert("Error with request", message: "Please enter in a password!", buttonTitle: "Try again", sender: self)
      return
    }
    
    // API restriction: Password must be at least 6 characters... (or it will throw an error)
    if (userPasswordString.characters.count < 6)
    {
      showAlert("Error with request", message: "Please enter in a password that is more than 6 characters!", buttonTitle: "Try again", sender: self)
      return
    }
    
    let lowerCaseUserNameString = userNameString.lowercaseString

    // Get user from cognito pool. Need to make sure phone numbers match.
    let poolUser = pool.getUser(lowerCaseUserNameString)
    
//    // Get UserPool Data too (email, phone info)
//    getUserPoolData(lowerCaseUserNameString) { (result, error) in
//      
//      if (error == nil && result != nil)
//      {
//        let userPoolData = result
//        let realPhoneNum = userPoolData!.phoneNumber!
//        
//        dispatch_async(dispatch_get_main_queue(), {
//          if realPhoneNum != userPhoneString {
//            showAlert("Error with request", message: "The phone number you provided does not match the phone number we have in the system.", buttonTitle: "Try again", sender: self)
//            return
//          }
    
          // If phone numbers match...
          // What if userNameString is nil?
          poolUser.forgotPassword().continueWithBlock { (resultTask) -> AnyObject? in
            // Success
            if resultTask.error == nil && resultTask.result != nil {
              // Popup - say that we sent code to a number. Enter code here
              dispatch_async(dispatch_get_main_queue(), {
                self.showAndProcessUsernameAlert(poolUser, password: userPasswordString)
              })
            }
            else {
              // Popup - could not send code at time, maybe phone is not verified
              dispatch_async(dispatch_get_main_queue(), {
                showAlert("Error with request.", message: "Sorry, we could not process your request at this time. Please contact customer support.", buttonTitle: "Ok", sender: self)
                self.nextButton.enabled = true
              })
              
              
            }
            return nil
          }
          
//        })
//    
//      }
//
//    }
  }

  private func resetAnimations()
  {
    // Set up animation
    self.checkMark.hidden = true
    self.checkMarkFlipped.hidden = true
    self.buttonToFlip.hidden = false
    checkMarkFlippedCopy = UIImageView(image: checkMark.image)
    flipImageHorizontally(checkMarkFlippedCopy)
  }
  
  func confirmForgottenPassword(poolUser: AWSCognitoIdentityUser, password: String, confirmationCode: String) {
    poolUser.confirmForgotPassword(confirmationCode, password: password).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil {
        print("Great success.")
        // Perform update on UI on main thread
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          
          // Stop showing activity indicator (spinner)
          self.checkMarkFlipped.hidden = false
          
          self.buttonToFlip.hidden = true
          self.spinner.stopAnimating()
          
          UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
            
            self.checkMarkFlipped.hidden = false
            self.checkMarkFlipped.image = self.checkMark.image
            
            }, completion: nil)
          
          delay(1.5) {
            self.dismissViewControllerAnimated(true, completion: nil)
            // Disable button so that user cannot click on it twice (this is how errors happen)
            self.nextButton.enabled = true
          }
          

          self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
          
        })

      } else {
        dispatch_async(dispatch_get_main_queue(), {
          showAlert("Improper verification code", message: "The verification code is invalid. Please try again.", buttonTitle: "Try again", sender: self)
          self.spinner.stopAnimating()
          // Disable button so that user cannot click on it twice (this is how errors happen)
          self.nextButton.enabled = true

        })
      }
      
      return nil
    }

  }
  
  func textFieldDidChange(textField: UITextField) {
    var codeString = removeAllNonDigits(textField.text!)
    
    if codeString.characters.count > 6 {
      let index = codeString.startIndex.advancedBy(6)
      codeString = codeString.substringToIndex(index)
    }
    
    textField.text = codeString
  }
  
  private func showAndProcessUsernameAlert(user: AWSCognitoIdentityUser, password: String) {
    var alertViewResponder: SCLAlertViewResponder!
    let subview = UIView(frame: CGRectMake(0,0,216,70))
    let x = (subview.frame.width - 180) / 2
    let colorDarkBlue = UIColor(
      red:  0.06,
      green: 0.48,
      blue: 0.62,
      alpha: 1.0
    )
    
    // Add text field for username
    let textField = UITextField(frame: CGRectMake(x,10,180,25))
    
    textField.font          = UIFont(name: "Avenir Roman", size: 14.0)
    textField.textColor     = colorDarkBlue
    textField.placeholder   = "Enter 6-digit code"
    textField.textAlignment = NSTextAlignment.Center
    
    // Add target to text field to validate/fix user input of a proper input
    textField.addTarget(
      self,
      action: #selector(textFieldDidChange),
      forControlEvents: UIControlEvents.EditingChanged
    )
    subview.addSubview(textField)
    
    let alertAppearance = SCLAlertView.SCLAppearance(
      shouldAutoDismiss: false,
      hideWhenBackgroundViewIsTapped: true
    )
    
    let alertView = SCLAlertView(appearance: alertAppearance)
    
    alertView.customSubview = subview
    alertView.addButton(
      "Submit",
      action: {
        print("Save button clicked for textField data:", textField.text)
        
        if alertViewResponder == nil {
          print("Something went wrong...")
          return
        }
        
        self.spinner.startAnimating()
        
        let value = textField.text!
        
        if value.isEmpty {
          // TODO: Nothing?
        } else if value.characters.count > 6 {
          // TODO: Notify that username is too long
          alertViewResponder.close()
        } else {
          print(" value returned is: ", value)
          
          self.confirmForgottenPassword(user, password: password, confirmationCode: value)
          alertViewResponder.close()
        }
      }
    )
    
    alertViewResponder = alertView.showTitle("We sent you a code!",
                                             subTitle: "",
                                             duration:0.0,
                                             completeText: "Cancel",
                                             style: .Success,
                                             colorStyle: 0x0F7A9D,
                                             colorTextButton: 0xFFFFFF,
                                             animationStyle: .BottomToTop
    )
  }
  
}
