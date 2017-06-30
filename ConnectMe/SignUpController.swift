//
//  SignUpController.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/13/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider
import AWSS3
import FBSDKCoreKit
import FBSDKLoginKit
import AWSDynamoDB
import RSKImageCropper

class SignUpController: ViewControllerPannable, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, UINavigationControllerDelegate {
    
    // UI variable data types
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPhone: UITextField!
    @IBOutlet weak var userFullName: UITextField!
    @IBOutlet weak var userPhoto: UIButton!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var formView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var facebookButton: UIButton!
    
//    @IBOutlet weak var orSignInWithLabel: UIView!
    var fbImage : UIImage!
    var fbFullName : String!
    var fbEmail : String!
    var fbUID : String!
    var isKeyboardShown = false
    var isSignUpWithFacebook = false
    var didSignInObserver: AnyObject!
    var pool: AWSCognitoIdentityUserPool!
    var credentialsProvider: AWSCognitoCredentialsProvider!
    var uploadRequest: AWSS3TransferManagerUploadRequest!
    var fileManager : AWSUserFileManager!
    
    var checkMarkFlippedCopy: UIImageView!
    var prevEmailString: String!                // Used to prevent user from spamming requests
    var imagePicker:UIImagePickerController!    // Used for selecting image from user's device

    let segueDestination = "toSignUpFetchMoreDataController"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("VIEW JUST LOADED!")

//        // Not needed at the moment, we verify only US numbers
//        let userPhone = PhoneNumberTextField()
//        print("USER PHONE:", userPhone.currentRegion)
//        print("USER PHONE:", userPhone.defaultRegion)

        // Make the button round!
        userPhoto.clipsToBounds = true
        userPhoto.layer.cornerRadius = userPhoto.frame.size.width / 2
        userPhoto.contentVerticalAlignment = UIControlContentVerticalAlignment.fill
        userPhoto.contentHorizontalAlignment = UIControlContentHorizontalAlignment.fill
        
        // Set up animation
        resetAnimations()
        
        // Empty previous email string
        prevEmailString = ""
        
        // Set up pan gesture recognizer for when the user wants to swipe left/right
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //TODO: INVESTIGATE UIImagePickerController class
        // The following initialization, for some reason, takes longer than usual. Doing this AFTER the view appears so that there's no obvious delay in any transitions.
        imagePicker = UIImagePickerController()
      
      awsMobileAnalyticsRecordPageVisitEventTrigger("SignUpController", forKey: "page_name")
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
            
            if self.userFullName.isFirstResponder
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
    
    func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == .ended
        {
            print("Screen swiped!")
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleLoginWithSignInProvider(_ sender: UIButton) {
        
        AWSIdentityManager.default().loginWithSign(AWSFacebookSignInProvider.sharedInstance(), completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true, completion: nil)
                })
            }
            print("result = \(result), error = \(error)")
        } as! (Any?, Error?) -> Void)

    }
    
    // Functionality for adding in a user specific photograph
    @IBAction func addPhotoButtonClicked(_ sender: UIButton) {
        
        
        // Present the Saved Photo Album to user only if it is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
        {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    // When user finishes picking an image, this function is called and we set the user's image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [AnyHashable: Any]?) {
        
        // Close the image picker view when user is finished with it
        self.dismiss(animated: true) { 
          var imageCropVC : RSKImageCropViewController!
          imageCropVC = RSKImageCropViewController(image: image, cropMode: RSKImageCropMode.circle)
          
          imageCropVC.delegate = self
          
          self.present(imageCropVC, animated: true, completion: nil)
      }
        
    }
  
    // RSKImageCropViewController lets us easily crop our pictures!
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
      controller.dismiss(animated: true, completion: nil)
    }
  
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
      controller.dismiss(animated: true, completion: nil)
      
      // Set the button's new image
      userPhoto.setImage(croppedImage, for: UIControlState())
    }
  
    // Ensure email is proper
    @IBAction func emailEditingDidEnd(_ sender: UITextField) {
        
        let userEmailString:String = userEmail.text!
        
        if (userEmailString.isEmpty)
        {
            print("Empty email string")
        }
        else if(verifyEmailFormat(userEmailString))
        {
            print("PROPER EMAIL")
        }
        else
        {
            //TODO: make email field red.
            print("IMPROPER EMAIL")
        }
        
    }
    
    // Ensure phone is proper
    @IBAction func phoneEditingDidEnd(_ sender: UITextField) {
        // Do this later if you want dynamic checking
    }
    
    // Ensure full name is proper
    @IBAction func fullNameEditingDidEnd(_ sender: UITextField) {
        // Do this later if you want dynamic checking

    }
    
    // Actively edit phone number
    @IBAction func onPhoneEditingDidChange(_ sender: UITextField) {
        
        let phoneString = userPhone.text
        
        userPhone.text = removeAllNonDigits(phoneString!)
        
    }
    
    
    // When user clicks "Next" on keyboard
    @IBAction func emailEditingDidEndOnExit(_ sender: AnyObject) {
        // Give control to next field
        userPhone.becomeFirstResponder()

    }

    // When user clicks "Next" on keyboard
    @IBAction func phoneEditingDidEndOnExit(_ sender: UITextField) {
        // Give control to next field
        userFullName.becomeFirstResponder()
    }
    
    @IBAction func fullNameEditingDidEndOnExit(_ sender: UITextField) {
        // Mimic the "Sign Up" button being pressed
        self.signUpButtonClicked(signUpButton.self)
    }
    
     // Actions to perform when "Next" (Sign up) button is clicked
    @IBAction func signUpButtonClicked(_ sender: AnyObject) {
        
        let userEmailString:String = userEmail.text!
        let userPhoneString:String = userPhone.text!
        let userFullNameString:String =  userFullName.text!
//        var userNameExists = false
        
        // Cache the user email and phone!
        setCurrentCachedUserEmail(userEmailString)
        setCurrentCachedUserPhone(userPhoneString)

        /*********************************************************************
        * ALERTS - send alert and leave if user enters in improper input
        **********************************************************************/
        if (userFullNameString.isEmpty)
        {
            showAlert("Error signing up", message: "Please enter in a proper full name!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyRealNameLength(userFullNameString))
        {
            showAlert("Improper full name format", message: "Please create a full name that is less than 30 characters long!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (userEmailString.isEmpty)
        {
            showAlert("Error signing up", message: "Please enter in an email address!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyEmailFormat(userEmailString))
        {
            showAlert("Improper email address", message: "Please enter in a proper email address!", buttonTitle: "Try again", sender: self)
            return
        }

        if (userPhoneString.isEmpty)
        {
            showAlert("Error signing up", message: "Please enter in a phone number!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyPhoneFormat(userPhoneString))
        {
            showAlert("Error signing up", message: "Please enter in a proper U.S. phone number.", buttonTitle: "Try again", sender: self)
            return
        }
        
        
        /*********************************************************************
        * END ALERTS
        **********************************************************************/
        
        // Disable sign up button so that user can only send one request at a time
        signUpButton.isEnabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        // Stop showing activity indicator (spinner)
        self.checkMarkFlipped.isHidden = false
        
        self.userPhoto.isHidden = true
        self.spinner.stopAnimating()
        
        UIView.transition(with: self.checkMarkView, duration: 1, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: { () -> Void in
            
            self.checkMarkFlipped.isHidden = false
            self.checkMarkFlipped.image = self.checkMark.image
            
            }, completion: nil)
        
        
        delay(1.5)
        {
          
          self.isSignUpWithFacebook = false
          self.performSegue(withIdentifier: self.segueDestination, sender: nil)
            
        }
        
        self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
        
        // Enable the sign-up button again
        signUpButton.isEnabled = true

    }
    
  
  @IBAction func onSignUpWithFacebookButtonClicked(_ sender: AnyObject) {
    let login = FBSDKLoginManager.init()
    login.logOut()

    // Open in app instead of web browser!
    login.loginBehavior = FBSDKLoginBehavior.native


    // Request basic profile permissions just to get user ID
    login.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
      
      if (error == nil && result != nil) {

        //Get user-specific data including name, email, and ID.
        let request = FBSDKGraphRequest(graphPath: "/me?locale=en_US&fields=name,email", parameters: nil)
        request?.start { (connection, result, error) in
          if error == nil {
            print("Result is FB!!: ", result)
            let resultMap = result as! Dictionary<String, String>
            
            self.fbFullName = resultMap["name"]
            self.fbEmail = resultMap["email"]
            self.fbUID = resultMap["id"]
            let userImageURL = "https://graph.facebook.com/" + self.fbUID! + "/picture?type=large"
            
            
            downloadImageFromURL(userImageURL, completion: { (result, error) in
              if (result != nil && error == nil) {
                self.fbImage = result! as UIImage
                DispatchQueue.main.async(execute: {
                  self.isSignUpWithFacebook = true
                  self.performSegue(withIdentifier: self.segueDestination, sender: nil)
                })
              }
            })
            
            
           

            
    //        // Check our databases to see if we have a user with the same fbUID
    //        // If we have multiple users ->
    //        // If we don't have a user -> create one
    //        let dynamoDB = AWSDynamoDB.defaultDynamoDB()
    //        let scanInput = AWSDynamoDBScanInput()
    //        scanInput.tableName = "aquaint-users"
    //        scanInput.limit = 100
    //        scanInput.exclusiveStartKey = nil
    //        
    //        let UIDValue = AWSDynamoDBAttributeValue()
    //        UIDValue.S = fbUID
    //        
    //        scanInput.expressionAttributeValues = [":val" : UIDValue]
    //        scanInput.filterExpression = "fbuid = :val"
    //        
    //        dynamoDB.scan(scanInput).continueWithBlock { (resultTask) -> AnyObject? in
    //          if resultTask.result != nil && resultTask.error == nil
    //          {
    //            print("DB QUERY SUCCESS:", resultTask.result)
    //            let results = resultTask.result as! AWSDynamoDBScanOutput
    //            
    //            if results.items!.count > 1 {
    //              print("FB login attempt where more than 1 user has same FB ID")
    //              dispatch_async(dispatch_get_main_queue(), {
    //                showAlert("Sorry", message: "You already have a ", buttonTitle: "Try again", sender: self)
    //              })
    //              
    //              return nil
    //            }
    //            
    //            for result in results.items! {
    //              print("RESULT IS: ", result)
    //              
    //              let username = (result["username"]?.S)! as String
    //              
    //              setCurrentCachedUserName(username)
    //              setCachedUserFromAWS(username)
    //              
    //              dispatch_async(dispatch_get_main_queue(), {
    //                self.performSegueWithIdentifier("toMainContainerViewController", sender: nil)
    //              })
    //            }
    //          }
    //          else
    //          {
    //            print("DB QUERY FAILURE:", resultTask.error)
    //          }
    //          return nil
    //        }
            
            
            
          } else {
            print("Error getting **FB infooo", error)
            DispatchQueue.main.async(execute: {
              showAlert("Sorry", message: "There was an issue signing up with Facebook. We apologize for the inconvenience.", buttonTitle: "Try again", sender: self)
            })
          }
        }
      }
    }
  }
  
  
    // Used to pass password to next view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
        // Pass the password to next view controller so we can log user in there
        if(segue.identifier == segueDestination)
        {
            let nextViewController = segue.destination as! SignUpFetchMoreDataController
          
            nextViewController.isSignUpWithFacebook = self.isSignUpWithFacebook
            
            if self.isSignUpWithFacebook {
              nextViewController.userFullName = self.fbFullName
              nextViewController.userEmail = self.fbEmail
              nextViewController.userImage = self.fbImage
              nextViewController.fbUID = self.fbUID  
              
            } else {
            
              nextViewController.userEmail = userEmail.text
              
              // Ensure that you pass the country code as well. Default: US
              nextViewController.userPhone = "+1" + userPhone.text!
              nextViewController.userFullName = userFullName.text
            
              // Pass image only if user set an image -- or if we're signing up through facebook
              if ((self.userPhoto.currentImage != UIImage(named: "Add Photo Color")))
              {
                  nextViewController.userImage = userPhoto.currentImage!
              }
            }
        }
    }
    
    fileprivate func resetAnimations()
    {
        self.checkMark.isHidden = true
        self.checkMarkFlipped.isHidden = true
        self.userPhoto.isHidden = false
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        flipImageHorizontally(checkMarkFlippedCopy)
    }
  
    
    // Use to go back to previous VC at ease.
    @IBAction func unwindBackVC(_ segue: UIStoryboardSegue)
    {
        print("CALLED UNWIND VC")
        resetAnimations()
    }

}
