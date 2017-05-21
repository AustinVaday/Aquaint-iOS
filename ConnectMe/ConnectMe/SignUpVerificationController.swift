//
//  SignUpVerificationController.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/3/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
import AWSDynamoDB
import AWSS3
import AWSLambda

class SignUpVerificationController: ViewControllerPannable {
    
    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var buttonToFlip: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var phoneDisplayLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    var isKeyboardShown = false
    var isSignUpWithFacebook = false
    var pool : AWSCognitoIdentityUserPool!
    var fileManager: AWSUserFileManager!
    var dynamoDBObjectMapper: AWSDynamoDBObjectMapper!
    
    
    var checkMarkFlippedCopy: UIImageView!
    var userPassword: String!
    var userFullName: String!
    var userName: String!
    var userImage: UIImage!
    var userPhone: String!
    var userEmail: String!
    var verificationCodeResendCount = 0
  
    let segueDestination = "toWalkthroughContainerViewController"
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up fileManager for uploading prof pics
        fileManager = AWSUserFileManager.defaultUserFileManager()
        
        // Set up DB
        dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()

        // get the IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        resetAnimations()
        
        // Display user's phone number-- "We sent a verification code to ..."
        phoneDisplayLabel.text = userPhone
        
        // Set up pan gesture recognizer for when the user wants to swipe left/right
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .Left
        view.addGestureRecognizer(edgePan)

    }
  
    override func viewDidAppear(animated: Bool) {
      awsMobileAnalyticsRecordPageVisitEventTrigger("SignUpVerificationController", forKey: "page_name")
    }
    
    /*=======================================================
     * BEGIN : Keyboard/Button Animations
     =======================================================*/
    // Add and Remove NSNotifications!
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        registerForKeyboardNotifications()
      
        // Bypass this page if so 
        if (isSignUpWithFacebook) {
          
        }
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
    func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == .Ended
        {
            print("Screen swiped!")
            dismissViewControllerAnimated(true, completion: nil)
        }
        
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
        self.onVerifyButtonClicked(signUpButton.self)
    }
  
  
    @IBAction func onResentVerificationCodeButtonClicked(sender: AnyObject) {
      
      // Prevent abuse
      if (self.verificationCodeResendCount < 5)
      {
        pool.getUser(userName).resendConfirmationCode()
        self.verificationCodeResendCount = self.verificationCodeResendCount + 1
      }
      else {
        showAlert("Sorry", message: "You've sent too many codes. Please try again later.", buttonTitle: "Ok", sender: self)
      }
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
        
        pool.getUser(userName).confirmSignUp(verificationString).continueWithBlock { (resultTask) -> AnyObject? in
            
            // If success code
            if resultTask.error == nil
            {
                print("CODE SUCCESSFUL")
                
                // LOG IN
                // Attempt to log user in
                self.pool.getUser(self.userName).getSession(self.userName, password: self.userPassword, validationData: nil, scopes: nil).continueWithBlock({ (sessionResultTask) -> AnyObject? in
                    
                    // If success login
                    if sessionResultTask.error == nil
                    {
                        
                        // Print credentials provider
                        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
                        
                        
                        // Update new identity ID
                        credentialsProvider.getIdentityId().continueWithBlock({ (task) -> AnyObject? in
                            print("^^^USER LOGGGGGED IN with credentials:", task.result)
                            
                            setCurrentCachedUserName(self.userName)
                            setCurrentCachedFullName(self.userFullName)
                            setCurrentCachedUserEmail(self.userEmail)
                            setCurrentCachedUserPhone(self.userPhone)
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
                                transferRequest.key = "public/" + self.userName
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
//                            parameters = ["action":"follow", "target": "aquaint", "me": self.userName]
//                            lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
//                                if resultTask.error != nil
//                                {
//                                    print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
//                                }
//                                else if resultTask.exception != nil
//                                {
//                                    print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
//                                    
//                                }
//                                else if resultTask.result != nil
//                                {
//                                    print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
//                                    
//                                }
//                                else
//                                {
//                                    print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
//                                    
//                                }
//                                
//                                return nil
//                                
//                            }
                          
                          
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
                            dynamoDBUser.username = self.userName
                            
                            // No account data to store yet.
//                            let accountData = NSMutableDictionary()
//                            accountData.setValue(["austinvaday", "austinswag"], forKey: "facebook")
//                            accountData.setValue(["austinvaday","avtheman"], forKey: "instagram")
//                            dynamoDBUser.accounts = accountData
                            
                            self.dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
                                
                                // If successful save
                                if (resultTask.error == nil)
                                {
                                    print ("DYNAMODB SUCCESS: ", resultTask.result)
                                    
//                                    setCurrentCachedUserProfiles(accountData)
                                    
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
                                            
                                            self.performSegueWithIdentifier(self.segueDestination, sender: nil)
                                            
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
                            
                            
                            return nil
                        })
                        
                        
                    }
                    else // If fail login
                    {
                        // Perform update on UI on main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            self.spinner.stopAnimating()
                            
                            //showAlert("Error", message: "Verification code successful, but could not log you in at this time. Please try again.", buttonTitle: "Try again", sender: self)
                          
                            let errorMessage = "Verification code successful, but could not log you in at this time. Please try again. Error: " + sessionResultTask.error.debugDescription
                            showAlert("Error", message: errorMessage, buttonTitle: "Try again", sender: self)
                        })
                    }
                    
                    return nil
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

    
    private func resetAnimations()
    {
        // Set up animation
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        self.buttonToFlip.hidden = false
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        flipImageHorizontally(checkMarkFlippedCopy)
        
    }
}
