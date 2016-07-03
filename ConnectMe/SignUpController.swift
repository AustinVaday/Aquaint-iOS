//
//  SignUpController.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/13/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Firebase
import AWSMobileHubHelper

class SignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // UI variable data types
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userPhoto: UIButton!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var formView: UIView!
    
    @IBOutlet weak var facebookButton: UIButton!
//    @IBOutlet weak var orSignInWithLabel: UIView!


    
    var checkMarkFlippedCopy: UIImageView!
    var firebaseRootRef: FIRDatabaseReference!
    var prevEmailString: String!                // Used to prevent user from spamming requests
    var imagePicker:UIImagePickerController!    // Used for selecting image from user's device

    let segueDestination = "toMainContainerViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the button round!
        userPhoto.clipsToBounds = true
        userPhoto.layer.cornerRadius = userPhoto.frame.size.width / 2
        userPhoto.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        userPhoto.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
        
        // Create a reference to firebase location
        firebaseRootRef = FIRDatabase.database().reference()
        
        // Log out of of firebase if already logged in
        try! FIRAuth.auth()!.signOut()
        
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
//        userObject  = User()
    }
    
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
    func handleLoginWithSignInProvide(signInProvider: AWSSignInProvider) {
        AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(signInProvider, completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
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
    

    // Ensure username is proper
    @IBAction func nameEditingDidChange(sender: UITextField) {
        // Prevent upper-case characters
        // Prevent spaces
        // Prevent special characters
        
        
        var inputString = userName.text!
        
//        // Make the input field lowercase while we're at it.
//        userName.text = inputString.lowercaseString
        
        if (!inputString.isEmpty)
        {
            // Get range of all characters in the string that are not digits
            let notAcceptableRange = inputString.rangeOfCharacterFromSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
            
            // If range of characters in given string has any non-digit characters
            // Then we must remove them
            if (notAcceptableRange != nil)
            {
                // Remove all non-digits
                inputString.removeRange(notAcceptableRange!)
                
                // Enforce this on user, set text field to no digits (and make it lowercase too while we're at it!
                userName.text = inputString
            }
        }
        


    }
    
    
    // EditingDidEnd functionality will be used for error checking user input
    @IBAction func nameEditingDidEnd(sender: UITextField) {
        
//        // Store the text inside the field. Make sure it's unwrapped by using a '!'.
//        let userNameString:String =  userName.text!
//        
//        print(userNameString)
//        
//        // Check if text field is empty
//        if userNameString.isEmpty
//        {
////            userNameLabel.textColor = UIColor.redColor()
//            print("Empy username string")
//        }
//        else
//        {
//            print("PROPER username string")
//
////            userNameLabel.textColor = UIColor.whiteColor()
//        }
        
        // Call this method one last time to ensure username is proper
        self.nameEditingDidChange(sender)

    }
    
    @IBAction func emailEditingDidEnd(sender: AnyObject) {
        
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
    
    @IBAction func passwordEditingDidEnd(sender: AnyObject) {
        
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
    
    // When user clicks "Next" on keyboard
    @IBAction func nameEditingDidEndOnExit(sender: UITextField) {
        // Give control to next field
        userEmail.becomeFirstResponder()
    }
    
    // When user clicks "Next" on keyboard
    @IBAction func emailEditingDidEndOnExit(sender: UITextField) {
        // Give control to next field
        userPassword.becomeFirstResponder()
    }
    
    // When user clicks "Go" on keyboard
    @IBAction func passwordEditingDidEndOnExit(sender: UITextField) {
        // Mimic the "Sign Up" button being pressed
        self.signUpButtonClicked(signUpButton.self)
    }
   
    // Actions to perform when "Sign Up" is clicked
    @IBAction func signUpButtonClicked(sender: AnyObject) {
        
        let userNameString:String = userName.text!
        let userEmailString:String = userEmail.text!
        let userPasswordString:String =  userPassword.text!
        var userNameExists = false
        
        /*********************************************************************
        * ALERTS - send alert and leave if user enters in improper input
        **********************************************************************/
        if (userNameString.isEmpty)
        {
            showAlert("Error signing up", message: "Please enter in a username!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyUserNameLength(userNameString))
        {
            showAlert("Improper username format", message: "Please create a username between 6 and 20 characters long!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyUserNameFormat(userNameString))
        {
            showAlert("Improper username format", message: "Please use a proper username format: no spaces and no special characters!", buttonTitle: "Try again", sender: self)
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
        
        if (userPasswordString.isEmpty)
        {
            showAlert("Error signing up", message: "Please enter in a password!", buttonTitle: "Try again", sender: self)
            return
        }
        
        // Firebase restriction: Password must be at least 6 characters... (or it will throw an error)
        if (userPasswordString.characters.count < 6)
        {
            showAlert("Error signing up", message: "Please enter in a password that is more than 6 characters!", buttonTitle: "Try again", sender: self)
            return
        }
        
        // Do not send request to server if user didn't change email input
        if (userEmailString == self.prevEmailString)
        {
            print("I will not let you take advantage of me.")
            showAlert("Error signing up", message: "The email you entered already exists! Please enter in a different email address.", buttonTitle: "Try again", sender: self)

            return
        }
        
        /*********************************************************************
        * END ALERTS
        **********************************************************************/
        
        // Disable sign up button so that user can only send one request at a time
        signUpButton.enabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        // Perform long-running operation on background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            self.spinner.startAnimating()
            
                
            })
        
            //Check is username already exists or not....
            let firebaseUserRef = firebaseRootRef.child("Users/")
        
            //Important!! Make userNameString all lowercase from now on (for storing unique keys in the database)
            let lowerCaseUserNameString = userNameString.lowercaseString
        
            // This is a check if username already exists or not.
            firebaseUserRef.observeSingleEventOfType(FIRDataEventType.Value, andPreviousSiblingKeyWithBlock: { (snapshot, str) -> Void in
            
                if snapshot.hasChild(lowerCaseUserNameString)
                {
                    userNameExists = true
                    print("USERNAME IS TAKEN")
                }
                else
                {
                    userNameExists = false
                    print("USERNAME IS FREE")
                }
                
            
            if (userNameExists)
            {
                self.spinner.stopAnimating()
                showAlert("Sorry", message: "The username you entered already exists! Please try a different username.", buttonTitle: "Try again", sender: self)
            }
            else
            {
                FIRAuth.auth()?.createUserWithEmail(userEmailString, password: userPasswordString, completion: { (user, error1) in

                    // If success sign up
                    if (error1 == nil)
                    {
                        // Log user in
                        FIRAuth.auth()?.signInWithEmail(userEmailString, password: userPasswordString, completion: { (user, error) in
                                // If success log in
                                if (error == nil)
                                {
                                    let userId = user!.uid
                                    
                                    let currentTime = getTimestampAsInt()
                                    
                                    var base64String : String!
                                    // If user did add a photo
                                    if ((self.userPhoto.currentImage != UIImage(named: "Add Photo Color")))
                                    {
                                        print ("B64 YES")
                                        let userPhoto = self.userPhoto.currentImage!
                                        
                                        let targetSize = CGSize(width: 120, height: 120)
                                        
                                        // Only resize photo if necessary
//                                        if ()
//                                        {
//                                            
//                                            
//                                        }
                                        
                                        let newImage = RBResizeImage(userPhoto, targetSize: targetSize)
                                        
                                        
                                        // Convert photo to base64
                                        base64String = convertImageToBase64(newImage)
                                    }
                                    
                                    let userInfo   = ["fullName" : "", "dateCreated": currentTime]
                                    let linkedSocialMediaAccounts = ["twitter": "austinvaday", "facebook": "austinvaday", "instagram": "avtheman"]
                                    let connections = ["aquaint" : currentTime]
                                    
                                    
                                    print("User signed up and logged in: ", lowerCaseUserNameString)
                                    

                                    
                                    // Store necessary information in JSON tree
                                    self.firebaseRootRef.child("Users/" + lowerCaseUserNameString).setValue(userInfo)
                                    
                                    // If user did add a photo, store it on database
                                    if ((self.userPhoto.currentImage != UIImage(named: "Add Photo Color")))
                                    {
                                        self.firebaseRootRef.child("UserImages/" + lowerCaseUserNameString + "/profileImage").setValue(base64String)
                                    }
                                    
                                    self.firebaseRootRef.child("LinkedSocialMediaAccounts/" + lowerCaseUserNameString).setValue(linkedSocialMediaAccounts)
                                    self.firebaseRootRef.child("Connections/" + lowerCaseUserNameString).setValue(connections)
                                    self.firebaseRootRef.child("UserIdToUserName/" + userId).setValue(lowerCaseUserNameString)
                                    
                                    
                                    // Cache the user name for future use!
                                    let defaults = NSUserDefaults.standardUserDefaults()
                                    defaults.setObject(lowerCaseUserNameString, forKey: "username")
                                    
                                    // Perform update on UI on main thread
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        
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
                                        
                                    })
                                    

                                    
                                }
                                else // If not success log in
                                {
                                    // Perform update on UI on main thread
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        
                                        // Stop showing activity indicator (spinner)
                                        self.spinner.stopAnimating()
                                        
                                        
                                        // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the button before it is disabled. This if statement prevents the display of multiple alerts).
                                        if (self.presentedViewController == nil)
                                        {
                                            
                                            showAlert("Error logging in.", message: "Sorry, we've signed you up already but was unable to log you in! Please try again.", buttonTitle: "Try again", sender: self)
                                        }
                                        
                                        print("Signup-login Error")
                                        
                                        self.prevEmailString = userEmailString
                                        
                                    })
                                    
                                }
                                
                        })

                    }
                    else // If user couldn't sign up
                    {
                        print("ERROR IS: ")
                        print(error1.debugDescription) // LOG THIS
                        // Perform update on UI on main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.spinner.stopAnimating()
                            self.prevEmailString = userEmailString

                            print("COULDN'T SIGN UP")
                            
//                            showAlert("Sorry", message: "The email you entered already exists! Please try a different email address.", buttonTitle: "Try again", sender: self)
                            showAlert("Sorry", message: "There was an error with your request. Please try again!", buttonTitle: "Try again", sender: self)
                        })
                    }
                    
                })
            }
            
            
        })
        
        
        // Enable the log-in button again
        signUpButton.enabled = true

    }
    
}
