//
//  MenuController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import AWSCognitoIdentityProvider
import AWSDynamoDB
import AWSS3
import AWSLambda
import SCLAlertView
import FBSDKLoginKit
import FBSDKCoreKit

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, AddSocialMediaProfileDelegate, SocialMediaCollectionDeletionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    enum MenuData: Int {
        case LINKED_PROFILES
        case MY_INFORMATION
        case SOCIAL_ACTIONS
        case NOTIFICATION_SETTINGS
        case PRIVACY_SETTINGS
        case ACTIONS
    }
    
    enum MyInformationData: Int {
        case FULL_NAME
        case EMAIL
        case PHONE
    }
    
    struct SectionTitleAndCountPair
    {
        var sectionTitle : String!
        var sectionCount : Int!
    }
    
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var realNameTextFieldLabel: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var numFollowersLabel: UILabel!
    @IBOutlet weak var numFollowsLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    var currentUserName : String!
    var currentRealName : String!
    var currentUserAccounts : NSMutableDictionary!
    var oldUserAccounts : NSMutableDictionary!
    var newUserAccountsForNewsfeed : NSMutableDictionary! // Used so that we can add new accounts to newsfeed
    var currentUserImage: UIImage!
    var currentUserEmail : String!
    var currentUserPhone : String!
    var editedRealName : String!
    var editedUserEmail : String!
    var editedUserPhone : String!
    
    var isKeyboardShown = false
    var enableEditing = false // Whether or not to enable editing of text fields.
    var hasDeletedProfiles = false
    var buttonViewOriginalFrame : CGRect!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var keyValSocialMediaPairList : Array<KeyValSocialMediaPair>!
    var tableViewSectionsList : Array<SectionTitleAndCountPair>!
    var refreshControl : UIRefreshControl!

    // AWS credentials provider
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
    
    let footerHeight = CGFloat(65)
    let defaultTableViewCellHeight = CGFloat(60)
    let defaultImage = UIImage(imageLiteral: "Person Icon Black")

    override func viewDidLoad() {

        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Disable editing by default
        enableEditing = false
        hasDeletedProfiles = false
        
        // Ensure that the button view is always visible -- in front of the table view
        buttonView.layer.zPosition = 1
        
        // Prevents crash when user attempts to add profiles -- then log out immediately (logOut() called before viewWillDisappear)
        currentUserName = getCurrentCachedUser()
        
        // Set up the data for the table views section. Note: Dictionary does not work for this list as we need a sense of ordering.   
        tableViewSectionsList = Array<SectionTitleAndCountPair>()
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Linked Profiles", sectionCount: 1))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "My Information", sectionCount: 3))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Social Actions", sectionCount: 1))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Notification Settings", sectionCount: 1))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Privacy Settings", sectionCount: 2))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Account Actions", sectionCount: 2))
        
        
        // Call this function to generate all AWS data for this page!
        generateData()

        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()
        
        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(MenuController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        settingsTableView.addSubview(refreshControl)
    }
    
    /*=======================================================
     * BEGIN : Keyboard/Button Animations
     =======================================================*/
    
    // Add and Remove NSNotifications!
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        registerForKeyboardNotifications()
        
        // Set up datastructure for newsfeed.. If this is not reset
        // in viewWillAppear, then we'll keep uploading the same info to dynamo
        newUserAccountsForNewsfeed = NSMutableDictionary()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        deregisterForKeyboardNotifications()
        
        // When the view disappears, upload action data to Dynamo (used for the newsfeed)
        print ("You will be uploading this data to dynamo: ", self.newUserAccountsForNewsfeed)
        
        if self.newUserAccountsForNewsfeed.count != 0
        {
            // Here's what we'll do: When the user leaves this page, we will take the recent additions (100 max)
            // and store them in dynamo. This information will be used for the newsfeed.
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            // Get dynamo mapper if it exists
            dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: currentUserName, rangeKey: nil).continueWithBlock({ (resultTask) -> AnyObject? in
                
                var newsfeedObjectMapper : NewsfeedEventListObjectModel!
                
                // If successfull find, use that data
                if (resultTask.error == nil && resultTask.exception == nil && resultTask.result != nil)
                {
                    newsfeedObjectMapper = resultTask.result as! NewsfeedEventListObjectModel
                }
                else // Else, use new mapper class
                {
                    newsfeedObjectMapper = NewsfeedEventListObjectModel()
                }
                
                // Store key
                newsfeedObjectMapper.username = self.currentUserName
                
                // Upload to Dynamo
                let newKeyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(self.newUserAccountsForNewsfeed)
                
                // Add an event for extracting first 10 profile adds only
                let numProfilesLimit = 10
                var index = 0
                
            
                print ("YOLO24: ", newKeyValSocialMediaPairList)
                for pair in newKeyValSocialMediaPairList
                {
                    // Prevent too many adds at once
                    index = index + 1
                    if index >= numProfilesLimit
                    {
                        print("LEAVING FOR STATEMENT")
                        // Exit loop
                        break
                    }
                    
                    let timestamp = getTimestampAsInt()
                    let othersArray = [pair.socialMediaType, pair.socialMediaUserName] as NSArray
                    let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newprofile", "other": othersArray, "time" : timestamp])
                    newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
                }
                
                dynamoDBObjectMapper.save(newsfeedObjectMapper).continueWithSuccessBlock { (resultTask) -> AnyObject? in
                    print("DynamoObjectMapper sucessful save for newsfeedObject with new social media profile")
                    
                    return nil
                }

                
                
                return nil
            })

        }
        
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
            
            self.buttonBottomConstraint.constant = keyboardSize.height - self.footerHeight
            self.view.layoutIfNeeded()
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
  
    @IBAction func onAddSocialMediaProfileButtonClicked(sender: AnyObject) {
        
        // Do this so we don't have any miscrepencies when adding profiles from edit mode
        if enableEditing
        {
           // Mimic a cancellation
            self.onCancelButtonClicked(self)
        }
    }
    

    @IBAction func goToFollowersPage(sender: AnyObject) {
        
        let parentViewController = self.parentViewController as! MainPageViewController
        parentViewController.goToFollowersPage()
        
    }
   
    @IBAction func goToFollowingPage(sender: AnyObject) {
        let parentViewController = self.parentViewController as! MainPageViewController
        parentViewController.goToFollowingPage()
    }
    
    @IBAction func onChangeProfilePictureClicked(sender: UIButton) {
        let imagePicker = UIImagePickerController()    // Used for selecting image from user's device

        // Present the Saved Photo Album to user only if it is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum)
        {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }

    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        // Close the image picker view when user is finished with it
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // Set the button's new image
        setUserS3Image(currentUserName, userImage: image) { (error) in
            
            // Perform update on UI on main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error != nil
                {
                    showAlert("Sorry", message: "Something went wrong, we couldn't upload the photo right now. Please try again later.", buttonTitle: "Ok", sender: self)
                }
                else
                {
                    self.profileImageView.image = image
                }
            })
        }
    }
    
    
    
    @IBAction func onEditInformationButtonClicked(sender: AnyObject) {
        
        // Reload data with editing enabled
        enableEditing = true
        settingsTableView.reloadData()
        
        // Show the buttons in edit view
        editButton.hidden = true
        cancelButton.hidden = false
        saveButton.hidden = false
        
        // Used to keep track of accounts the user wants to delete or not
        if currentUserAccounts == nil
        {
            oldUserAccounts = nil
        }
        else
        {
            oldUserAccounts = NSMutableDictionary(dictionary: currentUserAccounts as [NSObject : AnyObject], copyItems: true)
        }
        // Set first input field as first responder
//        realNameTextFieldLabel.becomeFirstResponder()
        realNameTextFieldLabel.performSelector(#selector(becomeFirstResponder))
        
    }
    
    @IBAction func onCancelButtonClicked(sender: AnyObject) {
        
        enableEditing = false
        
        // Show the edit button again
        editButton.hidden = false
        cancelButton.hidden = true
        saveButton.hidden = true
        
        // Reset any modified user accounts (profiles)
        if oldUserAccounts == nil
        {
            currentUserAccounts = nil
        }
        else
        {
            currentUserAccounts = NSMutableDictionary(dictionary: oldUserAccounts as [NSObject : AnyObject], copyItems: true)
        }
        keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(currentUserAccounts)
        self.settingsTableView.reloadData()
        
    }
    
    @IBAction func onSaveButtonClicked(sender: AnyObject) {

        // State resets
        self.enableEditing = false
        self.settingsTableView.reloadData()
        
        // Show the edit button again
        self.editButton.hidden = false
        self.cancelButton.hidden = true
        self.saveButton.hidden = true

        
        let fullNameIndexPath = NSIndexPath(forRow: MyInformationData.FULL_NAME.rawValue , inSection: MenuData.MY_INFORMATION.rawValue)
        let emailIndexPath = NSIndexPath(forRow: MyInformationData.EMAIL.rawValue, inSection: MenuData.MY_INFORMATION.rawValue)
        let phoneIndexPath = NSIndexPath(forRow: MyInformationData.PHONE.rawValue, inSection: MenuData.MY_INFORMATION.rawValue)

        let fullNameCell = settingsTableView.cellForRowAtIndexPath(fullNameIndexPath) as! MenuTableViewCell
        let emailCell = settingsTableView.cellForRowAtIndexPath(emailIndexPath) as! MenuTableViewCell
        let phoneCell = settingsTableView.cellForRowAtIndexPath(phoneIndexPath) as! MenuTableViewCell //TODO: CRASH?

        // If modified data, adjust accordingly!
        if editedRealName != nil && !editedRealName.isEmpty
        {
            if (!verifyRealNameLength(editedRealName!))
            {
                showAlert("Improper full name format", message: "Please create a full name that is less than 30 characters long!", buttonTitle: "Try again", sender: self)
                return
            }
        }
        
        if editedUserEmail != nil && !editedUserEmail.isEmpty
        {
            if (!verifyEmailFormat(editedUserEmail!))
            {
                showAlert("Improper email address", message: "Please enter in a proper email address!", buttonTitle: "Try again", sender: self)
                return
            }
    
        }
        
        
        if editedUserPhone != nil && !editedUserPhone.isEmpty
        {
            // Get the text from the beginning of the phone number (not US country code)
            let string = editedUserPhone as NSString
            let phoneString = string.substringFromIndex(2)
            
            if !verifyPhoneFormat(phoneString)
            {
                showAlert("Improper phone number", message: "Please enter in a proper U.S. phone number.", buttonTitle: "Try again", sender: self)
                return
            }
            
           
        }
        
        // ADD CHANGE TO USERPOOLS (email/phone only)
        let userPool = getAWSCognitoIdentityUserPool()
        let email = AWSCognitoIdentityUserAttributeType()
        let phone = AWSCognitoIdentityUserAttributeType()
        email.name = "email"
        phone.name = "phone_number"

        if editedUserEmail != nil && editedUserEmail != currentUserEmail
        {
            // Update user pools with currentUserPhone
            emailCell.menuValue.text = editedUserEmail
            currentUserEmail = editedUserEmail
      
            email.value = currentUserEmail
            phone.value = currentUserPhone
            
            
            userPool.getUser(currentUserName).updateAttributes([email, phone]).continueWithSuccessBlock { (resultTask) -> AnyObject? in
             
                print("SUCCESSFUL USER EMAIL UPDATE IN USERPOOLS")
                return nil
            }
            
        }
        
        if editedUserPhone != nil && editedUserPhone != currentUserPhone
        {
            // In case we need to revert changes -- if user cannot verify
            let oldPhoneNum = currentUserPhone
            
            // Update user pools with currentUserEmail
            phoneCell.menuValue.text = editedUserPhone
            currentUserPhone = editedUserPhone
            
            email.value = currentUserEmail
            phone.value = currentUserPhone
            
            userPool.getUser(currentUserName).updateAttributes([email, phone]).continueWithSuccessBlock { (resultTask) -> AnyObject? in
                
                
//                // Prompt user to enter in confirmation code.
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.showVerificationPopup({ (result) in
//                        if result != nil
//                        {
//                            // Check if valid verification code
//                            userPool.getUser(self.currentUserName).confirmSignUp(result!).continueWithBlock { (resultTask) -> AnyObject? in
//                                
//                                // If success code
//                                if resultTask.error == nil
//                                {
//                                    // We good to go!
//                                    print("WE GOOD TO GO!")
//                                }
//                                else
//                                {
//                                    // Invalid code
//                                    print("INVALID CODE")
//                                }
//                                
//                                return nil
//                            }
//                        }
//                        else
//                        {
//                            // Invalid entry or request, revert back to previous phone number
//                            print("INVALID REQUESTO")
//                        }
//                    })
//
//                })
                
                setCurrentCachedUserPhone(self.currentUserPhone)
                
                print("SUCCESSFUL USER PHONE UPDATE IN USERPOOLS")
                return nil
            }
            

        }
        
        // Check if we need to update dynamo
        if editedRealName != nil
        {
            fullNameCell.menuValue.text = editedRealName
            currentRealName = editedRealName
            
            // Change name at top of page, too
            realNameTextFieldLabel.text = currentRealName
            
            print ("UPDATING REALNAME IN DYNAMO AND LAMBDA")
            
            /********************************
             *  UPLOAD USER DATA TO DYNAMODB
             ********************************/
            // Upload user DATA to DynamoDB
            let dynamoDBUser = User()
            
            dynamoDBUser.realname = currentRealName
            dynamoDBUser.username = currentUserName

            if currentUserAccounts != nil && currentUserAccounts.count != 0
            {
                dynamoDBUser.accounts = currentUserAccounts
            }
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
                
                // If successful save
                if (resultTask.error == nil && resultTask.result != nil)
                {
                    print ("DYNAMODB SUCCESSFUL SAVE: ", resultTask.result)
                    setCurrentCachedFullName(self.currentRealName)

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
            
            // Update user real name in lambda as well
            let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
            let parameters = ["action":"updatern", "target": currentUserName, "realname": currentRealName]
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
            
        }
        
        if hasDeletedProfiles
        {
            
            /********************************
             *  UPLOAD USER DATA TO DYNAMODB
             ********************************/
            // Upload user DATA to DynamoDB
            let dynamoDBUser = User()
            
            dynamoDBUser.realname = currentRealName
            dynamoDBUser.username = currentUserName
            
            // If no current account data, do not upload to dynamo
            // or else it will throw an error.
            if currentUserAccounts.count != 0
            {
                dynamoDBUser.accounts = currentUserAccounts
            }
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
                
                // If successful save
                if (resultTask.error == nil && resultTask.result != nil)
                {
                    print ("DYNAMODB SUCCESSFUL SAVE: ", resultTask.result)
                
        
                    // Update UI on main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Cache user accounts result
                        setCurrentCachedUserProfiles(self.currentUserAccounts)
                        self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(self.currentUserAccounts)
                        
                        self.hasDeletedProfiles = false
                        
                        // Reload table
                        self.settingsTableView.reloadData()

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
        
        // Clear the edited results
        editedRealName = nil
        editedUserEmail = nil
        editedUserPhone = nil
        

        print("full name modified is:", fullNameCell.menuValue.text)
        print("email data modified is:", emailCell.menuValue.text)
        print("phone data modified is:", phoneCell.menuValue.text)
    }
    
 
    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        
        switch (sender.tag)
        {
        case MyInformationData.FULL_NAME.rawValue:
            editedRealName = sender.text!
            break;
        case MyInformationData.EMAIL.rawValue:
            editedUserEmail = sender.text!
            break;
        case MyInformationData.PHONE.rawValue:
            editedUserPhone = sender.text!
            break;
        default:
            break;
        }
        
    
        
        print("TEXT FIELD EDITING ENDED: ", sender.text)
    }

    /**************************************************************************
     *    COLLECTION VIEW PROTOCOL
     **************************************************************************/
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if (keyValSocialMediaPairList.isEmpty)
        {
            return 0
        }
    
        print ("NUM KEYVALSOCIALMEDIAPAR IN LIST: ", keyValSocialMediaPairList.count)
        return keyValSocialMediaPairList.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if !enableEditing
        {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
            
            print ("SELECTED", cell.socialMediaName)
            
            let socialMediaUserName = cell.socialMediaName
            let socialMediaType = cell.socialMediaType
            
            let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)

            // Perform the request, go to external application and let the user do whatever they want!
            if socialMediaURL != nil
            {
                UIApplication.sharedApplication().openURL(socialMediaURL)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("accountsCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        if (!keyValSocialMediaPairList.isEmpty)
        {
            let socialMediaPair = keyValSocialMediaPairList[indexPath.item % keyValSocialMediaPairList.count]
            let socialMediaType = socialMediaPair.socialMediaType
            let socialMediaUserName = socialMediaPair.socialMediaUserName

                
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
            
            cell.socialMediaName = socialMediaUserName // username
            cell.socialMediaType = socialMediaType // facebook, snapchat, etc
            
            cell.delegate = self
            
            print("enableEditing is: ", enableEditing)
            // Show the delete buttons if in editing mode!
            if (enableEditing)
            {
                cell.deleteSocialMediaButton.hidden = false
            }
            else
            {
                cell.deleteSocialMediaButton.hidden = true
            }
            
            // Make cell image circular
//            cell.layer.cornerRadius = cell.frame.width / 2
            cell.emblemImage.layer.cornerRadius = cell.emblemImage.frame.width / 2
        }
        
        return cell
    }
    
    // Used for polishing phone number in table view
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == MyInformationData.PHONE.rawValue
        {
            print ("HOLA")
            
            // Do not let user modify first 2 characters. Right now this is for US phone numbers ("+1")
            if (range.location < 2)
            {
                return false
            }
            
            return true
        }

        return false
    }
    
    func phoneNumberTextFieldEditingDidChange(textField: UITextField)
    {
        // Get the text from the beginning of the phone number (not US country code)
        let string = (textField.text)! as NSString
        let phoneString = string.substringFromIndex(2)
        
        textField.text = "+1" + removeAllNonDigits(phoneString)
        
        
    }
    
    /**************************************************************************
     *    TABLE VIEW PROTOCOL
     **************************************************************************/
    // Specify number of sections in our table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        // Return number of sections
        return tableViewSectionsList.count
    }
    
    // Specify height of header
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }

    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableViewSectionsList[section].sectionTitle
    }

    // Specify height of table view cells
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var returnHeight : CGFloat!
        
        switch indexPath.section
        {
        case MenuData.LINKED_PROFILES.rawValue:
            returnHeight = defaultTableViewCellHeight
            break;
        case MenuData.SOCIAL_ACTIONS.rawValue:
            returnHeight = CGFloat(50)
          break;
        case MenuData.MY_INFORMATION.rawValue:
            returnHeight = defaultTableViewCellHeight
            break;
        case MenuData.NOTIFICATION_SETTINGS.rawValue:
            returnHeight = CGFloat(50)
            break;
        case MenuData.PRIVACY_SETTINGS.rawValue:
            returnHeight = CGFloat(50)
            break;
        case MenuData.ACTIONS.rawValue:
            returnHeight = CGFloat(50)
            break;
            
        default:
            returnHeight = defaultTableViewCellHeight
        }
        
        return returnHeight
    }
    
    // Return the number of rows in each given section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableViewSectionsList[section].sectionCount
    }

    // Configure which cell to display
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.section
        {
        case MenuData.LINKED_PROFILES.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier("menuProfilesCell") as! MenuProfilesCell!
            
            cell.profilesCollectionView.reloadData()
            
            // Show delete buttons if editing is enabled.
            if (enableEditing)
            {
                //TODO: Red delete buttons
            }
            
            return cell
            break;
        case MenuData.MY_INFORMATION.rawValue:
            //else return regular cell
            let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
            
            switch (indexPath.item)
            {
            case MyInformationData.FULL_NAME.rawValue: //User full name
                cell.menuTitle.text = "Full Name"
                cell.menuValue.text = currentRealName
                // Tag is needed so we can detect which text field is being modified later on
                cell.menuValue.tag  = MyInformationData.FULL_NAME.rawValue
                break;
            case MyInformationData.EMAIL.rawValue: //User email
                cell.menuTitle.text = "Email"
                cell.menuValue.text = currentUserEmail
                // Tag is needed so we can detect which text field is being modified later on
                cell.menuValue.tag  = MyInformationData.EMAIL.rawValue
            
                break;
            case MyInformationData.PHONE.rawValue: //User phone
                cell.menuTitle.text = "Phone"
                cell.menuValue.text = currentUserPhone
                // Tag is needed so we can detect which text field is being modified later on
                cell.menuValue.tag  = MyInformationData.PHONE.rawValue
                
                cell.menuValue.addTarget(self, action: #selector(phoneNumberTextFieldEditingDidChange), forControlEvents: UIControlEvents.EditingChanged)
                cell.menuValue.delegate = self
                cell.menuValue.keyboardType = UIKeyboardType.NumberPad
                break;
                
            default: //Default
                cell.menuTitle.text = ""
                cell.menuValue.text = ""
                
            }
            
            // Set text field editable and display the cool line underneath
            if (enableEditing)
            {
                cell.menuLineSeparator.hidden = false
                cell.menuValue.enabled = true
            }
            else
            {
                cell.menuLineSeparator.hidden = true
                cell.menuValue.enabled = false
            }
            return cell
            break;
        case MenuData.SOCIAL_ACTIONS.rawValue:
          // return regular button cell
          let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
          
          switch (indexPath.item)
          {
          case 0: // button
            cell.menuButtonLabel.text = "Find Faceook friends to follow"
            break;
            
          default: //Default
            cell.menuButtonLabel.text = ""
            
          }
          
          return cell
          
          break;
        case MenuData.NOTIFICATION_SETTINGS.rawValue:
            // return regular button cell
            let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
            
            switch (indexPath.item)
            {
            case 0: // button
                cell.menuButtonLabel.text = "Coming Soon!"
                break;
                
            default: //Default
                cell.menuButtonLabel.text = ""
                
            }
            
            return cell

            break;
        case MenuData.PRIVACY_SETTINGS.rawValue:
            // return regular button cell
            let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
            
            switch (indexPath.item)
            {
            case 0: //Link to privacy policy page
                cell.menuButtonLabel.text = "Privacy Policy"
            case 1: //Log out button
                cell.menuButtonLabel.text = "More Coming Soon!"
                break;
                
            default: //Default
                cell.menuButtonLabel.text = ""
                
            }
            
            return cell

            break;
        case MenuData.ACTIONS.rawValue:
            // return regular button cell
            let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
            
            switch (indexPath.item)
            {
            case 0:
                cell.menuButtonLabel.text = "Change Password"
                break;
            case 1: //Log out button
                cell.menuButtonLabel.text = "Log Out"
                break;
            default: //Default
                cell.menuButtonLabel.text = ""
                
            }
            
            return cell
            break;
        default:
            // Default cell return..
            let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
            return cell
            
            
        }
    }
    
    // Configure/customize each table header view
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionTitle = tableViewSectionsList[section].sectionTitle
        
        let cell = tableView.dequeueReusableCellWithIdentifier("sectionHeaderCell") as! SectionHeaderCell!
        
        cell.sectionTitle.text = sectionTitle
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        if (indexPath.section == MenuData.ACTIONS.rawValue)
        {
            // Reset password button
            if (indexPath.item == 0)
            {
                performSegueWithIdentifier("toResetPasswordViewController", sender: self)
            }
            
            // Log out button
            if (indexPath.item == 1)
            {
                logUserOut()
            }
        }
      
        if (indexPath.section == MenuData.SOCIAL_ACTIONS.rawValue)
        {
          // Find facebook friends to follow button
          if (indexPath.item == 0)
          {
//            performSegueWithIdentifier("toResetPasswordViewController", sender: self)
              getFacebookFriendsUsingApp()
          }
          
        }
      
        if (indexPath.section == MenuData.PRIVACY_SETTINGS.rawValue)
        {
            // Go to privacy page
            if (indexPath.item == 0)
            {
                performSegueWithIdentifier("toPrivacyPolicyViewController", sender: self)
            }
        }
    
    }
  
    func getFacebookFriendsUsingApp()
    {
      let login = FBSDKLoginManager.init()
      login.logOut()
      
      // Open in app instead of web browser!
      login.loginBehavior = FBSDKLoginBehavior.Native
      
      // Request basic profile permissions just to get user ID
      login.logInWithReadPermissions(["public_profile", "user_friends"], fromViewController: self) { (result, error) in
        // If no error, store facebook user ID
        if (error == nil && result != nil) {
          print("SUCCESS LOG IN!", result.debugDescription)
          print(result.description)
          
          print("RESULTOO: ", result)
          
          if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            print("Current access user id: ", FBSDKAccessToken.currentAccessToken().userID)
            
            let request = FBSDKGraphRequest(graphPath: "/me/friends", parameters: nil)
            request.startWithCompletionHandler { (connection, result, error) in
              if error == nil {
                print("My **FB Friends using this app are: ", result)
              } else {
                print("Error getting **FB friends", error)
              }
            }
          }
        } else if (result == nil && error != nil) {
          print ("ERROR IS: ", error)
        } else {
          print("FAIL LOG IN")
        }
      }
      
      
      
      print("YOLOGINYO")
      
    }
    
    func logUserOut()
    {
        
        // Ask user if they really want to log out...
        let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            // present the log in home page
            
            //TODO: Add spinner functionality
            self.performSegueWithIdentifier("logOut", sender: nil)
            
            // Log out AWS
            self.credentialsProvider.clearCredentials()
            self.credentialsProvider.invalidateCachedTemporaryCredentials()
            self.credentialsProvider.clearKeychain()
            
            // get the IDENTITY POOL to log out AWS Cognito
            let pool = getAWSCognitoIdentityUserPool()
            
            print("*** MenuController *** currentUser 1", pool.currentUser()?.username)
            pool.currentUser()?.signOut()
            
            print("*** MenuController *** currentUser 2", pool.currentUser()?.username)
            pool.getUser(self.currentUserName).signOut()
            
            
            // Update new identity ID
            self.credentialsProvider.getIdentityId().continueWithBlock { (resultTask) -> AnyObject? in
                
                print("LOGOUT, identity id is:", resultTask.result)
                print("LOG2, ", self.credentialsProvider.identityId)
                return nil
            }
            
            
            
            // Clear local cache and user identity
            clearUserDefaults()
            
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
   
    }
    
    /*************************************************************************
     *    SELF-DEFINED DATA TRANSFER PROTOCOL
     **************************************************************************/
    func userDidAddNewProfile(socialMediaType: String, socialMediaName: String) {
        
        print("In protocol implementation -- data added: ", socialMediaType, " ", socialMediaName)
        
        updateCurrentUserProfilesDynamoDB(currentUserAccounts, socialMediaType: socialMediaType, socialMediaName: socialMediaName, isAdding: true) { (result, error) in
            
            if result != nil && error == nil
            {
                if result?.accounts == nil
                {
                    // Instantiate empty dictionary..
                    self.currentUserAccounts = NSMutableDictionary()
                }
                else
                {
                    self.currentUserAccounts = (result?.accounts)!
                }
                
                setCurrentCachedUserProfiles(self.currentUserAccounts)
                
                // Dictionary with key: string of social media types (i.e. "facebook"),
                // val: array of usernames for that social media (i.e. "austinvaday, austinv, sammyv")
                // Convert dictionary to key,val pairs. Redundancy allowed
                self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(self.currentUserAccounts)
                
                
                // Propagate newsfeed object data
                if self.newUserAccountsForNewsfeed.valueForKey(socialMediaType) == nil
                {
                    self.newUserAccountsForNewsfeed.setValue([ socialMediaName ], forKey: socialMediaType)
                }
                else // If the key already exists
                {
                    var list = self.newUserAccountsForNewsfeed.valueForKey(socialMediaType) as! Array<String>
                    list.append(socialMediaName)
                    self.newUserAccountsForNewsfeed.setValue(list, forKey: socialMediaType)
                }
                
                print("Adding new profile [", socialMediaType, ":", socialMediaName, " to newUserAccountsForNewsfeed.")
                print ("New list is: ", self.newUserAccountsForNewsfeed)
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    // Propogate collection view with new data
                    self.settingsTableView.reloadData()
                    
                })
                
            }
        }

        
        
        
//        // Dynamo updated already, just update local cache
//        
//        // If user does not have a particular social media type,
//        // we need to create a list
//        if (currentUserAccounts.valueForKey(socialMediaType) == nil)
//        {
//            currentUserAccounts.setValue([ socialMediaName ], forKey: socialMediaType)
//            
//        } // If it already exists, append value to end of list
//        else
//        {
//            var list = currentUserAccounts.valueForKey(socialMediaType) as! Array<String>
//            list.append(socialMediaName)
//            
//            currentUserAccounts.setValue(list, forKey: socialMediaType)
//        }
//
//        
//        setCurrentCachedUserProfiles(currentUserAccounts)
//        
//        // Dictionary with key: string of social media types (i.e. "facebook"),
//        // val: array of usernames for that social media (i.e. "austinvaday, austinv, sammyv")
//        self.socialMediaUserNames = currentUserAccounts
//        
//        // Convert dictionary to key,val pairs. Redundancy allowed
//        self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(self.socialMediaUserNames, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
//        
//        
//        // Reload table view data
//        settingsTableView.reloadData()
        
    }
    
    func userDidDeleteSocialMediaProfile(socialMediaType: String, socialMediaName: String) {
        
        print("OK! time to delete ", socialMediaType, " --> ", socialMediaName)
        hasDeletedProfiles = true
        
        // Delete account from local list. If user hits success button -- save changes
        if currentUserAccounts.valueForKey(socialMediaType) != nil
        {
            var list = currentUserAccounts.objectForKey(socialMediaType) as! Array<String>
            
            // Update list as to remove this specific value
            list.removeAtIndex(list.indexOf(socialMediaName)!)
            
            // If nothing in list, we need to delete the key
            if list.count == 0
            {
                currentUserAccounts.removeObjectForKey(socialMediaType)
            }
            else
            {
                currentUserAccounts.setValue(list, forKey: socialMediaType)
            }
            
            keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(currentUserAccounts)
            settingsTableView.reloadData()

        }
        
        // Delete account from newsfeed object as well
        if newUserAccountsForNewsfeed.valueForKey(socialMediaType) != nil
        {
            if newUserAccountsForNewsfeed.valueForKey(socialMediaType) != nil
            {
                var list = newUserAccountsForNewsfeed.valueForKey(socialMediaType) as! Array<String>
                
                if list.indexOf(socialMediaName) != nil
                {
                    // Update list as to remove this specific value
                    list.removeAtIndex(list.indexOf(socialMediaName)!)
                    
                    // If nothing in list, we need to delete the key
                    if list.count == 0
                    {
                        newUserAccountsForNewsfeed.removeObjectForKey(socialMediaType)
                    }
                    else
                    {
                        newUserAccountsForNewsfeed.setValue(list, forKey: socialMediaType)
                    }
                }
            }
        }
        
        print("Removing profile [", socialMediaType, ":", socialMediaName, " from newUserAccountsForNewsfeed.")
        print ("New list is: ", self.newUserAccountsForNewsfeed)
    }
    
    // Helper functions
    //---------------------------------------------------------------------------------------------------
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
//        self.settingsTableView.reloadData()

        generateData()
        
        // Need to end refreshing
        delay(0.5)
        {
            self.refreshControl.endRefreshing()
            print("REFRESH CONTROL!")
//            self.viewDidLoad()
            
        }


    }
    
    private func generateData()
    {
        // Initialize array so that collection view has something to check while we
        // fetch data from dynamo
        keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
        
        // Fetch the user's username and real name
        currentUserName = getCurrentCachedUser()
        currentRealName = getCurrentCachedFullName()
        currentUserImage = getCurrentCachedUserImage()
        currentUserAccounts = getCurrentCachedUserProfiles()
        currentUserEmail = getCurrentCachedEmail()
        currentUserPhone = getCurrentCachedPhone()
        
        print("CUR USERNAME: ", currentUserName)
        
        
        // If any values are nil, we need to re-cache -- safety precautions
        // Note if a user has no user accounts, we'll be re-caching every time (side effect)
        if (currentRealName == nil ||
            currentUserImage == nil ||
            currentUserAccounts == nil ||
            currentUserEmail == nil ||
            currentUserPhone == nil)
        {
            
            print("RE-caching user...")
            setCachedUserFromAWS(currentUserName)
            
            //re-set attributes
            //            currentUserName = getCurrentCachedUser()
            currentRealName = getCurrentCachedFullName()
            currentUserImage = getCurrentCachedUserImage()
            currentUserAccounts = getCurrentCachedUserProfiles()
            currentUserEmail = getCurrentCachedEmail()
            currentUserPhone = getCurrentCachedPhone()

        }
        
        // Set the UI
        userNameLabel.text = currentUserName
        realNameTextFieldLabel.text  = currentRealName
        
        if currentUserImage == nil
        {
            profileImageView.image = defaultImage
        }
        else
        {
            profileImageView.image = currentUserImage
        }
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()
        
        // If user has added accounts/profiles, show them
        if(currentUserAccounts != nil)
        {
            // Dictionary with key: string of social media types (i.e. "facebook"),
            // val: array of usernames for that social media (i.e. "austinvaday, austinv, sammyv")
 
            // Convert dictionary to key,val pairs. Redundancy allowed
            self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(self.currentUserAccounts)
            
            
            // Perform update on UI on main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // Propogate collection view with new data
                self.settingsTableView.reloadData()
                
                print("RELOADING COLLECTIONVIEW")
            })
        }
        
        // Fetch num followers from lambda
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        var parameters = ["action":"getNumFollowers", "target": currentUserName]
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
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let number = resultTask.result as? Int
                    self.numFollowersLabel.text = String(number!)
                })
                
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }
        
        // Fetch num followees from lambda
        parameters = ["action":"getNumFollowees", "target": currentUserName]
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
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let number = resultTask.result as? Int
                    self.numFollowsLabel.text = String(number!)
                })
                
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }
        

    }
    
    private func updateProfilesDynamoDB(currentAccounts: NSMutableDictionary)
    {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let currentUser = getCurrentCachedUser()
        let currentRealName = getCurrentCachedFullName()
    
    
        // Upload user DATA to DynamoDB
        let dynamoDBUser = User()
        
        dynamoDBUser.username = currentUser
        dynamoDBUser.realname = currentRealName
        dynamoDBUser.accounts = currentAccounts
        
        dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
            
            if (resultTask.error != nil)
            {
                print ("DYNAMODB MODIFY PROFILE ERROR: ", resultTask.error)
            }
            
            if (resultTask.exception != nil)
            {
                print ("DYNAMODB MODIFY PROFILE EXCEPTION: ", resultTask.exception)
            }
            
            if (resultTask.result == nil)
            {
                print ("DYNAMODB MODIFY PROFILE result is nil....: ")
                
            }
                // If successful save
            else if (resultTask.error == nil)
            {
                print ("DYNAMODB MODIFY PROFILE SUCCESS: ", resultTask.result)
                
                // Also cache accounts data
//                setCurrentCachedUserProfiles(currentAccounts)
                
                // Refresh something...
            }
            
            
            return nil
        })
        
    }
    
    
    private func showVerificationPopup(completion: (result:String?)->())
    {
        var alertViewResponder: SCLAlertViewResponder!
        let subview = UIView(frame: CGRectMake(0,0,216,70))
        let x = (subview.frame.width - 180) / 2
        let colorDarkBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        
        // Add text field for username
        let textField = UITextField(frame: CGRectMake(x,10,180,25))
        
        //            textField.layer.borderColor = colorLightBlue.CGColor
        //            textField.layer.borderWidth = 1.5
        //            textField.layer.cornerRadius = 5
        textField.font = UIFont(name: "Avenir Roman", size: 14.0)
        textField.textColor = colorDarkBlue
        textField.placeholder = "Enter Verification Code"
        textField.textAlignment = NSTextAlignment.Center
        
        // Add target to text field to validate/fix user input of a proper input
//        textField.addTarget(self, action: #selector(usernameTextFieldDidChange), forControlEvents: UIControlEvents.EditingChanged)
        subview.addSubview(textField)
//
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 40,
            kCircleHeight: 55,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
            
        )
        
        let alertView = SCLAlertView(appearance: alertAppearance)
        
        alertView.customSubview = subview
        alertView.addButton("Submit", action: {
            print("Submit button clicked for textField data:", textField.text)
            
            if alertViewResponder == nil
            {
                print("Something went wrong...")
                completion(result: nil)
            }
            
            let code = textField.text!
            
            if code.isEmpty
            {
                //TODO: Nothing?
            }
            else if code.characters.count != 6
            {
                //TODO: Notify that username is too long
                alertViewResponder.close()
                completion(result: nil)

                
                // Reset userpools to old phone number
            }
            else
            {
                print("SUCCESS RESULT:", code)
                alertViewResponder.close()
                completion(result: code)
                // Update userpools with verification
            }
            
            
        })
        
        let alertViewIcon = UIImage(named: "Emblem White")
        
        alertViewResponder = alertView.showTitle("Verify Phone",
                                                 subTitle: "",
                                                 duration:0.0,
                                                 completeText: "Cancel",
                                                 style: .Success,
                                                 colorStyle: 0x0F7A9D,
                                                 colorTextButton: 0xFFFFFF,
                                                 circleIconImage: alertViewIcon,
                                                 animationStyle: .BottomToTop
        )

    }

    // UNWIND SEGUES
    @IBAction func unwindBackToMenuVC(segue:UIStoryboardSegue)
    {
        print("Success unwind to menu VC")
//        print("REFRESH COLLECTION VIEW")
//        currentUserAccountsDirty = true
//        viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToAddSocialMediaProfilesController"
        {
            // Need to set delegate so that we can fetch which data user added in
            let vc = segue.destinationViewController as! AddSocialMediaProfilesController
            vc.delegate = self
        }
    }
    
    
    
}
