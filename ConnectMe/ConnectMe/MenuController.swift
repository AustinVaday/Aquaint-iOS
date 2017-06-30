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
import RSKImageCropper

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, AddSocialMediaProfileDelegate, SocialMediaCollectionDeletionDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, EditSectionDelegate {
  
  enum MenuData: Int {
    case linked_PROFILES
    case my_INFORMATION
    case social_ACTIONS
//    case NOTIFICATION_SETTINGS
    case privacy_SETTINGS
    case subscription_SETTINGS
    case actions
  }
  
  enum MyInformationData: Int {
    case full_NAME
    case email
    case phone
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
  let defaultImage = UIImage(imageLiteralResourceName: "Person Icon Black")
  let reusableWebViewStoryboard = UIStoryboard(name: "ReusableWebView", bundle: nil)
  
  override func viewDidLoad() {
    
    // Make the profile photo round
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
    
    // Disable editing by default
    enableEditingArray = Array(repeating: false, count: 7)
    
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
    refreshControl.addTarget(self, action: #selector(MenuController.refreshTable(_:)), for: UIControlEvents.valueChanged)
    settingsTableView.addSubview(refreshControl)
    
  }
  
  /*=======================================================
   * BEGIN : Keyboard/Button Animations
   =======================================================*/
  
  // Add and Remove NSNotifications!
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    
    registerForKeyboardNotifications()
    
    // Set up datastructure for newsfeed.. If this is not reset
    // in viewWillAppear, then we'll keep uploading the same info to dynamo
    newUserAccountsForNewsfeed = NSMutableDictionary()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(true)
    
    deregisterForKeyboardNotifications()
    
    // When the view disappears, upload action data to Dynamo (used for the newsfeed)
    print ("You will be uploading this data to dynamo: ", self.newUserAccountsForNewsfeed)
    
    if self.newUserAccountsForNewsfeed.count != 0
    {
      // Here's what we'll do: When the user leaves this page, we will take the recent additions (100 max)
      // and store them in dynamo. This information will be used for the newsfeed.
      let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
      
      // Get dynamo mapper if it exists
      dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: currentUserName, rangeKey: nil).continue({ (resultTask) -> AnyObject? in
        
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
        
        dynamoDBObjectMapper.save(newsfeedObjectMapper).continue { (resultTask) -> AnyObject? in
          print("DynamoObjectMapper sucessful save for newsfeedObject with new social media profile")
          
          return nil
        }
        
        
        
        return nil
      })
      
    }
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    // After FBSDK returns from getting user contacts, we call the segue here in order to prevent warning where
    // one cannot perform sugue due to hierarchy of view controllers
    if transitionToAddSocialContactsController {
      self.performSegue(withIdentifier: "toAddSocialContactsViewController", sender: self)
      transitionToAddSocialContactsController = false
    }
    
    awsMobileAnalyticsRecordPageVisitEventTrigger("MenuViewController", forKey: "page_name")
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
    // If keyboard shown already, no need to perform this method
    if isKeyboardShown
    {
      return
    }
    
    self.isKeyboardShown = true
    
    let userInfo = notification.userInfo!
    let keyboardSize = ((userInfo[UIKeyboardFrameBeginUserInfoKey])! as AnyObject).cgRectValue.size
    
    UIView.animate(withDuration: 0.5, animations: {
      
      print("KEYBOARD SHOWN")
      
      self.buttonBottomConstraint.constant = keyboardSize.height - self.footerHeight
      self.view.layoutIfNeeded()
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
  
  /*=======================================================
   * BEGIN : Detect long press on collection view
   =======================================================*/
  func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
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
  
  
  @IBAction func onAddSocialMediaProfileButtonClicked(_ sender: AnyObject) {
    
    // Do this so we don't have any miscrepencies when adding profiles from edit mode
    if enableEditingArray[MenuData.linked_PROFILES.rawValue]
    {
      // Mimic a cancellation
//      self.onCancelButtonClicked(self)
      self.cancelSectionButtonClicked(LINKED_PROFILES_TITLE)
    }
  }
  
  @IBAction func goToFollowersPage(_ sender: AnyObject) {
    showFollowerListViewController("getFollowers")
  }
  
  @IBAction func goToFollowingPage(_ sender: AnyObject) {
    showFollowerListViewController("getFollowees")
  }
  
  @IBAction func onChangeProfilePictureClicked(_ sender: UIButton) {
    let imagePicker = UIImagePickerController()    // Used for selecting image from user's device
    
    // Present the Saved Photo Album to user only if it is available
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
    {
      imagePicker.delegate = self
      imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
      imagePicker.allowsEditing = false
      self.present(imagePicker, animated: true, completion: nil)
    }
    
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
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
    setUserS3Image(currentUserName, userImage: croppedImage) { (error) in
      
      // Perform update on UI on main thread
      DispatchQueue.main.async(execute: { () -> Void in
        if error != nil
        {
          showAlert("Sorry", message: "Something went wrong, we couldn't upload the photo right now. Please try again later.", buttonTitle: "Ok", sender: self)
        }
        else
        {
          self.profileImageView.image = croppedImage
        }
      })
    }

    
  }
  
  
  
  @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
    
    switch (sender.tag)
    {
    case MyInformationData.full_NAME.rawValue:
      editedRealName = sender.text!
      break;
    case MyInformationData.email.rawValue:
      editedUserEmail = sender.text!
      break;
    case MyInformationData.phone.rawValue:
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
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if (keyValSocialMediaPairList.isEmpty)
    {
      return 0
    }
    
    print ("NUM KEYVALSOCIALMEDIAPAR IN LIST: ", keyValSocialMediaPairList.count)
    return keyValSocialMediaPairList.count
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    if !enableEditingArray[MenuData.linked_PROFILES.rawValue]
    {
      let cell = collectionView.cellForItem(at: indexPath) as! SocialMediaCollectionViewCell
      
      print ("SELECTED", cell.socialMediaName)
      
      let socialMediaUserName = cell.socialMediaName
      let socialMediaType = cell.socialMediaType
      
      let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)
      
      // Perform the request, go to external application and let the user do whatever they want!
      if socialMediaURL != nil
      {
        UIApplication.shared.openURL(socialMediaURL)
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "accountsCollectionViewCell", for: indexPath) as! SocialMediaCollectionViewCell
    
    if (!keyValSocialMediaPairList.isEmpty)
    {
      let socialMediaPair = keyValSocialMediaPairList[indexPath.item % keyValSocialMediaPairList.count]
      let socialMediaType = socialMediaPair.socialMediaType
      let socialMediaUserName = socialMediaPair.socialMediaUserName
      
      
      // Generate a UI image for the respective social media type
      cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType!]
      
      cell.socialMediaName = socialMediaUserName // username
      cell.socialMediaType = socialMediaType // facebook, snapchat, etc
      
      cell.delegate = self
      
//      print("enableEditing is: ", enableEditing)
      // Show the delete buttons if in editing mode!
      if (enableEditingArray[MenuData.linked_PROFILES.rawValue])
      {
        cell.deleteSocialMediaButton.isHidden = false
      }
      else
      {
        cell.deleteSocialMediaButton.isHidden = true
      }
      
      // Make cell image circular
      //            cell.layer.cornerRadius = cell.frame.width / 2
      cell.emblemImage.layer.cornerRadius = cell.emblemImage.frame.width / 2
    }
    
    return cell
  }
  
  // Used for polishing phone number in table view
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if textField.tag == MyInformationData.phone.rawValue
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
  
  func phoneNumberTextFieldEditingDidChange(_ textField: UITextField)
  {
    // Get the text from the beginning of the phone number (not US country code)
    let string = (textField.text)! as NSString
    let phoneString = string.substring(from: 2)
    
    textField.text = "+1" + removeAllNonDigits(phoneString)
    
    
  }
  
  /**************************************************************************
   *    TABLE VIEW PROTOCOL
   **************************************************************************/
  // Specify number of sections in our table
  func numberOfSections(in tableView: UITableView) -> Int {
    
    // Return number of sections
    return tableViewSectionsList.count
  }
  
  // Specify height of header
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 48
  }
  
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
    return tableViewSectionsList[section].sectionTitle
  }
  
  // Specify height of table view cells
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
    var returnHeight : CGFloat!
    
    switch indexPath.section
    {
    case MenuData.linked_PROFILES.rawValue:
      returnHeight = defaultTableViewCellHeight
      break;
    case MenuData.social_ACTIONS.rawValue:
      returnHeight = CGFloat(50)
      break;
    case MenuData.my_INFORMATION.rawValue:
      returnHeight = defaultTableViewCellHeight
      break;
//    case MenuData.NOTIFICATION_SETTINGS.rawValue:
//      returnHeight = CGFloat(50)
//      break;
    case MenuData.privacy_SETTINGS.rawValue:
      returnHeight = CGFloat(50)
      break;
    case MenuData.subscription_SETTINGS.rawValue:
      returnHeight = CGFloat(50)
      break;
    case MenuData.actions.rawValue:
      returnHeight = CGFloat(50)
      break;
      
    default:
      returnHeight = defaultTableViewCellHeight
    }
    
    return returnHeight
  }
  
  // Return the number of rows in each given section
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return tableViewSectionsList[section].sectionCount
  }
  
  // Configure which cell to display
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    switch indexPath.section
    {
    case MenuData.linked_PROFILES.rawValue:
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuProfilesCell") as! MenuProfilesCell!
    
      cell?.profilesCollectionView.reloadData()
      
      // Add long press gesture recognizer to collection view
      let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MenuController.handleLongPress(_:)))
      lpgr.minimumPressDuration = 0.8
      lpgr.delaysTouchesBegan = true
      lpgr.delegate = self
      cell?.profilesCollectionView.addGestureRecognizer(lpgr)
      
      // Show delete buttons if editing is enabled.
      if (enableEditingArray[MenuData.linked_PROFILES.rawValue])
      {
        //TODO: Red delete buttons
      }
      
      return cell!
      break;
    case MenuData.my_INFORMATION.rawValue:
      //else return regular cell
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell") as! MenuTableViewCell!
      
      switch (indexPath.item)
      {
      case MyInformationData.full_NAME.rawValue: //User full name
        cell?.menuTitle.text = "Full Name"
        cell?.menuValue.text = currentRealName
        // Tag is needed so we can detect which text field is being modified later on
        cell?.menuValue.tag  = MyInformationData.full_NAME.rawValue
        cell?.menuValue.autocorrectionType = .no
        
        //        self.fullNameCell = cell
        break;
      case MyInformationData.email.rawValue: //User email
        cell?.menuTitle.text = "Email"
        cell?.menuValue.text = currentUserEmail
        // Tag is needed so we can detect which text field is being modified later on
        cell?.menuValue.tag  = MyInformationData.email.rawValue
        cell?.menuValue.autocorrectionType = .no
        
        //        self.emailCell = cell
        break;
      case MyInformationData.phone.rawValue: //User phone
        cell?.menuTitle.text = "Phone"
        cell?.menuValue.text = currentUserPhone
        
        if currentUserPhone == nil || currentUserPhone.characters.count == 0 {
          cell?.clickToAdd.isHidden = false
        } else {
          cell?.clickToAdd.isHidden = true
        }
        
        // Tag is needed so we can detect which text field is being modified later on
        cell?.menuValue.tag  = MyInformationData.phone.rawValue
        
        
        cell?.menuValue.addTarget(self, action: #selector(phoneNumberTextFieldEditingDidChange), for: UIControlEvents.editingChanged)
        cell?.menuValue.delegate = self
        cell?.menuValue.keyboardType = UIKeyboardType.numberPad
        cell?.menuValue.autocorrectionType = .no
        
        //        self.phoneCell = cell
        break;
        
      default: //Default
        cell?.menuTitle.text = ""
        cell?.menuValue.text = ""
        
      }
      
      // Set text field editable and display the cool line underneath
      if (enableEditingArray[MenuData.my_INFORMATION.rawValue])
      {
        cell?.menuLineSeparator.isHidden = false
        cell?.menuValue.isEnabled = true
        cell?.clickToAdd.isHidden = true
      }
      else
      {
        cell?.menuLineSeparator.isHidden = true
        cell?.menuValue.isEnabled = false
        //cell.clickToAdd.hidden = false
      }
      return cell!
      break;
    case MenuData.social_ACTIONS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuButtonCell") as! MenuButtonTableViewCell!
      cell?.menuToggleSwitch.isHidden = true
      
      switch (indexPath.item)
      {
      case 0: // button
        cell?.menuButtonLabel.text = "Find Facebook friends"
        break;
        
      default: //Default
        cell?.menuButtonLabel.text = ""
        
      }
      
      return cell!
      
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
    case MenuData.privacy_SETTINGS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuButtonCell") as! MenuButtonTableViewCell!
      cell?.menuToggleSwitch.isHidden = true
      
      switch (indexPath.item)
      {
      case 0:
        cell?.menuButtonLabel.text = "Private Account"
        cell?.menuToggleSwitch.isHidden = false
        
        let privacyStatus = getCurrentCachedPrivacyStatus()
        if privacyStatus != nil && privacyStatus == "private" {
          cell?.menuToggleSwitch.isOn = true
        } else {
          cell?.menuToggleSwitch.isOn = false
        }
        
        cell?.toggleType = MenuButtonTableViewCell.ToggleType.private_PROFILE
        
      case 1:
        cell?.menuButtonLabel.text = "Privacy Policy"
        break;
      case 2:
        cell?.menuButtonLabel.text = "Terms of Service"
        break;
        
      default: //Default
        cell?.menuButtonLabel.text = ""
        
      }
      
      return cell!
      
      break;
    case MenuData.subscription_SETTINGS.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuButtonCell") as! MenuButtonTableViewCell!
      cell?.menuToggleSwitch.isHidden = true
      
      switch (indexPath.item)
      {
      case 0: //Link to about subscription page
        cell?.menuButtonLabel.text = "About Subscription"
        break;
      default: //Default
        cell?.menuButtonLabel.text = ""
        
      }
      
      return cell!
      
      break;
    case MenuData.actions.rawValue:
      // return regular button cell
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuButtonCell") as! MenuButtonTableViewCell!
      cell?.menuToggleSwitch.isHidden = true
      
      switch (indexPath.item)
      {
      case 0:
        cell?.menuButtonLabel.text = "Change Password"
        break;
      case 1: //Log out button
        cell?.menuButtonLabel.text = "Log Out"
        break;
      default: //Default
        cell?.menuButtonLabel.text = ""
        
      }
      
      return cell!
      break;
    default:
      // Default cell return..
      let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell") as! MenuTableViewCell!
      return cell!
      
    }
  }
  
  // Configure/customize each table header view
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    let sectionTitle = tableViewSectionsList[section].sectionTitle
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "sectionHeaderCell") as! SectionHeaderCell!
  
    cell?.sectionTitle.text = sectionTitle
    
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      cell?.editView.isHidden = false
      if (enableEditingArray[MenuData.linked_PROFILES.rawValue]) {
        cell?.cancelSection.isHidden = false
        cell?.saveSection.isHidden = false
        cell?.editSection.isHidden = true
      }
      
      break;
    case MY_INFORMATION_TITLE:
      cell?.editView.isHidden = false
      if (enableEditingArray[MenuData.my_INFORMATION.rawValue]) {
        cell?.cancelSection.isHidden = false
        cell?.saveSection.isHidden = false
        cell?.editSection.isHidden = true
      }
      break;
    default:
      break;
    }
  
    
    cell?.editSectionDelegate = self
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if (indexPath.section == MenuData.my_INFORMATION.rawValue)
    {
//      self.onEditInformationButtonClicked(self)
      self.editSectionButtonClicked(MY_INFORMATION_TITLE)
    }
    
    if (indexPath.section == MenuData.actions.rawValue)
    {
      // Reset password button
      if (indexPath.item == 0)
      {
        performSegue(withIdentifier: "toResetPasswordViewController", sender: self)
      }
      
      // Log out button
      if (indexPath.item == 1)
      {
        logUserOut()
      }
    }
    
    if (indexPath.section == MenuData.social_ACTIONS.rawValue)
    {
      // Find facebook friends to follow button
      if (indexPath.item == 0)
      {
        performSegue(withIdentifier: "toAddSocialContactsViewController", sender: self)
        //              getFacebookFriendsUsingApp()
      }
      
    }
    
    if (indexPath.section == MenuData.privacy_SETTINGS.rawValue)
    {
      // Go to privacy page
      if (indexPath.item == 1)
      {
        
        let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
        
        webDisplayVC.webTitle = "Privacy Policy"
        webDisplayVC.webURL = "http://www.aquaint.us/static/privacy-policy"
        webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(webDisplayVC, animated: true, completion: nil)
        
      }
      
      // Go to terms of service page
      if (indexPath.item == 2)
      {
        
        let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
        
        webDisplayVC.webTitle = "Terms of Service"
        webDisplayVC.webURL = "http://www.aquaint.us/static/terms-of-service"
        webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(webDisplayVC, animated: true, completion: nil)
        
      }
    }
    
    if (indexPath.section == MenuData.subscription_SETTINGS.rawValue)
    {
      // Go to privacy page
      if (indexPath.item == 0)
      {
        
        let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
        
        webDisplayVC.webTitle = "About Subscription"
        webDisplayVC.webURL = "http://www.aquaint.us/static/about-subscription"
        webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(webDisplayVC, animated: true, completion: nil)
        
      }
      
    }
    
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  
  func logUserOut()
  {
    
    // Ask user if they really want to log out...
    let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.alert)
    
    let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.default) { (UIAlertAction) -> Void in
      
      // present the log in home page
      
      //TODO: Add spinner functionality
      self.performSegue(withIdentifier: "logOut", sender: nil)
      
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
      self.credentialsProvider.getIdentityId().continue { (resultTask) -> AnyObject? in
        
        print("LOGOUT, identity id is:", resultTask.result)
        print("LOG2, ", self.credentialsProvider.identityId)
        return nil
      }
      
      
      
      // Clear local cache and user identity
      clearUserDefaults()
      
      
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil)
    
    alert.addAction(logOutAction)
    alert.addAction(cancelAction)
    
    self.show(alert, sender: nil)
    
  }
  
  /*************************************************************************
   *    SELF-DEFINED DATA TRANSFER PROTOCOL
   **************************************************************************/
  func userDidAddNewProfile(_ socialMediaType: String, socialMediaName: String) {
    
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
        if self.newUserAccountsForNewsfeed.value(forKey: socialMediaType) == nil
        {
          self.newUserAccountsForNewsfeed.setValue([ socialMediaName ], forKey: socialMediaType)
        }
        else // If the key already exists
        {
          var list = self.newUserAccountsForNewsfeed.value(forKey: socialMediaType) as! Array<String>
          list.append(socialMediaName)
          self.newUserAccountsForNewsfeed.setValue(list, forKey: socialMediaType)
        }
        
        print("Adding new profile [", socialMediaType, ":", socialMediaName, " to newUserAccountsForNewsfeed.")
        print ("New list is: ", self.newUserAccountsForNewsfeed)
        
        // Perform update on UI on main thread
        DispatchQueue.main.async(execute: { () -> Void in
          
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
  
  func userDidDeleteSocialMediaProfile(_ socialMediaType: String, socialMediaName: String) {
    
    print("OK! time to delete ", socialMediaType, " --> ", socialMediaName)
    hasDeletedProfiles = true
    
    // Delete account from local list. If user hits success button -- save changes
    if currentUserAccounts.value(forKey: socialMediaType) != nil
    {
      var list = currentUserAccounts.object(forKey: socialMediaType) as! Array<String>
      
      // Update list as to remove this specific value
      list.remove(at: list.index(of: socialMediaName)!)
      
      // If nothing in list, we need to delete the key
      if list.count == 0
      {
        currentUserAccounts.removeObject(forKey: socialMediaType)
      }
      else
      {
        currentUserAccounts.setValue(list, forKey: socialMediaType)
      }
      
      keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(currentUserAccounts)
      settingsTableView.reloadData()
      
    }
    
    // Delete account from newsfeed object as well
    if newUserAccountsForNewsfeed.value(forKey: socialMediaType) != nil
    {
      if newUserAccountsForNewsfeed.value(forKey: socialMediaType) != nil
      {
        var list = newUserAccountsForNewsfeed.value(forKey: socialMediaType) as! Array<String>
        
        if list.index(of: socialMediaName) != nil
        {
          // Update list as to remove this specific value
          list.remove(at: list.index(of: socialMediaName)!)
          
          // If nothing in list, we need to delete the key
          if list.count == 0
          {
            newUserAccountsForNewsfeed.removeObject(forKey: socialMediaType)
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
  func refreshTable(_ sender:AnyObject)
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
  
  fileprivate func generateData()
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
      DispatchQueue.main.async(execute: { () -> Void in
        
        // Propogate collection view with new data
        self.settingsTableView.reloadData()
        
        print("RELOADING COLLECTIONVIEW")
      })
    }
    
    // Fetch num followers from lambda
    let lambdaInvoker = AWSLambdaInvoker.default()
    var parameters = ["action":"getNumFollowers", "target": currentUserName]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
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
        DispatchQueue.main.async(execute: { () -> Void in
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
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
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
        DispatchQueue.main.async(execute: { () -> Void in
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
          DispatchQueue.main.async(execute: { 
            addVerifiedIconToLabel(self.currentUserName, label: self.userNameLabel, size: 12)
          })
          
        }
        else {
          
        }
        
      }
    })

    
    
  }
  
  fileprivate func updateProfilesDynamoDB(_ currentAccounts: NSMutableDictionary)
  {
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    let currentUser = getCurrentCachedUser()
    let currentRealName = getCurrentCachedFullName()
    
    
    // Upload user DATA to DynamoDB
    let dynamoDBUser = User()
    
    dynamoDBUser?.username = currentUser
    dynamoDBUser?.realname = currentRealName
    dynamoDBUser?.accounts = currentAccounts
    
    dynamoDBObjectMapper.save(dynamoDBUser!).continue({ (resultTask) -> AnyObject? in
      
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
  
  
  fileprivate func showVerificationPopup(_ completion: @escaping (_ result:String?)->())
  {
    var alertViewResponder: SCLAlertViewResponder!
    let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 70))
    let x = (subview.frame.width - 180) / 2
    let colorDarkBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
    
    // Add text field for username
    let textField = UITextField(frame: CGRect(x: x,y: 10,width: 180,height: 25))
    
    //            textField.layer.borderColor = colorLightBlue.CGColor
    //            textField.layer.borderWidth = 1.5
    //            textField.layer.cornerRadius = 5
    textField.font = UIFont(name: "Avenir Roman", size: 14.0)
    textField.textColor = colorDarkBlue
    textField.placeholder = "Enter Verification Code"
    textField.textAlignment = NSTextAlignment.center
    
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
  @IBAction func unwindBackToMenuVC(_ segue:UIStoryboardSegue)
  {
    print("Success unwind to menu VC")
    //        print("REFRESH COLLECTION VIEW")
    //        currentUserAccountsDirty = true
    //        viewDidLoad()
    
    // request permission for sending Push Notifications when user finishes signing up
    askUserForPushNotificationPermission(self)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "segueToAddSocialMediaProfilesController"
    {
      // Need to set delegate so that we can fetch which data user added in
      let vc = segue.destination as! AddSocialMediaProfilesController
      vc.delegate = self
    }
    //        else if segue.identifier == "toAddSocialContactsViewController"
    //        {
    //          let vc = segue.destinationViewController as! AddSocialContactsViewController
    //          vc.listOfFBUserIDs = self.listOfFBUserIDs
    //        }
    
  }
  
  func showFollowerListViewController(_ lambdaAction: String) {
    // Let's use a re-usable view just for viewing user follows/followings!
    let storyboard = UIStoryboard(name: "PopUpAlert", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "AquaintsSingleFollowerListViewController") as! AquaintsSingleFollowerListViewController
    viewController.currentUserName = self.currentUserName
    viewController.lambdaAction = lambdaAction
    viewController.profilePopupView = nil
    viewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    
    //    // Fetch VC on top view
    //    var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
    //    while ((topVC!.presentedViewController) != nil) {
    //      topVC = topVC!.presentedViewController
    //    }
    
    // Note: Need to dismiss this popup so we can display another VC. We will restore the popup later,
    // which is why we pass in this class and it's data to the next view controller.
    //    self.dismissPresentingPopup()
    self.present(viewController, animated: true, completion: nil)
    
  }
  
  func editSectionButtonClicked(_ sectionTitle: String) {
    // Reload table view so that buttons can be shown as hidden/unhidden
    self.settingsTableView.reloadData()
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      enableEditingArray[MenuData.linked_PROFILES.rawValue] = true
  
      // Used to keep track of accounts the user wants to delete or not
      if currentUserAccounts == nil
      {
        oldUserAccounts = nil
      }
      else
      {
        oldUserAccounts = NSMutableDictionary(dictionary: currentUserAccounts as! [AnyHashable: Any], copyItems: true)
      }
      
      break;
    case MY_INFORMATION_TITLE:
      enableEditingArray[MenuData.my_INFORMATION.rawValue] = true
      realNameTextFieldLabel.perform(#selector(becomeFirstResponder))
      break;
    default:
      break;
    }
  }
  
  func cancelSectionButtonClicked(_ sectionTitle: String) {
    // Reload table view so that buttons can be shown as hidden/unhidden
    self.settingsTableView.reloadData()
    
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      enableEditingArray[MenuData.linked_PROFILES.rawValue] = false
      // Reset any modified user accounts (profiles)
      if oldUserAccounts == nil
      {
        currentUserAccounts = nil
      }
      else
      {
        currentUserAccounts = NSMutableDictionary(dictionary: oldUserAccounts as! [AnyHashable: Any], copyItems: true)
      }
      keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(currentUserAccounts)
      self.settingsTableView.reloadData()
      break;
    case MY_INFORMATION_TITLE:
      enableEditingArray[MenuData.my_INFORMATION.rawValue] = false
      break;
    default:
      break;
    }
  }

  
  func saveSectionButtonClicked(_ sectionTitle: String) {
    // Reload table view so that buttons can be shown as hidden/unhidden
    self.settingsTableView.reloadData()
    
    switch sectionTitle {
    case LINKED_PROFILES_TITLE:
      enableEditingArray[MenuData.linked_PROFILES.rawValue] = false
      
      if self.hasDeletedProfiles
      {
        
        /********************************
         *  UPLOAD USER DATA TO DYNAMODB
         ********************************/
        // Upload user DATA to DynamoDB
        let dynamoDBUser = User()
        
        dynamoDBUser?.realname = self.currentRealName
        dynamoDBUser?.username = self.currentUserName
        
        // If no current account data, do not upload to dynamo
        // or else it will throw an error.
        if self.currentUserAccounts.count != 0
        {
          dynamoDBUser?.accounts = self.currentUserAccounts
        }
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.save(dynamoDBUser!).continue({ (resultTask) -> AnyObject? in
          
          // If successful save
          if (resultTask.error == nil && resultTask.result != nil)
          {
            print ("DYNAMODB SUCCESSFUL SAVE: ", resultTask.result)
            
            
            // Update UI on main thread
            DispatchQueue.main.async(execute: {
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
      enableEditingArray[MenuData.my_INFORMATION.rawValue] = false
      let fullNameIndexPath = IndexPath(row: MyInformationData.full_NAME.rawValue , section: MenuData.my_INFORMATION.rawValue)
      let emailIndexPath = IndexPath(row: MyInformationData.email.rawValue, section: MenuData.my_INFORMATION.rawValue)
      let phoneIndexPath = IndexPath(row: MyInformationData.phone.rawValue, section: MenuData.my_INFORMATION.rawValue)
      
      
      let fullNameCellTemp = self.settingsTableView.cellForRow(at: fullNameIndexPath)
      let emailCellTemp = self.settingsTableView.cellForRow(at: emailIndexPath)
      let phoneCellTemp = self.settingsTableView.cellForRow(at: phoneIndexPath)
      
      
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
        let phoneString = string.substring(from: 2)
        
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
      email?.name = "email"
      phone?.name = "phone_number"
      
      if self.editedUserEmail != nil && self.editedUserEmail != self.currentUserEmail
      {
        // Update user pools with currentUserPhone
        emailCell.menuValue.text = self.editedUserEmail
        self.currentUserEmail = self.editedUserEmail
        
        email?.value = self.currentUserEmail
        phone?.value = self.currentUserPhone
        
        
        userPool.getUser(self.currentUserName).update([email!, phone!]).continue { (resultTask) -> AnyObject? in
          
          print("SUCCESSFUL USER EMAIL UPDATE IN USERPOOLS")
          return nil
        }
        
      }
      
      if self.editedUserPhone != nil && self.editedUserPhone != self.currentUserPhone
      {
        // In case we need to revert changes -- if user cannot verify
        let oldPhoneNum = self.currentUserPhone
        
        phoneCell.clickToAdd.isHidden = true
        
        // Update user pools with currentUserEmail
        phoneCell.menuValue.text = self.editedUserPhone
        self.currentUserPhone = self.editedUserPhone
        
        email?.value = self.currentUserEmail
        phone?.value = self.currentUserPhone
        
        userPool.getUser(self.currentUserName).update([email!, phone!]).continue { (resultTask) -> AnyObject? in
          
          
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
        
        dynamoDBUser?.realname = self.currentRealName
        dynamoDBUser?.username = self.currentUserName
        
        if self.currentUserAccounts != nil && self.currentUserAccounts.count != 0
        {
          dynamoDBUser?.accounts = self.currentUserAccounts
        }
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        dynamoDBObjectMapper.save(dynamoDBUser!).continue({ (resultTask) -> AnyObject? in
          
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
        let lambdaInvoker = AWSLambdaInvoker.default()
        let parameters = ["action":"updatern", "target": self.currentUserName, "realname": self.currentRealName]
        lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
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


