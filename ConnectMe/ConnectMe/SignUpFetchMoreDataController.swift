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

class SignUpFetchMoreDataController: UIViewController {
    

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
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    var isKeyboardShown = false
    var pool : AWSCognitoIdentityUserPool!
    var fileManager: AWSUserFileManager!
    var uploadRequest: AWSS3TransferManagerUploadRequest!

    var dynamoDBObjectMapper : AWSDynamoDBObjectMapper!
    
    var checkMarkFlippedCopy: UIImageView!
    
    var userPhone : String!
    var userEmail : String!
    var userFullName : String!
    var userImage: UIImage!
    let segueDestination = "toSignUpVerificationController"

    
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
    
    // When user clicks "next" on keyboard
    @IBAction func onUserNameEditingDidEndOnExit(sender: AnyObject) {
        userPassword.becomeFirstResponder()
    }
    
    // When user clicks "Go" on keyboard
    @IBAction func onPasswordEditingDidEndOnExit(sender: AnyObject) {
        // Mimic the "Sign Up" button being pressed
        self.onFinishButtonClicked(nextButton.self)
        
    }

    @IBAction func onFinishButtonClicked(sender: UIButton) {
    
        let userNameString:String = userName.text!
        let userPasswordString:String = userPassword.text!
        
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
        
        if (userPasswordString.isEmpty)
        {
            showAlert("Error signing up", message: "Please enter in a password!", buttonTitle: "Try again", sender: self)
            return
        }
        
        // API restriction: Password must be at least 6 characters... (or it will throw an error)
        if (userPasswordString.characters.count < 6)
        {
            showAlert("Error signing up", message: "Please enter in a password that is more than 6 characters!", buttonTitle: "Try again", sender: self)
            return
        }
        
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
//        let currentUser = getCurrentUser()
//        
//        print("Current user to sign up: ", currentUser)
//        print("And password is: ", userPassword)
        
        
        //Important!! Make userNameString all lowercase from now on (for storing unique keys in the database)
        // What if userNameString is nil?
        let lowerCaseUserNameString = userNameString.lowercaseString

        let email  = AWSCognitoIdentityUserAttributeType()
            email.name = "email"
            email.value = userEmail
        
        let phone = AWSCognitoIdentityUserAttributeType()
            phone.name = "phone_number"
            phone.value = userPhone


        // Remember, AWSTask is ASYNCHRONOUS.
        pool.signUp(lowerCaseUserNameString, password: userPasswordString, userAttributes: [email, phone], validationData: nil).continueWithBlock { (resultTask) -> AnyObject? in

            // If sign up performed successfully.
            if (resultTask.error == nil)
            {
                print("Successful signup")

                // Cache the user name for future use!
//                let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
//
//                // Fetch new identity ID
//                credentialsProvider.getIdentityId().continueWithBlock({ (task) -> AnyObject? in
//                    print("^^^USER SIGNED UP:", task.result)
//
//                    // Set cached current user
//                    setCurrentUserNameAndId(userNameString, userId: task.result as! String)
//
//                    return nil
//                })


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


                    delay(1.5)
                    {

                        self.performSegueWithIdentifier(self.segueDestination, sender: nil)

                    }

                    self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image

                })


            }
            else // If sign up failed
            {
                print("Fail signup")
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in

                    // Stop showing activity indicator (spinner)
                    self.spinner.stopAnimating()

                    // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the button before it is disabled. This if statement prevents the display of multiple alerts).
                    if (self.presentedViewController == nil)
                    {

                        showAlert("Error signing up.", message: "Sorry, your username is already taken. Please try again!", buttonTitle: "Try again", sender: self)
                    }
                    
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
            let nextViewController = segue.destinationViewController as! SignUpVerificationController

            nextViewController.userFullName = self.userFullName
            nextViewController.userPassword = self.userPassword.text
            nextViewController.userName = self.userName.text?.lowercaseString // IMPORTANT that it's lowercase, or else future userpool verification will fail
            nextViewController.userImage = self.userImage
            nextViewController.userPhone = self.userPhone
            nextViewController.userEmail = self.userEmail
            // Need phone to display it on next screen
            // Don't need to pass email.
            // Remember, email & phone stored on AWS User Pools, not DynamoDB users.
            
        
        }
        
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
    
    // Use to go back to previous VC at ease.
    @IBAction func unwindBackSignUpInfoVC(segue: UIStoryboardSegue)
    {
        print("CALLED UNWIND VC")
        
        resetAnimations()
    }

    
}
