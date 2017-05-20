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

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, AddSocialMediaProfileDelegate, SocialMediaCollectionDeletionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, EditSectionDelegate {
  
  enum MenuData: Int {
    case LINKED_PROFILES
    case MY_INFORMATION
    case SOCIAL_ACTIONS
//    case NOTIFICATION_SETTINGS
    case PRIVACY_SETTINGS
    case SUBSCRIPTION_SETTINGS
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

  let LINKED_PROFILES_TITLE = "Linked Profiles"
  let MY_INFORMATION_TITLE = "My Information"
  let SOCIAL_ACTIONS_TITLE = "Discover Friends"
//  let NOTIFICATION_SETTINGS_TITLE = "Notification Settings"
  let PRIVACY_SETTINGS_TITLE = "Privacy Settings"
  let SUBSCRIPTION_SETTINGS_TITLE = "Subscription Settings"
  let ACTIONS_TITLE = "Account Actions"
  
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
  
  //  var fullNameCell: MenuTableViewCell!
  //  var emailCell: MenuTableViewCell!
  //  var phoneCell: MenuTableViewCell!
  
  var isKeyboardShown = false
  var enableEditingArray = Array<Bool>() // Whether or not to enable editing of text fields.
  var hasDeletedProfiles = false
  var buttonViewOriginalFrame : CGRect!
  var socialMediaImageDictionary: Dictionary<String, UIImage>!
  var keyValSocialMediaPairList : Array<KeyValSocialMediaPair>!
  var tableViewSectionsList : Array<SectionTitleAndCountPair>!
  var refreshControl : CustomRefreshControl!
  
  var listOfFBUserIDs = Set<String>()
  var transitionToAddSocialContactsController = false
  // AWS credentials provider
  let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")
  let footerHeight = CGFloat(65)
  let defaultTableViewCellHeight = CGFloat(60)
  let defaultImage = UIImage(imageLiteral: "Person Icon Black")
  let reusableWebViewStoryboard = UIStoryboard(name: "ReusableWebView", bundle: nil)
  
  override func viewDidLoad() {
    
    // Make the profile photo round
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
    
    // Disable editing by default
    enableEditingArray = Array(count: 7, repeatedValue: false)
    
    hasDeletedProfiles = false
    
    // Ensure that the button view is always visible -- in front of the table view
    buttonView.layer.zPosition = 1
    
    // Prevents crash when user attempts to add profiles -- then log out immediately (logOut() called before viewWillDisappear)
    currentUserName = getCurrentCachedUser()
    
    // Set up the data for the table views section. Note: Dictionary does not work for this list as we need a sense of ordering.
    tableViewSectionsList = Array<SectionTitleAndCountPair>()
    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: LINKED_PROFILES_TITLE, sectionCount: 1))
    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: MY_INFORMATION_TITLE, sectionCount: 3))
    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: SOCIAL_ACTIONS_TITLE, sectionCount: 1))
//    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: NOTIFICATION_SETTINGS_TITLE, sectionCount: 1))
    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: PRIVACY_SETTINGS_TITLE, sectionCount: 3))
    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: SUBSCRIPTION_SETTINGS_TITLE, sectionCount: 1))
    tableViewSectionsList.append(SectionTitleAndCountPair(sectionTitle: ACTIONS_TITLE, sectionCount: 2))
    
    
    // Call this function to generate all AWS data for this page!
    generateData()
    
    // Set up refresh control for when user drags for a refresh.
    refreshControl = CustomRefreshControl()
    
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
  
  override func viewDidAppear(animated: Bool) {
    // After FBSDK returns from getting user contacts, we call the segue here in order to prevent warning where
    // one cannot perform sugue due to hierarchy of view controllers
    if transitionToAddSocialContactsController {
      self.performSegueWithIdentifier("toAddSocialContactsViewController", sender: self)
      transitionToAddSocialContactsController = false
    }
    
    awsMobileAnalyticsRecordPageVisitEventTrigger("MenuViewController", forKey: "page_name")
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
  
  /*=======================================================
   * BEGIN : Detect long press on collection view
   =======================================================*/
  func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
    //    if gestureRecognizer.state != UIGestureRecognizerState.Ended {
    //      return
    //    }
    
    // Go to edit mode
//    self.onEditInformationButtonClicked(self)
    self.editSectionButtonClicked(LINKED_PROFILES_TITLE)
  }
  
  /*=======================================================
   * End : Detect long press on collection view
   =======================================================*/
  
  
  @IBAction func onAddSocialMediaProfileButtonClicked(sender: AnyObject) {
    
    // Do this so we don't have any miscrepencies when adding profiles from edit mode
    if enableEditingArray[MenuData.LINKED_PROFILES.rawValue]
    {
      // Mimic a cancellation
//      self.onCancelButtonClicked(self)
      self.cancelSectionButtonClicked(LINKED_PROFILES_TITLE)
    }
  }
  
  @IBAction func goToFollowersPage(sender: AnyObject) {
    showFollowerListViewController("getFollowers")
  }
  
  @IBAction func goToFollowingPage(sender: AnyObject) {
    showFollowerListViewController("getFollowees")
  }
  
  @IBAction func onChangeProfilePictureClicked(sender: UIButton) {
    let imagePicker = UIImagePickerController()    // Used for selecting image from user's device
    
    // Present the Saved Photo Album to user only if it is available
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)
    {
      imagePicker.delegate = self
      imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
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
    
    if !enableEditingArray[MenuData.LINKED_PROFILES.rawValue]
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
      
//      print("enableEditing is: ", enableEditing)
      // Show the delete buttons if in editing mode!
      if (enableEditingArray[MenuData.LINKED_PROFILES.rawValue])
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
      
      if (textField.text?.characters.count == 0)
      {
        textField.text = "+1"
      }
      // Do not let user modify first 2 characters. Right now this is for US phone numbers ("+1")
      else if (range.location < 2)
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
//    case MenuData.NOTIFICATION_SETTINGS.rawValue:
//      returnHeight = CGFloat(50)
//      break;
    case MenuData.PRIVACY_SETTINGS.rawValue:
      returnHeight = CGFloat(50)
      break;
    case MenuData.SUBSCRIPTION_SETTINGS.rawValue:
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
      
      // Add long press gesture recognizer to collection view
      let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MenuController.handleLongPress(_:)))
      lpgr.minimumPressDuration = 0.8
      lpgr.delaysTouchesBegan = true
      lpgr.delegate = self
      cell.profilesCollectionView.addGestureRecognizer(lpgr)
      
      // Show delete buttons if editing is enabled.
      if (enableEditingArray[MenuData.LINKED_PROFILES.rawValue])
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
        cell.menuValue.autocorrectionType = .No
        
        //        self.fullNameCell = cell
        break;
      case MyInformationData.EMAIL.rawValue: //User email
        cell.menuTitle.text = "Email"
        cell.menuValue.text = currentUserEmail
        // Tag is needed so we can detect which text field is being modified later on
        cell.menuValue.tag  = MyInformationData.EMAIL.rawValue
        cell.menuValue.autocorrectionType = .No
        
        //        self.emailCell = cell
        break;
      case MyInformationData.PHONE.rawValue: //User phone
        cell.menuTitle.text = "Phone"
        cell.menuValue.text = currentUserPhone
        
        if currentUserPhone == nil || currentUserPhone.characters.count == 0 {
          cell.clickToAdd.hidden = false
        } else {
          cell.clickToAdd.hidden = true
        }
        
        // Tag is needed so we can detect which text field is being modified later on
        cell.menuValue.tag  = MyInformationData.PHONE.rawValue
        
        
        cell.menuValue.addTarget(self, action: #selector(phoneNumberTextFieldEditingDidChange), forControlEvents: UIControlEvents.EditingChanged)
        cell.menuValue.delegate = self
        cell.menuValue.keyboardType = UIKeyboardType.NumberPad
        cell.menuValue.autocorrectionType = .No
        
        //        self.phoneCell = cell
        break;
        
      default: //Default
        cell.menuTitle.text = ""
        cell.menuValue.text = ""
        
      }
      
      // Set text field editable and display the cool line underneath
      if (enableEditingArray[MenuData.MY_INFORMATION.rawValue])
      {
        cell.menuLineSeparator.hidden = false
        cell.menuValue.enabled = true
        cell.clickToAdd.hidden = true
      }
      else
      {
        cell.menuLineSeparator.hidden = true
        cell.menuValue.enabled = false
        //cell.clickToAdd.hidden = false
      }
      return cell
      break;
    case MenuData.SOCIAL_ACTIONS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
      cell.menuToggleSwitch.hidden = true
      
      switch (indexPath.item)
      {
      case 0: // button
        cell.menuButtonLabel.text = "Find Facebook friends"
        break;
        
      default: //Default
        cell.menuButtonLabel.text = ""
        
      }
      
      return cell
      
      break;
//    case MenuData.NOTIFICATION_SETTINGS.rawValue:
//      // return regular button cell
//      let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
//      cell.menuToggleSwitch.hidden = true
//      
//      switch (indexPath.item)
//      {
//      case 0: // button
//        cell.menuButtonLabel.text = "Coming Soon!"
//        break;
//        
//      default: //Default
//        cell.menuButtonLabel.text = ""
//        
//      }
//      
//      return cell
//      
//      break;
    case MenuData.PRIVACY_SETTINGS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
      cell.menuToggleSwitch.hidden = true
      
      switch (indexPath.item)
      {
      case 0:
        cell.menuButtonLabel.text = "Private Account"
        cell.menuToggleSwitch.hidden = false
        
        let privacyStatus = getCurrentCachedPrivacyStatus()
        if privacyStatus != nil && privacyStatus == "private" {
          cell.menuToggleSwitch.on = true
        } else {
          cell.menuToggleSwitch.on = false
        }
        
        cell.toggleType = MenuButtonTableViewCell.ToggleType.PRIVATE_PROFILE
        
      case 1:
        cell.menuButtonLabel.text = "Privacy Policy"
        break;
      case 2:
        cell.menuButtonLabel.text = "Terms of Service"
        break;
        
      default: //Default
        cell.menuButtonLabel.text = ""
        
      }
      
      return cell
      
      break;
    case MenuData.SUBSCRIPTION_SETTINGS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
      cell.menuToggleSwitch.hidden = true
      
      switch (indexPath.item)
      {
      case 0: //Link to about subscription page
        cell.menuButtonLabel.text = "About Subscription"
        break;
      default: //Default
        cell.menuButtonLabel.text = ""
        
      }
      
      return cell
      
      break;
    case MenuData.ACTIONS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCellWithIdentifier("menuButtonCell") as! MenuButtonTableViewCell!
      cell.menuToggleSwitch.hidden = true
      
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
    
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      cell.editView.hidden = false
      if (enableEditingArray[MenuData.LINKED_PROFILES.rawValue]) {
        cell.cancelSection.hidden = false
        cell.saveSection.hidden = false
        cell.editSection.hidden = true
      }
      
      break;
    case MY_INFORMATION_TITLE:
      cell.editView.hidden = false
      if (enableEditingArray[MenuData.MY_INFORMATION.rawValue]) {
        cell.cancelSection.hidden = false
        cell.saveSection.hidden = false
        cell.editSection.hidden = true
      }
      break;
    default:
      break;
    }
  
    
    cell.editSectionDelegate = self
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    if (indexPath.section == MenuData.MY_INFORMATION.rawValue)
    {
//      self.onEditInformationButtonClicked(self)
      self.editSectionButtonClicked(MY_INFORMATION_TITLE)
    }
    
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
        performSegueWithIdentifier("toAddSocialContactsViewController", sender: self)
        //              getFacebookFriendsUsingApp()
      }
      
    }
    
    if (indexPath.section == MenuData.PRIVACY_SETTINGS.rawValue)
    {
      // Go to privacy page
      if (indexPath.item == 1)
      {
        
        let webDisplayVC = reusableWebViewStoryboard.instantiateViewControllerWithIdentifier("reusableWebViewController") as! ReusableWebViewController
        
        webDisplayVC.webTitle = "Privacy Policy"
        webDisplayVC.webURL = "http://www.aquaint.us/static/privacy-policy"
        self.presentViewController(webDisplayVC, animated: true, completion: nil)
        
      }
      
      // Go to terms of service page
      if (indexPath.item == 2)
      {
        
        let webDisplayVC = reusableWebViewStoryboard.instantiateViewControllerWithIdentifier("reusableWebViewController") as! ReusableWebViewController
        
        webDisplayVC.webTitle = "Terms of Service"
        webDisplayVC.webURL = "http://www.aquaint.us/static/terms-of-service"
        self.presentViewController(webDisplayVC, animated: true, completion: nil)
        
      }
    }
    
    if (indexPath.section == MenuData.SUBSCRIPTION_SETTINGS.rawValue)
    {
      // Go to privacy page
      if (indexPath.item == 0)
      {
        
        let webDisplayVC = reusableWebViewStoryboard.instantiateViewControllerWithIdentifier("reusableWebViewController") as! ReusableWebViewController
        
        webDisplayVC.webTitle = "About Subscription"
        webDisplayVC.webURL = "http://www.aquaint.us/static/about-subscription"
        self.presentViewController(webDisplayVC, animated: true, completion: nil)
        
      }
      
    }
    
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
      
      pool.currentUser()?.signOutAndClearLastKnownUser()
      
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
    self.refreshControl.beginRefreshing()
    generateData()
    
    // Need to end refreshing
    delay(0.5)
    {
      self.refreshControl.endRefreshing()
      print("REFRESH CONTROL!")
      
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
    
    // Check to see whether user has a verified account (i.e. influencer)
    getUserVerifiedData(self.currentUserName, completion: { (result, error) in
      if error == nil && result != nil
      {
        let resultUser = result! as UserVerifiedMinimalObjectModel
        
        if resultUser.isverified != nil && resultUser.isverified == 1 {
          dispatch_async(dispatch_get_main_queue(), { 
            addVerifiedIconToLabel(self.currentUserName, label: self.userNameLabel)
          })
          
        }
        else {
          
        }
        
      }
    })

    
    
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
    //        else if segue.identifier == "toAddSocialContactsViewController"
    //        {
    //          let vc = segue.destinationViewController as! AddSocialContactsViewController
    //          vc.listOfFBUserIDs = self.listOfFBUserIDs
    //        }
    
  }
  
  func showFollowerListViewController(lambdaAction: String) {
    // Let's use a re-usable view just for viewing user follows/followings!
    let storyboard = UIStoryboard(name: "PopUpAlert", bundle: nil)
    let viewController = storyboard.instantiateViewControllerWithIdentifier("AquaintsSingleFollowerListViewController") as! AquaintsSingleFollowerListViewController
    viewController.currentUserName = self.userNameLabel.text
    viewController.lambdaAction = lambdaAction
    viewController.profilePopupView = nil
    
    //    // Fetch VC on top view
    //    var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
    //    while ((topVC!.presentedViewController) != nil) {
    //      topVC = topVC!.presentedViewController
    //    }
    
    // Note: Need to dismiss this popup so we can display another VC. We will restore the popup later,
    // which is why we pass in this class and it's data to the next view controller.
    //    self.dismissPresentingPopup()
    self.presentViewController(viewController, animated: true, completion: nil)
    
  }
  
  func editSectionButtonClicked(sectionTitle: String) {
    // Reload table view so that buttons can be shown as hidden/unhidden
    self.settingsTableView.reloadData()
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      enableEditingArray[MenuData.LINKED_PROFILES.rawValue] = true
  
      // Used to keep track of accounts the user wants to delete or not
      if currentUserAccounts == nil
      {
        oldUserAccounts = nil
      }
      else
      {
        oldUserAccounts = NSMutableDictionary(dictionary: currentUserAccounts as [NSObject : AnyObject], copyItems: true)
      }
      
      break;
    case MY_INFORMATION_TITLE:
      enableEditingArray[MenuData.MY_INFORMATION.rawValue] = true
      realNameTextFieldLabel.performSelector(#selector(becomeFirstResponder))
      break;
    default:
      break;
    }
  }
  
  func cancelSectionButtonClicked(sectionTitle: String) {
    // Reload table view so that buttons can be shown as hidden/unhidden
    self.settingsTableView.reloadData()
    
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      enableEditingArray[MenuData.LINKED_PROFILES.rawValue] = false
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
      break;
    case MY_INFORMATION_TITLE:
      enableEditingArray[MenuData.MY_INFORMATION.rawValue] = false
      break;
    default:
      break;
    }
  }

  
  func saveSectionButtonClicked(sectionTitle: String) {
    // Reload table view so that buttons can be shown as hidden/unhidden
    self.settingsTableView.reloadData()
    
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      enableEditingArray[MenuData.LINKED_PROFILES.rawValue] = false
      
      if self.hasDeletedProfiles
      {
        
        /********************************
         *  UPLOAD USER DATA TO DYNAMODB
         ********************************/
        // Upload user DATA to DynamoDB
        let dynamoDBUser = User()
        
        dynamoDBUser.realname = self.currentRealName
        dynamoDBUser.username = self.currentUserName
        
        // If no current account data, do not upload to dynamo
        // or else it will throw an error.
        if self.currentUserAccounts.count != 0
        {
          dynamoDBUser.accounts = self.currentUserAccounts
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
      
      break;
    case MY_INFORMATION_TITLE:
      enableEditingArray[MenuData.MY_INFORMATION.rawValue] = false
      let fullNameIndexPath = NSIndexPath(forRow: MyInformationData.FULL_NAME.rawValue , inSection: MenuData.MY_INFORMATION.rawValue)
      let emailIndexPath = NSIndexPath(forRow: MyInformationData.EMAIL.rawValue, inSection: MenuData.MY_INFORMATION.rawValue)
      let phoneIndexPath = NSIndexPath(forRow: MyInformationData.PHONE.rawValue, inSection: MenuData.MY_INFORMATION.rawValue)
      
      
      let fullNameCellTemp = self.settingsTableView.cellForRowAtIndexPath(fullNameIndexPath)
      let emailCellTemp = self.settingsTableView.cellForRowAtIndexPath(emailIndexPath)
      let phoneCellTemp = self.settingsTableView.cellForRowAtIndexPath(phoneIndexPath)
      
      
      if fullNameCellTemp == nil || emailCellTemp == nil || phoneCellTemp == nil {
        
//        delay(0.5) {
//          self.saveSectionButtonClicked(sectionTitle)
//        }
        return
      }
      
      
      let fullNameCell = fullNameCellTemp as! MenuTableViewCell
      let emailCell = emailCellTemp as! MenuTableViewCell
      let phoneCell = phoneCellTemp as! MenuTableViewCell
      
      // If modified data, adjust accordingly!
      if self.editedRealName != nil && !self.editedRealName.isEmpty
      {
        if (!verifyRealNameLength(self.editedRealName!))
        {
          showAlert("Improper full name format", message: "Please create a full name that is less than 30 characters long!", buttonTitle: "Try again", sender: self)
          self.editedRealName = fullNameCell.menuValue.text
          return
        }
      }
      else if self.editedRealName != nil && self.editedRealName.isEmpty
      {
        showAlert("Improper full name format", message: "Please create a full name that is at least 1 character!", buttonTitle: "Try again", sender: self)
        
        self.editedRealName = fullNameCell.menuValue.text
        return
        
      }
      
      if self.editedUserEmail != nil && !self.editedUserEmail.isEmpty
      {
        if (!verifyEmailFormat(self.editedUserEmail!))
        {
          showAlert("Improper email address", message: "Please enter in a proper email address!", buttonTitle: "Try again", sender: self)
          self.editedUserEmail = emailCell.menuValue.text
          return
        }
        
      }
      else if self.editedUserEmail != nil && self.editedUserEmail.isEmpty
      {
        showAlert("Improper email address", message: "Please enter in an email address!", buttonTitle: "Try again", sender: self)
        self.editedUserEmail = emailCell.menuValue.text
        return
      }
      
      
      if self.editedUserPhone != nil && !self.editedUserPhone.isEmpty
      {
        // Get the text from the beginning of the phone number (not US country code)
        let string = self.editedUserPhone as NSString
        let phoneString = string.substringFromIndex(2)
        
        if !verifyPhoneFormat(phoneString)
        {
          showAlert("Improper phone number", message: "Please enter in a proper U.S. phone number.", buttonTitle: "Try again", sender: self)
          self.editedUserPhone = phoneCell.menuValue.text
          return
        }
        
        
      }
      
      // ADD CHANGE TO USERPOOLS (email/phone only)
      let userPool = getAWSCognitoIdentityUserPool()
      let email = AWSCognitoIdentityUserAttributeType()
      let phone = AWSCognitoIdentityUserAttributeType()
      email.name = "email"
      phone.name = "phone_number"
      
      if self.editedUserEmail != nil && self.editedUserEmail != self.currentUserEmail
      {
        // Update user pools with currentUserPhone
        emailCell.menuValue.text = self.editedUserEmail
        self.currentUserEmail = self.editedUserEmail
        
        email.value = self.currentUserEmail
        phone.value = self.currentUserPhone
        
        
        userPool.getUser(self.currentUserName).updateAttributes([email, phone]).continueWithSuccessBlock { (resultTask) -> AnyObject? in
          
          print("SUCCESSFUL USER EMAIL UPDATE IN USERPOOLS")
          return nil
        }
        
      }
      
      if self.editedUserPhone != nil && self.editedUserPhone != self.currentUserPhone
      {
        // In case we need to revert changes -- if user cannot verify
        let oldPhoneNum = self.currentUserPhone
        
        phoneCell.clickToAdd.hidden = true
        
        // Update user pools with currentUserEmail
        phoneCell.menuValue.text = self.editedUserPhone
        self.currentUserPhone = self.editedUserPhone
        
        email.value = self.currentUserEmail
        phone.value = self.currentUserPhone
        
        userPool.getUser(self.currentUserName).updateAttributes([email, phone]).continueWithSuccessBlock { (resultTask) -> AnyObject? in
          
          
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
      if self.editedRealName != nil
      {
        fullNameCell.menuValue.text = self.editedRealName
        self.currentRealName = self.editedRealName
        
        // Change name at top of page, too
        self.realNameTextFieldLabel.text = self.currentRealName
        
        print ("UPDATING REALNAME IN DYNAMO AND LAMBDA")
        
        /********************************
         *  UPLOAD USER DATA TO DYNAMODB
         ********************************/
        // Upload user DATA to DynamoDB
        let dynamoDBUser = User()
        
        dynamoDBUser.realname = self.currentRealName
        dynamoDBUser.username = self.currentUserName
        
        if self.currentUserAccounts != nil && self.currentUserAccounts.count != 0
        {
          dynamoDBUser.accounts = self.currentUserAccounts
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
        let parameters = ["action":"updatern", "target": self.currentUserName, "realname": self.currentRealName]
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
        
        // Clear the edited results
        self.editedRealName = nil
        self.editedUserEmail = nil
        self.editedUserPhone = nil
        
        
        print("full name modified is:", fullNameCell.menuValue.text)
        print("email data modified is:", emailCell.menuValue.text)
        print("phone data modified is:", phoneCell.menuValue.text)
      }

      break;
    default:
      break;
    }
    
  }
  
  
}


