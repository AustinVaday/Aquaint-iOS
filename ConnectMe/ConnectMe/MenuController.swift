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


class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    enum MenuData: Int {
        case LINKED_PROFILES
        case MY_INFORMATION
        case NOTIFICATION_SETTINGS
        case PRIVACY_SETTINGS
        case ACTIONS
    }
    
    // The dictionary we receive from AWS DynamoDB maps a string to an array.
    // When we have a collection view, we need a way to propogate this 
    // datastructure linearly, because we're given indices based on
    // how many usernames we have. A solution to this is using  
    // an array of structs to keep tabs on what social media type we have
    // and what the respective username is.
    struct KeyValSocialMediaPair
    {
        var socialMediaType : String!       // i.e. "Facebook"
        var socialMediaUserName : String!   // i.e. "austinvaday"
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
    
    var isKeyboardShown = false
    var enableEditing = false // Whether or not to enable editing of text fields.
    
    var buttonViewOriginalFrame : CGRect!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var keyValSocialMediaPairList : Array<KeyValSocialMediaPair>!
    
    var tableViewSectionsList : Array<SectionTitleAndCountPair>!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)

    // AWS credentials provider
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
    
    let footerHeight = CGFloat(65)
    let defaultTableViewCellHeight = CGFloat(60)

    override func viewDidLoad() {
        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Disable editing by default
        enableEditing = false
        
 
        
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
        tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: "Actions", sectionCount: 1))
        
        
        // Initialize array so that collection view has something to check while we
        // fetch data from dynamo
        keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
        
        print("CUR USERNAME: ", currentUserName)
        
        
        // If any values are nil, we need to re-cache
        if (currentRealName == nil ||
            currentUserImage == nil ||
            currentUserAccounts == nil ||
            currentUserEmail == nil ||
            currentUserPhone == nil)
        {
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
        numFollowersLabel.text = "200"
        
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
            self.keyValSocialMediaPairList = self.convertDictionaryToSocialMediaKeyValPairList(self.socialMediaUserNames, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
            
            
            // Perform update on UI on main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // Propogate collection view with new data
                self.settingsTableView.reloadData()
                
                print("RELOADING COLLECTIONVIEW")
            })
        }

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
        
        let fullNameIndexPath = NSIndexPath(forRow: 0, inSection: MenuData.MY_INFORMATION.rawValue)
        let emailIndexPath = NSIndexPath(forRow: 1, inSection: MenuData.MY_INFORMATION.rawValue)
        let phoneIndexPath = NSIndexPath(forRow: 2, inSection: MenuData.MY_INFORMATION.rawValue)

        
        let fullNameCell = settingsTableView.cellForRowAtIndexPath(fullNameIndexPath) as! MenuTableViewCell
        let emailCell = settingsTableView.cellForRowAtIndexPath(emailIndexPath) as! MenuTableViewCell
        let phoneCell = settingsTableView.cellForRowAtIndexPath(phoneIndexPath) as! MenuTableViewCell

        delay(3)
        {
        print("full name data is:", fullNameCell.menuValue.text)
        print("email data is:", emailCell.menuValue.text)
        print("phone data is:", phoneCell.menuValue.text)
        
        
        self.enableEditing = false
        self.settingsTableView.reloadData()
        
        // Show the edit button again
        self.editButton.hidden = false
        self.cancelButton.hidden = true
        self.saveButton.hidden = true
        }
        
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
            return cell
            break;
        case MenuData.MY_INFORMATION.rawValue:
            //else return regular cell
            let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
            
            switch (indexPath.item)
            {
            case 0: //User full name
                cell.menuTitle.text = "Full Name"
                cell.menuValue.text = currentRealName
                break;
            case 1: //User email
                cell.menuTitle.text = "Email"
                cell.menuValue.text = currentUserEmail
                break;
            case 2: //User phone
                cell.menuTitle.text = "Phone"
                cell.menuValue.text = currentUserPhone
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
            case 0: //Log out button
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
            case 0: //Log out button
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
            
            // Log out button
            if (indexPath.item == 0)
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
    
    // Private helper functions
    //---------------------------------------------------------------------------------------------------
    private func convertDictionaryToSocialMediaKeyValPairList(dict: NSMutableDictionary,
                                                              possibleSocialMediaNameList: Array<String>)
                                                                -> Array<KeyValSocialMediaPair>!
    {
        
        var pairList = Array<KeyValSocialMediaPair>()
        
        // dict is a dictionary that maps a social media name (i.e. facebook) to every
        // single username that the user has for that social media type. We need to find how many
        // total there are
        for socialMediaName in possibleSocialMediaNameList
        {
            // need to check if user has respective social media type first
            if (dict[socialMediaName] != nil)
            {
                // Get a list of usernames for just one social media type (i.e. all usernames for facebook)
                let socialMediaUserNamesList = dict[socialMediaName] as! Array<String>
                
                for username in socialMediaUserNamesList
                {
                    let pair = KeyValSocialMediaPair(socialMediaType: socialMediaName, socialMediaUserName: username)
                    pairList.append(pair)
                }
            }
        }
        
        return pairList
        
    }
    
    

    
    
    
    // UNWIND SEGUES
    @IBAction func unwindBackToMenuVC(segue:UIStoryboardSegue)
    {
        print("Success unwind to menu VC")
        print("REFRESH COLLECTION VIEW")
        viewDidLoad()
    }
    
    
}
