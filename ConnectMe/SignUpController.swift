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

class SignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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

    var isKeyboardShown = false
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
        
        // Get the IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        // Set up fileManager for uploading prof pics
        fileManager = AWSUserFileManager.defaultUserFileManager()
        
//        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e", identityProviderManager:pool)
//        didSignInObserver =  NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignInNotification,
//             object: AWSIdentityManager.defaultIdentityManager(),
//             queue: NSOperationQueue.mainQueue(),
//             usingBlock: {(note: NSNotification) -> Void in
//                
//                // perform successful login actions here
//                
//                print("SUCCESSFUL LOG IN", note)
//                print(AWSIdentityManager.defaultIdentityManager().userName)
//                print(AWSIdentityManager.defaultIdentityManager().imageURL)
//                print(AWSIdentityManager.defaultIdentityManager().identityId)
//        })
//        AWSIdentityManager.defaultIdentityManager().logoutWithCompletionHandler { (obj, error) in
//            print("LOGGING USER OUT!")
//        }
        
        // Make the button round!
        userPhoto.clipsToBounds = true
        userPhoto.layer.cornerRadius = userPhoto.frame.size.width / 2
        userPhoto.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        userPhoto.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
        
        
        // Set up animation
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        self.userPhoto.hidden = false
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        flipImageHorizontally(checkMarkFlippedCopy)
        
        // Empty previous email string
        prevEmailString = ""
    }
    
    override func viewDidAppear(animated: Bool) {
        //TODO: INVESTIGATE UIImagePickerController class
        // The following initialization, for some reason, takes longer than usual. Doing this AFTER the view appears so that there's no obvious delay in any transitions.
        imagePicker = UIImagePickerController()
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleLoginWithSignInProvider(sender: UIButton) {
        
        AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance(), completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                dispatch_async(dispatch_get_main_queue(),{
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
            print("result = \(result), error = \(error)")
        })

    }
    
    // Functionality for adding in a user specific photograph
    @IBAction func addPhotoButtonClicked(sender: UIButton) {
        
        
        // Present the Saved Photo Album to user only if it is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum)
        {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    // When user finishes picking an image, this function is called and we set the user's image
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [NSObject : AnyObject]?) {
        
        // Close the image picker view when user is finished with it
        self.dismissViewControllerAnimated(true, completion: nil)
    
        // Set the button's new image
        userPhoto.setImage(image, forState: UIControlState.Normal)
        
        // Store the image into the userObject
//        userObject.image = image
        
    }
    
    // Ensure email is proper
    @IBAction func emailEditingDidEnd(sender: UITextField) {
        
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
    @IBAction func phoneEditingDidEnd(sender: UITextField) {
        // Do this later if you want dynamic checking
    }
    
    // Ensure full name is proper
    @IBAction func fullNameEditingDidEnd(sender: UITextField) {
        // Do this later if you want dynamic checking

    }
    
    // Actively edit phone number
    @IBAction func onPhoneEditingDidChange(sender: UITextField) {
        
        let phoneString = userPhone.text
        
        
        
        
    }
    
    
    // When user clicks "Next" on keyboard
    @IBAction func emailEditingDidEndOnExit(sender: UITextField) {
        // Give control to next field
        userPhone.becomeFirstResponder()
    }
    
    // When user clicks "Next" on keyboard
    @IBAction func phoneEditingDidEndOnExit(sender: UITextField) {
        // Give control to next field
        userFullName.becomeFirstResponder()
    }
    
    @IBAction func fullNameEditingDidEndOnExit(sender: UITextField) {
        // Mimic the "Sign Up" button being pressed
        self.signUpButtonClicked(signUpButton.self)
    }
    
     // Actions to perform when "Next" (Sign up) button is clicked
    @IBAction func signUpButtonClicked(sender: AnyObject) {
        
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
        signUpButton.enabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        // Stop showing activity indicator (spinner)
        self.checkMarkFlipped.hidden = false
        
        self.userPhoto.hidden = true
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
        
        // Enable the sign-up button again
        signUpButton.enabled = true

    }
    
    
    // Used to pass password to next view controller
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Pass the password to next view controller so we can log user in there
        if(segue.identifier == segueDestination)
        {
            let nextViewController = segue.destinationViewController as! SignUpFetchMoreDataController
            
            nextViewController.userEmail = userEmail.text
            
            // Ensure that you pass the country code as well. Default: US
            nextViewController.userPhone = "+1" + userPhone.text!
            nextViewController.userFullName = userFullName.text
            
            // Pass image only if user set an image
            if ((self.userPhoto.currentImage != UIImage(named: "Add Photo Color")))
            {
                nextViewController.userImage = userPhoto.currentImage!
            }
        }
    }
    
    // Use to go back to previous VC at ease.
    @IBAction func unwindBackVC(segue: UIStoryboardSegue)
    {
        print("CALLED UNWIND VC")
    }

}
