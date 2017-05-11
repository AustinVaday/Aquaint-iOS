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
import AWSLambda

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
  
    var isSignUpWithFacebook = false
    var userPhone : String!
    var userEmail : String!
    var userFullName : String!
    var userImage: UIImage!
    var fbUID : String!
    var attemptedUserName = String()
    let segueDestination = "toSignUpVerificationController"
    let signUpWithFBSegueDestination = "toWalkthroughContainerViewController"
    
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
  
    override func viewDidAppear(animated: Bool) {
      awsMobileAnalyticsRecordPageVisitEventTrigger("SignUpFetchMoreDataController", forKey: "page_name")
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
                self.buttonBottomConstraint.constant = -keyboardSize.height
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

    @IBAction func onFinishButtonClicked(sender: UIButton) {
        // Disable button so that user cannot click on it twice (this is how errors happen)
        self.nextButton.enabled = false
        
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
      
        if isSignUpWithFacebook {
          completeUserRegistration()
          return
        }
      
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
                        // Disable button so that user cannot click on it twice (this is how errors happen)
                        self.nextButton.enabled = true

                    }

                    self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                  
                })


            }
            else // If sign up failed
            {
                // If user attempted to use the username before, let them proceed
                if (!self.attemptedUserName.isEmpty && self.attemptedUserName == self.userName.text)
                {
                    //Proceed only if user is not confirmed
                    if (self.pool.getUser(self.attemptedUserName).confirmedStatus.rawValue == 0)
                    {
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
                                // Disable button so that user cannot click on it twice (this is how errors happen)
                                self.nextButton.enabled = true

                            }
                          
                            
                            self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                        })

                    
                    }
                    else
                    {
                        // we failed.. do something like what we do below
                        print("USER PRE CONFIRMED IN SIGN UP")
                    }
                }
                else
                {

                
                
                    // Perform update on UI on main thread
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in

                        // Stop showing activity indicator (spinner)
                        self.spinner.stopAnimating()
                        
                        // Re-enable button
                        self.nextButton.enabled = true
                        
                        self.attemptedUserName = String()

                        // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the button before it is disabled. This if statement prevents the display of multiple alerts).
                        if (self.presentedViewController == nil)
                        {
                            let error = (resultTask.error?.userInfo["__type"])! as! String
                            
                            if (error == "UsernameExistsException")
                            {
                                showAlert("Error signing up.", message: "Sorry, your username is already taken. Please try again!", buttonTitle: "Try again", sender: self)
                            }
                            else
                            {
                                showAlert("Error signing up", message: (resultTask.error?.userInfo["message"])! as! String, buttonTitle: "Try again", sender: self)

                            }
                            
                        }
                    })
                }
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
            
            // IMPORTANT: This will help us determine whether we should allow user to proceed to verification page or not. BE VERY CAREFUL.
            // Problem: If user signs up, goes to verification page, then hits the "back button" -- they cannot use the username they tried to sign up with before -- it will say that it is taken. So we need to know when to let them try again. This will help us. See "unwindBackSignUpInfoVC" for more details
            // Solution: This function will ONLY be called if username does not exist. Therefore it is safe to do this.
            attemptedUserName = (self.userName.text?.lowercaseString)!
            
            
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
  
    private func completeUserRegistration() {
        // Create AWS user and upload
      let userNameString:String = userName.text!
      let userPasswordString:String = userPassword.text!
      let lowerCaseUserNameString = userNameString.lowercaseString
      
      let email  = AWSCognitoIdentityUserAttributeType()
      email.name = "email"
      email.value = userEmail
      
      // Remember, AWSTask is ASYNCHRONOUS.
      pool.signUp(lowerCaseUserNameString, password: userPasswordString, userAttributes: [email], validationData: nil).continueWithBlock { (resultTask) -> AnyObject? in
        
        
        // If sign up performed successfully.
        if (resultTask.error == nil)
        {
          
          setCurrentCachedUserName(lowerCaseUserNameString)
          setCurrentCachedFullName(self.userFullName)
          setCurrentCachedUserEmail(self.userEmail)
          setCurrentCachedPrivacyStatus("public")
          
          /*********************
           *  UPLOAD PHOTO TO S3
           **********************/
          // If user did add a photo, upload to S3
          if (self.userImage != nil)
          {
            // Fetch user photo
            let userPhoto = self.userImage
            
            // Resize photo for cheaper storage
            let targetSize = CGSize(width: 150, height: 150)
            let newImage = RBResizeImage(userPhoto, targetSize: targetSize)
            
            // Create temp file location for image (hint: may be useful later if we have users taking photos themselves and not wanting to store it)
            let imageFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingString("temp"))
            
            // Force PNG format
            let data = UIImagePNGRepresentation(newImage)
            try! data?.writeToURL(imageFileURL, options: NSDataWritingOptions.AtomicWrite)
            
            // AWS TRANSFER REQUEST
            let transferRequest = AWSS3TransferManagerUploadRequest()
            transferRequest.bucket = "aquaint-userfiles-mobilehub-146546989"
            transferRequest.key = "public/" + lowerCaseUserNameString
            transferRequest.body = imageFileURL
            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
            
            transferManager.upload(transferRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock:
              { (resultTask) -> AnyObject? in
                
                // if sucessful file transfer
                if resultTask.error == nil
                {
                  print("SUCCESS FILE UPLOAD")
                  // Also cache it.. only if file successfully uploadsd
                  setCurrentCachedUserImage(self.userImage)
                  
                }
                else // If fail file transfer
                {
                  
                  print("ERROR FILE UPLOAD: ", resultTask.error)
                }
                
                return nil
            })
            
          }
          /*************************************
           *  UPLOAD USER DATA TO RDS via LAMBDA
           *************************************/
          // Store username and user realname
          let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
          var parameters = ["action":"adduser", "target": self.userName, "realname": self.userFullName]
          lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error != nil
            {
              print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
            }
            else if resultTask.exception != nil
            {
              print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
              
            }
            else if resultTask.result != nil
            {
              print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
              
            }
            else
            {
              print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
              
            }
            
            return nil
            
          }
          
          
          // Have user automatically follow and be followed by Aquaint Team!
          parameters = ["action":"follow", "target": self.userName, "me": "aquaint"]
          lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error != nil
            {
              print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
            }
            else if resultTask.exception != nil
            {
              print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
              
            }
            else if resultTask.result != nil
            {
              print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
              
            }
            else
            {
              print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
              
            }
            
            return nil
            
          }
          
          // Generate scan code for user
          parameters = ["action":"createScanCodeForUser", "target": self.userName]
          lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error != nil {
              print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
            }
            else if resultTask.exception != nil {
              print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
            }
            else if resultTask.result != nil {
              print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
            }
            else {
              print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
            }
            return nil
          }
          
          /********************************
           *  UPLOAD USER DATA TO DYNAMODB
           ********************************/
          // Upload user DATA to DynamoDB
          let dynamoDBUser = User()
          
          dynamoDBUser.realname = self.userFullName
          // dynamoDBUser.timestamp = getTimestampAsInt()
          // dynamoDBUser.userId = task.result as! String
          dynamoDBUser.username = lowerCaseUserNameString
          
          
          self.dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
            
            // If successful save
            if (resultTask.error == nil)
            {
              print ("DYNAMODB SUCCESS: ", resultTask.result)
              
              // Perform update on UI on main thread
              dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // Stop showing activity indicator (spinner)
                self.spinner.stopAnimating()
                self.checkMarkFlipped.hidden = false
                self.buttonToFlip.hidden = true
                
                UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
                  
                  self.checkMarkFlipped.hidden = false
                  self.checkMarkFlipped.image = self.checkMark.image
                  
                  }, completion: nil)
                
                
                delay(1.5)
                {
                  
                  self.performSegueWithIdentifier(self.signUpWithFBSegueDestination, sender: nil)
                  
                }
                
                self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
              })
            }
            
            if (resultTask.error != nil)
            {
              print ("DYNAMODB ERROR: ", resultTask.error)
            }
            
            if (resultTask.exception != nil)
            {
              print ("DYNAMODB EXCEPTION: ", resultTask.exception)
            }
            
            return nil
          })
        
      
        }
        else // If sign up failed
        {
          // If user attempted to use the username before, let them proceed
          if (!self.attemptedUserName.isEmpty && self.attemptedUserName == self.userName.text)
          {
            //Proceed only if user is not confirmed
            if (self.pool.getUser(self.attemptedUserName).confirmedStatus.rawValue == 0)
            {
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
                  // Disable button so that user cannot click on it twice (this is how errors happen)
                  self.nextButton.enabled = true
                  
                }
                
                
                self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
              })
              
              
            }
            else
            {
              // we failed.. do something like what we do below
              print("USER PRE CONFIRMED IN SIGN UP")
            }
          }
          else
          {
            
            
            
            // Perform update on UI on main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
              
              // Stop showing activity indicator (spinner)
              self.spinner.stopAnimating()
              
              // Re-enable button
              self.nextButton.enabled = true
              
              self.attemptedUserName = String()
              
              // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the button before it is disabled. This if statement prevents the display of multiple alerts).
              if (self.presentedViewController == nil)
              {
                let error = (resultTask.error?.userInfo["__type"])! as! String
                
                if (error == "UsernameExistsException")
                {
                  showAlert("Error signing up.", message: "Sorry, your username is already taken. Please try again!", buttonTitle: "Try again", sender: self)
                }
                else
                {
                  showAlert("Error signing up", message: (resultTask.error?.userInfo["message"])! as! String, buttonTitle: "Try again", sender: self)
                  
                }
                
              }
            })
          }
        }
        
        return nil
      }

    }
  
    // Use to go back to previous VC at ease.
    @IBAction func unwindBackSignUpInfoVC(segue: UIStoryboardSegue)
    {
        print("CALLED UNWIND VC")
      
        resetAnimations()
    }

  
}
