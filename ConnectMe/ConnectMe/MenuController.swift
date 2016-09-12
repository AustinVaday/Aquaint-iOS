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

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    enum MenuData: Int {
        case LINKED_PROFILES
        case MY_INFORMATION
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
    var currentUserImage: UIImage!
    var currentUserEmail : String!
    var currentUserPhone : String!
    var editedRealName : String!
    var editedUserEmail : String!
    var editedUserPhone : String!
    
    var currentUserAccountsDirty = false
    var isKeyboardShown = false
    var enableEditing = false // Whether or not to enable editing of text fields.
    var buttonViewOriginalFrame : CGRect!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var keyValSocialMediaPairList : Array<KeyValSocialMediaPair>!
    var tableViewSectionsList : Array<SectionTitleAndCountPair>!
    var refreshControl : UIRefreshControl!

    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube", "tumblr" /*, "phone"*/)
    
    // AWS credentials provider
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
    
    let footerHeight = CGFloat(65)
    let defaultTableViewCellHeight = CGFloat(60)

    override func viewDidLoad() {

        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Disable editing by default
        enableEditing = false
        
        // Ensure that the button view is always visible -- in front of the table view
        buttonView.layer.zPosition = 1
        
        // Fetch the user's username and real name
        currentUserName = getCurrentCachedUser()
        currentRealName = getCurrentCachedFullName()
        currentUserImage = getCurrentCachedUserImage()
        currentUserAccounts = getCurrentCachedUserProfiles()
        currentUserEmail = getCurrentCachedEmail()
        currentUserPhone = getCurrentCachedPhone()
        
        // Set up the data for the table views section. Note: Dictionary does not work for this list as we need a sense of ordering.   
        tableViewSectionsList = Array<SectionTitleAndCountPair>()
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Linked Profiles", sectionCount: 1))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "My Information", sectionCount: 3))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Notification Settings", sectionCount: 1))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Privacy Settings", sectionCount: 1))
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Actions", sectionCount: 2))
        
        
        // Initialize array so that collection view has something to check while we
        // fetch data from dynamo
        keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
        
        print("CUR USERNAME: ", currentUserName)
        
        
        if currentUserAccountsDirty
        {
            print("CURRENT USER ACCOUNT DIRTY!")
            getUserDynamoData(currentUserName, completion: { (result, error) in
                if result != nil && error == nil
                {
                    self.currentUserAccounts = result!.accounts as NSMutableDictionary
                    setCurrentCachedUserProfiles(self.currentUserAccounts)
                }
            })
            
            
        }
        
        // If any values are nil, we need to re-cache
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
        profileImageView.image = currentUserImage

        
        // Set up dictionary for user's social media names
        socialMediaUserNames = currentUserAccounts
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
        
        // If user has added accounts/profiles, show them
        if(currentUserAccounts != nil)
        {
            // Dictionary with key: string of social media types (i.e. "facebook"),
            // val: array of usernames for that social media (i.e. "austinvaday, austinv, sammyv")
            self.socialMediaUserNames = currentUserAccounts
            
            // Convert dictionary to key,val pairs. Redundancy allowed
            self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(self.socialMediaUserNames, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
            
            
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
    @IBAction func onEditInformationButtonClicked(sender: AnyObject) {
        
        // Reload data with editing enabled
        enableEditing = true
        settingsTableView.reloadData()
        
        // Show the buttons in edit view
        editButton.hidden = true
        cancelButton.hidden = false
        saveButton.hidden = false
        
        // Set first input field as first responder
//        realNameTextFieldLabel.becomeFirstResponder()
        realNameTextFieldLabel.performSelector(#selector(becomeFirstResponder))
        
    }
    
    @IBAction func onCancelButtonClicked(sender: AnyObject) {
        
        enableEditing = false
        settingsTableView.reloadData()
        
        // Show the edit button again
        editButton.hidden = false
        cancelButton.hidden = true
        saveButton.hidden = true
        
    }
    
    @IBAction func onSaveButtonClicked(sender: AnyObject) {
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
        let phoneCell = settingsTableView.cellForRowAtIndexPath(phoneIndexPath) as! MenuTableViewCell

        // If modified data, adjust accordingly!
        if editedRealName != nil && !editedRealName.isEmpty
        {
            if (!verifyRealNameLength(editedRealName!))
            {
                showAlert("Improper full name format", message: "Please create a full name that is less than 30 characters long!", buttonTitle: "Try again", sender: self)
                return
            }

            fullNameCell.menuValue.text = editedRealName
            currentRealName = editedRealName
            setCurrentCachedFullName(currentRealName)
            
            // Change name at top of page, too
            realNameTextFieldLabel.text = currentRealName
            
            
            // ADD CHANGE TO DYNAMO
            
            
            
        }
        
        if editedUserEmail != nil && !editedUserEmail.isEmpty
        {
            if (!verifyEmailFormat(editedUserEmail!))
            {
                showAlert("Improper email address", message: "Please enter in a proper email address!", buttonTitle: "Try again", sender: self)
                return
            }
            
            
            emailCell.menuValue.text = editedUserEmail
            currentUserEmail = editedUserEmail
            setCurrentCachedUserEmail(currentUserEmail)
        }
        
        
        if editedUserPhone != nil && !editedUserPhone.isEmpty
        {
//            if (!verifyPhoneFormat(editedUserPhone!))
//            {
//                showAlert("Improper phone number", message: "Please enter in a proper U.S. phone number.", buttonTitle: "Try again", sender: self)
//                return
//            }
            
            phoneCell.menuValue.text = editedUserPhone
            currentUserPhone = editedUserPhone
            setCurrentCachedUserPhone(currentUserPhone)
        }
        
        // Check if we need to update user pools
        if editedUserEmail != nil || editedUserPhone != nil
        {
            print ("UPDATING USER POOLS")
            // ADD CHANGE TO USERPOOLS (email/phone only)
            let userPool = getAWSCognitoIdentityUserPool()
            let email = AWSCognitoIdentityUserAttributeType()
            let phone = AWSCognitoIdentityUserAttributeType()
            
            email.name = "email"
            email.value = currentUserEmail
            phone.name = "phone_number"
            phone.value = currentUserPhone
            
            
            userPool.getUser(currentUserName).updateAttributes([email, phone]).continueWithSuccessBlock { (resultTask) -> AnyObject? in
                print("successful user pools update!")
                return nil
            }

        }
        
        // Check if we need to update dynamo
        if editedRealName != nil
        {
            print ("UPDATING DYNAMO")
            
            /********************************
             *  UPLOAD USER DATA TO DYNAMODB
             ********************************/
            // Upload user DATA to DynamoDB
            let dynamoDBUser = User()
            
            dynamoDBUser.realname = currentRealName
            dynamoDBUser.username = currentUserName
            dynamoDBUser.accounts = currentUserAccounts
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
                
                // If successful save
                if (resultTask.error == nil && resultTask.result != nil)
                {
                    print ("DYNAMODB SUCCESSFUL SAVE: ", resultTask.result)
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
    
        return keyValSocialMediaPairList.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        
        print ("SELECTED", cell.socialMediaName)
        
        let socialMediaUserName = cell.socialMediaName
        let socialMediaType = cell.socialMediaType
        
        let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)

        // Perform the request, go to external application and let the user do whatever they want!
        UIApplication.sharedApplication().openURL(socialMediaURL)
        
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
            case 0: //Log out button
                cell.menuButtonLabel.text = "Coming Soon!"
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
                cell.menuButtonLabel.text = "Reset Password"
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
            if (indexPath.item == 0)
            {
                print ("COMING SOON")
            }
            
            // Log out button
            if (indexPath.item == 1)
            {
                logUserOut()
            }
        }
    
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
    
    // Helper functions
    //---------------------------------------------------------------------------------------------------
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
        self.settingsTableView.reloadData()
        print ("Reloading Data...")

        // Need to end refreshing
        delay(0.5)
        {
            self.refreshControl.endRefreshing()
        }

    }
    
    // UNWIND SEGUES
    @IBAction func unwindBackToMenuVC(segue:UIStoryboardSegue)
    {
        print("Success unwind to menu VC")
        print("REFRESH COLLECTION VIEW")
        currentUserAccountsDirty = true
        viewDidLoad()
    }
    
    
}
