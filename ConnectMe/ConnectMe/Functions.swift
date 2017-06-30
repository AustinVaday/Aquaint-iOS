//
//  Functions.swift
//  ConnectMe
//
//  Created by Austin Vaday on 1/16/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import Foundation
import UIKit
import KLCPopup

// Private so to not let other files use this list directly.
private let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube", "tumblr", "soundcloud", "website", "ios", "android")

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

func getNumberPossibleSocialMedia() -> Int
{
  return possibleSocialMediaNameList.count
}

func getAllPossibleSocialMediaList() -> Array<String>
{
  return possibleSocialMediaNameList
}

func convertDictionaryToSocialMediaKeyValPairList(_ dict: NSMutableDictionary!)
  -> Array<KeyValSocialMediaPair>!
{
  
  
  var pairList = Array<KeyValSocialMediaPair>()
  
  if dict == nil
  {
    return pairList
  }
  
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

func computeTimeDiffFromNow(_ timestampGMT: Int) -> String
{
  let currentTime = getTimestampAsInt()
  
  // Get time diff in seconds
  let timeDiffSec = (currentTime! - timestampGMT)
  
  // If we're in seconds, return seconds
  if (timeDiffSec < 60)
  {
    return String(Int(timeDiffSec)) + " sec"
  }
    // If it's better to use minutes
  else if (timeDiffSec < (60 * 60))
  {
    let calcTime = Int(timeDiffSec / 60)
    return String(calcTime) + " min"
  }
    // If it's better to use hours
  else if (timeDiffSec < (60 * 60 * 24))
  {
    let calcTime = Int(timeDiffSec / 60 / 60)
    return String(calcTime) + " h"
  }
    // If it's better to use days
  else if (timeDiffSec < (60 * 60 * 24 * 30))
  {
    let calcTime = Int(timeDiffSec / 60 / 60 / 24 )
    return String(calcTime) + " d"
  }
    // If it's better to use months
  else if (timeDiffSec < (60 * 60 * 24 * 30 * 12))
  {
    let calcTime = Int(timeDiffSec / 60 / 60 / 24 / 30)
    return String(calcTime) + " mo"
  }
  else
  {
    let calcTime = Int(timeDiffSec / 60 / 60 / 24 / 365)
    return String(calcTime) + " y"
  }
  
}

func getSocialMediaDisplayName(_ socialMediaType: String) -> String
{
  switch socialMediaType {
    case "android": return "Android App"
    case "ios": return "iOS App"
    default: return socialMediaType.capitalized
  }
}

// Necessary for fetching username URLs
func getUserSocialMediaURL(_ socialMediaUserName: String!, socialMediaTypeName: String!, sender: AnyObject) -> URL!
{
  var urlString = ""
  var altString = ""
  
  switch (socialMediaTypeName)
  {
  case "facebook":
    //        urlString = "fb://requests/" + socialMediaUserName
    altString = "http://www.facebook.com/" + socialMediaUserName
    break;
  case "snapchat":
    urlString = "snapchat://add/" + socialMediaUserName
    altString = "http://www.snapchat.com/add/" + socialMediaUserName
    break;
  case "instagram":
    urlString = "instagram://user?username=" + socialMediaUserName
    altString = "http://www.instagram.com/" + socialMediaUserName
    break;
  case "twitter":
    urlString = "twitter:///user?screen_name=" + socialMediaUserName
    altString = "http://www.twitter.com/" + socialMediaUserName
    break;
  case "linkedin":
    /*
    urlString = "linkedin://profile/view?id=" + socialMediaUserName //MAY NOT WORK? (added view?)
    // UPDATE: confirmed urlString does not work even if Linkedin app is installed. altString is automatically used instead
    altString = "https://www.linkedin.com/profile/view?id=" + socialMediaUserName
    */
    // temporary solution for user manually entering URL in popup
    urlString = socialMediaUserName
    break;
    
  case "youtube":
    urlString = "youtube:www.youtube.com/user/" + socialMediaUserName
    altString = "http://www.youtube.com/" + socialMediaUserName
    break;
  case "soundcloud":
    //        urlString = "soundcloud://users/" + socialMediaUserName
    altString = "http://www.soundcloud.com/" + socialMediaUserName
  case "tumblr":
    urlString = "tumblr://x-callback-url/blog?blogName=" + socialMediaUserName
    altString = "http://" + socialMediaUserName + ".tumblr.com"
  case "ios":
    urlString  = socialMediaUserName
  case "android":
    urlString  = socialMediaUserName
  case "website":
    urlString  = socialMediaUserName
    
    //                contact.familyName = "Vaday"
    //                contact.givenName  = "Austin"
    //
    //                let phoneNum  = CNPhoneNumber(stringValue: "9493758223")
    //                let cellPhone = CNLabeledValue(label: CNLabelPhoneNumberiPhone, value: phoneNum)
    //
    //                contact.phoneNumbers.append(cellPhone)
    //
    //                //TODO: Check if contact already exists in phone
    //                let saveRequest = CNSaveRequest()
    //                saveRequest.addContact(contact, toContainerWithIdentifier: nil)
    //
    
    //                return
    
    break;
  default:
    break;
  }
  
  var socialMediaURL = URL(string: urlString)
  
  // If user doesn't have social media app installed, open using default browser instead (use altString)
  if (!UIApplication.shared.canOpenURL(socialMediaURL!))
  {
    if (altString != "")
    {
      socialMediaURL = URL(string: altString)
    }
    else
    {
      if (socialMediaTypeName == "snapchat")
      {
        DispatchQueue.main.async(execute: {
          showAlert("Sorry", message: "It seems like you don't have the Snapchat app installed! Please install it and try again.", buttonTitle: "Ok", sender: sender)
        })
      }
      else
      {
        DispatchQueue.main.async(execute: {
          showAlert("Hold on!", message: "Feature coming soon...", buttonTitle: "Ok", sender: sender)
        })
      }
      return nil
    }
  }
  
  print("SOCIAL MEDIA URL IS: ", socialMediaURL)
  return socialMediaURL
}


// Implements a delay.
// Usage: delay([num_sec]){ [Code after delay] }
func delay(_ delay:Double, closure:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(
    deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}


// Create attributed text string. Specify which range values you'd lke to be bold using
// parallel arrays
func createAttributedTextString(_ string: String, boldStartArray: [Int], boldEndArray: [Int]) -> NSAttributedString
{
  if boldStartArray.count != boldEndArray.count
  {
    print("CREATE ATTRIBUTE TEXT STRING FUNCTION ERROR: ARRAY SIZES DIFFER")
  }
  
  let attributedString = NSMutableAttributedString(string: string)
  let boldFontAttribute = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15.0)]
  
  for (start,end) in zip(boldStartArray,boldEndArray)
  {
    // NSRange works by specifying a starting location and then how many characters after.
    // So if we have a range from [5 to 10], we need to specify NSRange(location: 5, length: 5)
    attributedString.addAttributes(boldFontAttribute, range: NSRange(location: start ,length: end - start))
  }
  
  return attributedString
  
}

// Get a dictionary of all images!
func getAllPossibleSocialMediaImages() -> Dictionary<String, UIImage>!
{
  let size = possibleSocialMediaNameList.count
  var socialMediaImageDictionary = Dictionary<String, UIImage>()
  // Generate all necessary images for the emblems
  for i in 0...size-1
  {
    // Fetch emblem name
    let imageName = possibleSocialMediaNameList[i]
    
    print("Generating image for: ", imageName)
    // Generate image
    let newUIImage = UIImage(named: imageName)
    
    if (newUIImage != nil)
    {
      // Store image into our 'cache'
      socialMediaImageDictionary[imageName] = newUIImage
    }
    else
    {
      print ("ERROR: getAllPossibleSocialMediaImages : social media emblem image not found for:", imageName)
    }
    
  }
  return socialMediaImageDictionary
  
}

// Generate a random UIColor!
func generateRandomColor() -> UIColor {
  let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
  let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
  let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
  
  return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
}


// Convert UIImage to base64
func convertImageToBase64(_ image: UIImage) -> String
{
  // Get image representation
  let imageData = UIImagePNGRepresentation(image)
  
  // Return b64
  return (imageData?.base64EncodedString(options: .lineLength64Characters))!
}


// Convert base64 to UIImage
func convertBase64ToImage(_ base64String: String) -> UIImage
{
  let decodedData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)!
  
  return UIImage(data: decodedData)!
}



// Flips any image horizontally
func flipImageHorizontally(_ imageView:UIImageView)
{
  imageView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
}

// Flips any image vertically
func flipImageVertically(_ imageView:UIImageView)
{
  imageView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
}

// Check if url format is proper
func verifyUrl (_ urlString: String?) -> Bool {
//  //Check for nil
//  if let urlString = urlString {
//    // create NSURL instance
//    if let url = NSURL(string: urlString) {
//      // check if your application can open the NSURL instance
//      return UIApplication.sharedApplication().canOpenURL(url)
//    }
//  }
//  return false
  
  // The following does not always check valid URLs. For Example the ? and = sign in: https://itunes.apple.com/us/app/aquaint/id1142094794?mt=8
  let urlRegEx1 = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
  let urlRegEx2 = "(?i)(http|https)(:\\/\\/)([^ .]+)(\\.)([^ \n]+)"
  return NSPredicate(format: "SELF MATCHES %@", urlRegEx1).evaluate(with: urlString) ||
         NSPredicate(format: "SELF MATCHES %@", urlRegEx2).evaluate(with: urlString)
}

// Check if username format is proper
func verifyUserNameLength(_ userNameString: String) -> Bool
{
  if (!userNameString.isEmpty)
  {
    let numChar = userNameString.characters.count
    
    if (numChar >= 3 && numChar <= 20)
    {
      return true
    }
  }
  
  return false
}

func verifyUserNameFormat(_ userNameString: String) -> Bool
{
  
  if (!userNameString.isEmpty)
  {
    let acceptableCharacterSet = NSMutableCharacterSet.alphanumeric()
    acceptableCharacterSet.addCharacters(in: "_-")
    
    let notAcceptableRange = userNameString.rangeOfCharacter(from: acceptableCharacterSet.inverted)
    
    if (notAcceptableRange == nil)
    {
      return true
    }
  }
  
  return false
}

// Check if real name format is proper
func verifyRealNameLength(_ realNameString: String) -> Bool
{
  if (!realNameString.isEmpty)
  {
    let numChar = realNameString.characters.count
    
    if (numChar >= 1 && numChar <= 30)
    {
      return true
    }
  }
  
  return false
}

//func verifyRealNameFormat(realNameString: String) -> Bool
//{
//
//    if (!realNameString.isEmpty)
//    {
//        let notAcceptableRange = realNameString.rangeOfCharacterFromSet(NSCharacterSet.letterCharacterSet().invertedSet)
//
//        if (notAcceptableRange == nil)
//        {
//            return true
//        }
//    }
//
//    return false
//}

// Check if email format is proper
func verifyEmailFormat(_ emailString:String) -> Bool
{
  
  if (!emailString.isEmpty)
  {
    // Create a regular expression with acceptable email combos
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
    
    // Create NSPredicate object to define logical constraints for our search in
    let test = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    
    // Evaluate the regex. Returns true if acceptable, else false
    return test.evaluate(with: emailString)
    
  }
  
  return false
  
}

// Remove all non-digits from a string (i.e. phone number)
func removeAllNonDigits(_ string: String) -> String
{
  let characterSetToRemove = CharacterSet.decimalDigits.inverted
  return string.components(separatedBy: characterSetToRemove).joined(separator: "")
}

// Remove all non-alpha-numeric characters from a string (i.e. username)
func removeAllNonAlphaNumeric(_ string: String, charactersToKeep: String? = nil) -> String
{
  let acceptableCharacterSet = NSMutableCharacterSet.alphanumeric()
  
  // If user specifies any characters to keep, add them to acceptable set
  if charactersToKeep != nil
  {
    acceptableCharacterSet.addCharacters(in: charactersToKeep!)
  }
  let characterSetToRemove = acceptableCharacterSet.inverted
  return string.components(separatedBy: characterSetToRemove).joined(separator: "")
}

// Remove all non-alpha-numeric characters from a string (i.e. username)
func removeAllNonAlphaNumeric(_ string: String) -> String
{
  let characterSetToRemove = CharacterSet.alphanumerics.inverted
  return string.components(separatedBy: characterSetToRemove).joined(separator: "")
}


// Check if phone number is proper
func verifyPhoneFormat(_ phoneString: String) -> Bool
{
  
  // Create a regular expression with acceptable phone number
  let phoneRegex = "[0-9]{10}"
  
  // Create NSPredicate object to define logical constraints for our search in
  let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
  
  return phoneTest.evaluate(with: phoneString)
}

// Check if password format is proper
func verifyPasswordFormat(_ passwordString:String) -> Bool
{
  // Ensure that length of password is at least 4 characters
  if (passwordString.characters.count > 3)
  {
    return true
  }
  
  return false
  
}

// Check if verification length is proper
func verifyVerificationCodeLength(_ verificationString: String) -> Bool
{
  if (!verificationString.isEmpty)
  {
    let numChar = verificationString.characters.count
    
    // Verification codes are 6 characters long.
    if (numChar == 6)
    {
      return true
    }
    
  }
  
  return false
}

// Show an alert to the user
func showAlert(_ title: String, message: String, buttonTitle: String, sender: AnyObject)
{
  
  // Create alert to send to user
  let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
  
  // Create the action to add to alert
  let alertAction = UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.default, handler: nil)
  
  // Add the action to the alert
  alert.addAction(alertAction)
  
  sender.show(alert, sender: nil)
}


func showAlertFetchText(_ title: String, message: String, buttonTitle: String, textFetch: String, sender: AnyObject)
{
  let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
  
  let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
    if let field = alertController.textFields![0] as? UITextField {
      // store your data
      print("STORING DATA!!!")
      UserDefaults.standard.set(field.text, forKey: "textFetch")
      UserDefaults.standard.synchronize()
    } else {
      // user did not fill field
    }
  }
  
  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
  
  alertController.addTextField { (textField) in
    textField.placeholder = "Enter here"
  }
  
  alertController.addAction(confirmAction)
  alertController.addAction(cancelAction)
  
  sender.present(alertController, animated: true, completion: nil)
  
  
  
}

func clearUserDefaults()
{
  // Make sure delete the temporary user image that we created...
  let defaults = UserDefaults.standard
  
  // Fetch cached image URL
  let imageURL = defaults.url(forKey: "userimage")
  
  let fileManager = FileManager.default
  
  if imageURL != nil
  {
    // Delete image from path so that next user will have a fresh location
    try? fileManager.removeItem(at: imageURL!)
    
  }
  
  UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
}


func setCurrentCachedUserName(_ username: String)
{
  let defaults = UserDefaults.standard
  defaults.set(username, forKey: "username")
  print("Cache username success: ", username)
  
}

func setCachedUserSignUpName(_ userSignUpName: String)
{
  let defaults = UserDefaults.standard
  defaults.set(userSignUpName, forKey: "usersignupname")
  print("Cache userSignUpName success: ", userSignUpName)
  
}

func setCurrentCachedFullName(_ userFullName: String)
{
  let defaults = UserDefaults.standard
  defaults.set(userFullName, forKey: "userfullname")
  print("Cache userfullname success: ", userFullName)
  
}

func setCurrentCachedDeviceID(_ deviceID: String) {
  let defaults = UserDefaults.standard
  defaults.set(deviceID, forKey: "deviceID")
  print("Cache deviceID success: ", deviceID)
}

func setCurrentCachedPrivacyStatus(_ privacyStatus: String) {
  if privacyStatus != "public" && privacyStatus != "private" {
    print("ERROR. Attempting to cache unnaceptable privacy status. Must be either private or public: ", privacyStatus)
    return
  }
  let defaults = UserDefaults.standard
  defaults.set(privacyStatus, forKey: "privacyStatus")
  print("Cache deviceID success: ", privacyStatus)
}

func setCurrentCachedUserEmail(_ email: String)
{
  let defaults = UserDefaults.standard
  defaults.set(email, forKey: "useremail")
  print("Cache useremail success: ", email)
}

func setCurrentCachedUserPhone(_ phone: String)
{
  let defaults = UserDefaults.standard
  defaults.set(phone, forKey: "userphone")
  print("Cache userphone success: ", phone)
  
}

func setCurrentCachedUserImage(_ userImage: UIImage!)
{
  let defaults = UserDefaults.standard
  
  // Create temp file location for image (hint: may be useful later if we have users taking photos themselves and not wanting to store it)
  let imageFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "temp")
  
  // Force PNG format
  let data = UIImagePNGRepresentation(userImage)
  
  // Write image data to the created url
  try! data?.write(to: imageFileURL, options: NSData.WritingOptions.atomicWrite)
  
  
  defaults.set(imageFileURL, forKey: "userimage")
}

func setCurrentCachedUserScanCode(_ scanCode: UIImage!)
{
  let defaults = UserDefaults.standard
  
  // Create temp file location for image (hint: may be useful later if we have users taking photos themselves and not wanting to store it)
  let imageFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "tempUserScanCode")
  
  // Force PNG format
  let data = UIImagePNGRepresentation(scanCode)
  
  // Write image data to the created url
  try! data?.write(to: imageFileURL, options: NSData.WritingOptions.atomicWrite)
  
  defaults.set(imageFileURL, forKey: "userscancode")
  
}

func setCurrentCachedSubscriptionStatus(_ status : Bool)
{
  let defaults = UserDefaults.standard
  defaults.set(status, forKey: "subscriptionStatus")
}

func setCurrentCachedPromoUserStatus(_ status : Bool)
{
  let defaults = UserDefaults.standard
  defaults.set(status, forKey: "promoUserStatus")
}

func setCurrentCachedUserProfiles(_ userProfiles: NSMutableDictionary)
{
  let defaults = UserDefaults.standard
  defaults.set(userProfiles, forKey: "userprofiles")
}

func setCurrentNotificationTimestamp(_ timestamp: Date) {
  let defaults = UserDefaults.standard
  defaults.set(timestamp, forKey: "notificationTimestamp")
}

// Get the current user that is signed into the app
func getCurrentCachedUser() -> String!
{
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  let currentUser = defaults.string(forKey: "username")
  
  if currentUser == nil
  {
    print("Uh oh, no cached username available.")
    return nil
  }
  
  return currentUser
  
}

// Get the current user that is signed into the app
func getCachedUserSignUpName() -> String!
{
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  let signupName = defaults.string(forKey: "usersignupname")
  
  if signupName == nil
  {
    print("Uh oh, no cached usersignupname available.")
    return nil
  }
  
  return signupName
  
}


// Get the current user full name that is signed into the app
func getCurrentCachedFullName() -> String!
{
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  let currentUserFullName = defaults.string(forKey: "userfullname")
  
  if currentUserFullName == nil
  {
    print("Uh oh, no cached full name available.")
    return nil
  }
  
  return currentUserFullName
  
}

// Get the current user's device IDs, used for sending out push notification on server
func getCurrentCachedDeviceID() -> String! {
  let defaults = UserDefaults.standard
  
  let currentDeviceID = defaults.string(forKey: "deviceID")
  
  if currentDeviceID == nil {
    print("Uh oh, no cached deviceID available.")
    return nil
  }
  
  return currentDeviceID
}

// Get the current user's privacy setting status, used to determine whether to show follow requests or not.
func getCurrentCachedPrivacyStatus() -> String! {
  let defaults = UserDefaults.standard
  
  let currentPrivacyStatus = defaults.string(forKey: "privacyStatus")
  
  if currentPrivacyStatus == nil {
    print("Uh oh, no cached privacy status available.")
    return nil
  }
  
  return currentPrivacyStatus
}


// Get the current user email that is signed into the app
func getCurrentCachedEmail() -> String!
{
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  let currentUserEmail = defaults.string(forKey: "useremail")
  
  if currentUserEmail == nil
  {
    print("Uh oh, no cached email  available.")
    return nil
  }
  
  return currentUserEmail
  
}

// Get the current user full name that is signed into the app
func getCurrentCachedPhone() -> String!
{
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  let currentUserPhone = defaults.string(forKey: "userphone")
  
  if currentUserPhone == nil
  {
    print("Uh oh, no cached user phone available.")
    return nil
  }
  
  return currentUserPhone
  
}
// Get the current user image that is signed into the app
func getCurrentCachedUserImage() -> UIImage!
{
  
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  // Fetch cached image URL
  let imageURL = defaults.url(forKey: "userimage")
  
  if (imageURL == nil)
  {
    print("Uh oh, no cached userImage available.")
    return nil
  }
  // Get data of image
  let data = try? Data(contentsOf: imageURL!)
  
  if (data == nil)
  {
    print("Uh oh, no cached userImage available -- data is nil.")
    return nil
  }
  
  // Generate image from data
  let currentUserImage = UIImage(data: data!)
  
  return currentUserImage
  
}

func getCurrentCachedUserScanCode() -> UIImage!
{
  
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  // Fetch cached image URL
  let imageURL = defaults.url(forKey: "userscancode")
  
  if (imageURL == nil)
  {
    print("Uh oh, no cached scan code available.")
    return nil
  }
  // Get data of image
  let data = try? Data(contentsOf: imageURL!)
  
  if (data == nil)
  {
    print("Uh oh, no cached scan code available -- data is nil.")
    return nil
  }
  
  // Generate image from data
  let currentScanCode = UIImage(data: data!)
  
  return currentScanCode
  
}

func getCurrentCachedSubscriptionStatus() -> Bool
{
  let defaults = UserDefaults.standard
  
  let status = defaults.value(forKey: "subscriptionStatus") as! Bool!
  
  if status == nil {
    return false
  } else {
    return status!
  }
}

func getCurrentCachedPromoUserStatus() -> Bool
{
  let defaults = UserDefaults.standard
  
  let status = defaults.value(forKey: "promoUserStatus") as! Bool!
  
  if status == nil {
    return false
  } else {
    return status!
  }
}

// Get the current user that is signed into the app
func getCurrentCachedUserProfiles() -> NSMutableDictionary!
{
  // Get the user defaults set previously in the program (username of user)
  let defaults = UserDefaults.standard
  
  let currentUserProfiles = defaults.value(forKey: "userprofiles") as! NSDictionary!
  
  if currentUserProfiles == nil
  {
    print("Uh oh, no cached userProfiles available.")
    return nil
  }
  
  let mutableCopy = NSMutableDictionary(dictionary: currentUserProfiles!)
  return mutableCopy
  
}

// Get the Notification Timestamp of last time reminding the user to enable push notification feature
func getCurrentNotificationTimestamp() -> Date! {
  let defaults = UserDefaults.standard
  
  let currentNotificationTimestamp = defaults.value(forKey: "notificationTimestamp")
  
  if currentNotificationTimestamp == nil {
    print("Uh oh, no cached notificationTimestamp available.")
    return nil
  }
  
  return (currentNotificationTimestamp as! Date)
}

// Get timestamp as integer value
func getTimestampAsInt() -> Int!
{
  let date = Date()
  return Int(date.timeIntervalSince1970)
}

// For parsing return data (example use case: lambda)
func convertJSONStringToArray(_ jsonString: AnyObject) -> NSArray!
{
  let string = jsonString as! String
  
  let data = string.data(using: String.Encoding.utf8)
  var result : NSArray!
  
  do
  {
    result = try JSONSerialization.jsonObject(with: data!, options: []) as! NSArray
  }
  catch let error as NSError
  {
    print(error)
  }
  
  return result
}

// For getting the app's special popup view to display user 'profiles'
func getProfilePopup() -> KLCPopup
{
  // Get our special popup design from the XIB
  let storyboard = UIStoryboard(name: "PopUpAlert", bundle: nil)
  let viewController = storyboard.instantiateViewController(withIdentifier: "ProfilePopUp")
  let popup = KLCPopup()
  
  // Modify size of content view accordingly
  let contentView = viewController.view
  contentView?.frame.size.height = 200.0
  contentView?.frame.size.width = viewController.view.frame.size.width - 30.0
  contentView?.layer.cornerRadius = 12.0
  
  // Set popup's content view to be what we just fetched
  popup.contentView = viewController.view
  
  return popup
}

// For getting the app's special popup view to display help messages
func getHelpPopup() -> KLCPopup
{
  // Get our special popup design from the XIB
  let storyboard = UIStoryboard(name: "PopUpHelpAlert", bundle: nil)
  let viewController = storyboard.instantiateViewController(withIdentifier: "HelpPopUp")
  let popup = KLCPopup()
  
  // Modify size of content view accordingly
  let contentView = viewController.view
  contentView?.frame.size.height = 200.0
  contentView?.frame.size.width = viewController.view.frame.size.width - 30.0
  contentView?.layer.cornerRadius = 12.0
  
  // Set popup's content view to be what we just fetched
  popup.contentView = viewController.view
  
  return popup
}

func clearCookies (_ domain: String)
{
  let cookieJar : HTTPCookieStorage = HTTPCookieStorage.shared
  for cookie in cookieJar.cookies! as [HTTPCookie]{
    
    let url = "www." + domain + ".com"
    let appUrl = "api." + domain + ".com"
    
    if cookie.domain == url || cookie.domain == appUrl
    {
      cookieJar.deleteCookie(cookie)
      print("Cleared cookies for ", domain)
    }
  }
}

func showHelpPopup(_ title: String, description: String)
{
  let popup = getHelpPopup()
  let view = popup.contentView as! HelpPopupView
  view.helpTitle.text = title
  view.helpDescription.text = description
  popup.contentView = view
  popup.show()
}


func showPopupForUser(_ username: String, me: String)
{
  let popup = getProfilePopup()
  let view = popup.contentView as! ProfilePopupView
  view.setDataForUser(username, me: me)
  popup.contentView = view
  popup.show()
}

// Showing KLCPopup at the QR code scanning section
func showPopupForUserFromScanCode(_ username: String, me: String, sender: UIViewController) {
  let popup = getProfilePopup()
  let view = popup.contentView as! ProfilePopupView
  view.setDataForUser(username, me: me)
  popup.contentView = view
  
  if let scanCodeViewController = sender as? ScanCodeDisplay {
    popup.didFinishShowingCompletion = { () -> Void in
      scanCodeViewController.isShowingUserProfilePopup = true
    }
    popup.didFinishDismissingCompletion = { () -> Void in
      scanCodeViewController.isShowingUserProfilePopup = false
    }
  } else {
    print("showPopupForUserFromScanCode(): sender is not of type ScanCodeDisplay. ")
  }
  popup.show()
}

func showPopupForUserWithView(_ view: ProfilePopupView)
{
  let popup = getProfilePopup()
  popup.contentView = view
  popup.show()
}

func showPopupForUser(_ username: String, me: String, searchConsistencyDelegate: SearchTableViewCell!)
{
  let popup = getProfilePopup()
  let view = popup.contentView as! ProfilePopupView
  view.setDataForUser(username, me: me)
  
  // Used to enforce consistency between search table view cell and popup
  if searchConsistencyDelegate != nil {
    view.popupSearchConsistencyDelegate = searchConsistencyDelegate
  }
  
  popup.contentView = view
  popup.show()
}

func registerToReceivePushNotifications()
{
  
  // Apple Push Notification initialization
  let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
  let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
  
  let application = UIApplication.shared
  application.registerUserNotificationSettings(pushNotificationSettings)
  application.registerForRemoteNotifications()
  
}

// prompt the user if he/she wants to enable app push notification. If yes, register system-level remote notification
func askUserForPushNotificationPermission(_ viewController: UIViewController) {
  
  // TODO: if user disables notification permission in system Settings later, the prompt would still show up but cannot register for push notification. Have to distinguish "Declined" or "Uninitialized"
  let timeIntervalThreshold = 604800.0  // setting to one week (in seconds)
  var willRemindUser = 1
  
  let lastNotificationDate = getCurrentNotificationTimestamp()
  let currentDate = Date()
  if let lastNotification = lastNotificationDate {
    let timeInterval = currentDate.timeIntervalSince(lastNotification)
    // if we have reminded user to enable push notification before (a timestamp entry exists in NSUserDefaults), in less than timeIntervalThreshold, we don't ask again
    if timeInterval < timeIntervalThreshold {
      willRemindUser = 0
    }
  }
  
  let isRegisteredForNotification = UIApplication.shared.isRegisteredForRemoteNotifications
  
  if ((UIApplication.shared.isRegisteredForRemoteNotifications == false) && (willRemindUser == 1)) {
    
    let alertTitle = "Enable Push Notification"
    let alertMessage = "Aquaint will notify you when you have new followers, new follow requests or your follow requests to others get accepted! "
    let notificationAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
    
    let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) {
      UIAlertAction in
      
      print("askUserForPushNotificationPermission: user chooses to enable push notification. ")
      registerToReceivePushNotifications()
    }
    
    let noAction = UIAlertAction(title: "Not Now", style: UIAlertActionStyle.default) {
      UIAlertAction in
      
      print("askUserForPushNotificationPermission: user chooses NOT to enable push notification. ")
      
      let currentDate = Date.init()
      setCurrentNotificationTimestamp(currentDate)
    }
    
    notificationAlert.addAction(noAction)
    notificationAlert.addAction(yesAction)
    
    DispatchQueue.main.async {
      viewController.present(notificationAlert, animated: true, completion: nil)
    }
    
  } else if (isRegisteredForNotification == true) {
    // app has registered system-level push notification service before.
    // register with APN server every time the app launches, to check any update on deviceToken
    registerToReceivePushNotifications()
  }
  
}

func downloadImageFromURL(_ url: String, completion: @escaping (_ result: UIImage?, _ error: NSError?)->())
{
  let nsurl = URL(string: url)
  
  // Creating a session object with the default configuration.
  let session = URLSession(configuration: URLSessionConfiguration.default)
  
  
  // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
  let downloadPicTask = session.dataTask(with: nsurl!, completionHandler: { (data, response, error) in
    // The download has finished.
    if let e = error {
      print("Error downloading URL picture: \(e)")
      completion(nil, e as NSError)
    } else {
      // No errors found.
      if let res = response as? HTTPURLResponse {
        print("Downloaded cat picture with response code \(res.statusCode)")
        if let imageData = data {
          // Finally convert that Data into an image and do what you wish with it.
          let image = UIImage(data: imageData)
          completion(image, nil)
          // Do something with your image.
        } else {
          print("Couldn't get image: Image is nil")
          completion(nil, nil)
        }
      } else {
        print("Couldn't get response code for some reason")
      }
    }
  }) 
  
  downloadPicTask.resume()
}

func addVerifiedIconToLabel(_ username: String, label: UILabel, size: Int) {
  let attachment = NSTextAttachment()
  attachment.image = UIImage(named: "Verified Button")
  attachment.bounds = CGRect(x: 2, y: -2, width: size, height: size)
  let attachmentStr = NSAttributedString(attachment: attachment)
  let myString = NSMutableAttributedString(string: "")
  let myString1 = NSMutableAttributedString(string: username)
  myString.append(myString1)
  myString.append(attachmentStr)
  
  label.text = ""
  label.attributedText = myString
  
}
