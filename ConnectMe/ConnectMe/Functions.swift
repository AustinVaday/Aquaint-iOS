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
private let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube", "tumblr" /*, "phone"*/)

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

func convertDictionaryToSocialMediaKeyValPairList(dict: NSMutableDictionary)
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

// Necessary for fetching username URLs
func getUserSocialMediaURL(socialMediaUserName: String!, socialMediaTypeName: String!, sender: AnyObject) -> NSURL!
{
    var urlString = ""
    var altString = ""
    
    switch (socialMediaTypeName)
    {
    case "facebook":
        urlString = "fb://requests/" + socialMediaUserName
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
        urlString = "linkedin://profile/view?id=" + socialMediaUserName //MAY NOT WORK? (added view?)
        altString = "https://www.linkedin.com/profile/view?id=" + socialMediaUserName
        break;
    case "youtube":
        urlString = "youtube:www.youtube.com/user/" + socialMediaUserName
        altString = "http://www.youtube.com/" + socialMediaUserName
        break;
    case "tumblr":
        urlString = "tumblr://x-callback-url/blog?blogName=" + socialMediaUserName
        altString = "http://" + socialMediaUserName + ".tumblr.com"
    case "phone":
        print ("COMING SOON")
        
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
    
    var socialMediaURL = NSURL(string: urlString)
    
    // If user doesn't have social media app installed, open using default browser instead (use altString)
    if (!UIApplication.sharedApplication().canOpenURL(socialMediaURL!))
    {
        if (altString != "")
        {
            socialMediaURL = NSURL(string: altString)
        }
        else
        {
            if (socialMediaTypeName == "snapchat")
            {
                showAlert("Sorry", message: "You need to have the Snapchat app! Please download it and try again!", buttonTitle: "Ok", sender: sender)
            }
            else
            {
                showAlert("Hold on!", message: "Feature coming soon...", buttonTitle: "Ok", sender: sender)
            }
            return nil
        }
    }
    
    print("SOCIAL MEDIA URL IS: ", socialMediaURL)
    return socialMediaURL
}


// Implements a delay.
// Usage: delay([num_sec]){ [Code after delay] }
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}


// Create attributed text string. Specify which range values you'd lke to be bold using
// parallel arrays
func createAttributedTextString(string: String, boldStartArray: [Int], boldEndArray: [Int]) -> NSAttributedString
{
    if boldStartArray.count != boldEndArray.count
    {
        print("CREATE ATTRIBUTE TEXT STRING FUNCTION ERROR: ARRAY SIZES DIFFER")
    }
    
    let attributedString = NSMutableAttributedString(string: string)
    let boldFontAttribute = [NSFontAttributeName: UIFont.boldSystemFontOfSize(15.0)]
    
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
func convertImageToBase64(image: UIImage) -> String
{
    // Get image representation
    let imageData = UIImagePNGRepresentation(image)
    
    // Return b64
    return (imageData?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength))!
}


// Convert base64 to UIImage
func convertBase64ToImage(base64String: String) -> UIImage
{
    let decodedData = NSData(base64EncodedString: base64String, options: .IgnoreUnknownCharacters)!
    
    return UIImage(data: decodedData)!
}



// Flips any image horizontally
func flipImageHorizontally(imageView:UIImageView)
{
    imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0)
}

// Flips any image vertically
func flipImageVertically(imageView:UIImageView)
{
    imageView.transform = CGAffineTransformMakeScale(1.0, -1.0)
}

// Check if username format is proper
func verifyUserNameLength(userNameString: String) -> Bool
{
    if (!userNameString.isEmpty)
    {
        let numChar = userNameString.characters.count
        
        if (numChar >= 5 && numChar <= 20)
        {
            return true
        }
    }
    
    return false
}

func verifyUserNameFormat(userNameString: String) -> Bool
{
    
    if (!userNameString.isEmpty)
    {
        let notAcceptableRange = userNameString.rangeOfCharacterFromSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
        
        if (notAcceptableRange == nil)
        {
            return true
        }
    }
    
    return false
}

// Check if real name format is proper
func verifyRealNameLength(realNameString: String) -> Bool
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
func verifyEmailFormat(emailString:String) -> Bool
{
    
    if (!emailString.isEmpty)
    {
        // Create a regular expression with acceptable email combos
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        
        // Create NSPredicate object to define logical constraints for our search in
        let test = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // Evaluate the regex. Returns true if acceptable, else false
        return test.evaluateWithObject(emailString)
    
    }
    
    return false
    
}

// Remove all non-digits from a string (i.e. phone number)
func removeAllNonDigits(string: String) -> String
{
    let characterSetToRemove = NSCharacterSet.decimalDigitCharacterSet().invertedSet
    return string.componentsSeparatedByCharactersInSet(characterSetToRemove).joinWithSeparator("")
}

// Check if phone number is proper
func verifyPhoneFormat(phoneString: String) -> Bool
{

    // Create a regular expression with acceptable phone number
    let phoneRegex = "[0-9]{10}"
    
    // Create NSPredicate object to define logical constraints for our search in
    let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

    return phoneTest.evaluateWithObject(phoneString)
}

// Check if password format is proper
func verifyPasswordFormat(passwordString:String) -> Bool
{
    // Ensure that length of password is at least 4 characters
    if (passwordString.characters.count > 3)
    {
        return true
    }
    
    return false
    
}

// Check if verification length is proper
func verifyVerificationCodeLength(verificationString: String) -> Bool
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
func showAlert(title: String, message: String, buttonTitle: String, sender: AnyObject)
{
    
    // Create alert to send to user
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    
    // Create the action to add to alert
    let alertAction = UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.Default, handler: nil)
    
    // Add the action to the alert
    alert.addAction(alertAction)
    
    sender.showViewController(alert, sender: nil)
}


func showAlertFetchText(title: String, message: String, buttonTitle: String, textFetch: String, sender: AnyObject)
{
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let confirmAction = UIAlertAction(title: "Confirm", style: .Default) { (_) in
        if let field = alertController.textFields![0] as? UITextField {
            // store your data
            print("STORING DATA!!!")
            NSUserDefaults.standardUserDefaults().setObject(field.text, forKey: "textFetch")
            NSUserDefaults.standardUserDefaults().synchronize()
        } else {
            // user did not fill field
        }
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
    
    alertController.addTextFieldWithConfigurationHandler { (textField) in
        textField.placeholder = "Enter here"
    }
    
    alertController.addAction(confirmAction)
    alertController.addAction(cancelAction)
    
    sender.presentViewController(alertController, animated: true, completion: nil)

 
    
}

func clearUserDefaults()
{
    NSUserDefaults.standardUserDefaults().removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
}


func setCurrentCachedUserName(username: String)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(username, forKey: "username")
    print("Cache username success: ", username)

}

func setCurrentCachedFullName(userFullName: String)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(userFullName, forKey: "userfullname")
    print("Cache userfullname success: ", userFullName)

}

func setCurrentCachedUserEmail(email: String)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(email, forKey: "useremail")
    print("Cache useremail success: ", email)
}

func setCurrentCachedUserPhone(phone: String)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(phone, forKey: "userphone")
    print("Cache userphone success: ", phone)

}

func setCurrentCachedUserImage(userImage: UIImage!)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // Create temp file location for image (hint: may be useful later if we have users taking photos themselves and not wanting to store it)
    let imageFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingString("temp"))
    
    // Force PNG format
    let data = UIImagePNGRepresentation(userImage)
    
    // Write image data to the created url
    try! data?.writeToURL(imageFileURL, options: NSDataWritingOptions.AtomicWrite)
    
    
    defaults.setURL(imageFileURL, forKey: "userimage")
}

func setCurrentCachedUserProfiles(userProfiles: NSMutableDictionary)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(userProfiles, forKey: "userprofiles")
}

// Get the current user that is signed into the app
func getCurrentCachedUser() -> String!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUser = defaults.stringForKey("username")
    
    if currentUser == nil
    {
        print("Uh oh, no cached username available.")
        return nil
    }
    
    return currentUser
    
}


// Get the current user full name that is signed into the app
func getCurrentCachedFullName() -> String!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUserFullName = defaults.stringForKey("userfullname")
    
    if currentUserFullName == nil
    {
        print("Uh oh, no cached full name available.")
        return nil
    }
    
    return currentUserFullName
    
}

// Get the current user email that is signed into the app
func getCurrentCachedEmail() -> String!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUserEmail = defaults.stringForKey("useremail")
    
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
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUserPhone = defaults.stringForKey("userphone")
    
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
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // Fetch cached image URL
    let imageURL = defaults.URLForKey("userimage")
    
    if (imageURL == nil)
    {
        print("Uh oh, no cached userImage available.")
        return nil
    }
    // Get data of image
    let data = NSData(contentsOfURL: imageURL!)
    
    if (data == nil)
    {
        print("Uh oh, no cached userImage available -- data is nil.")
        return nil
    }
    
    // Generate image from data
    let currentUserImage = UIImage(data: data!)
    
    return currentUserImage
    
}
// Get the current user that is signed into the app
func getCurrentCachedUserProfiles() -> NSMutableDictionary!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUserProfiles = defaults.valueForKey("userprofiles") as! NSDictionary!
    
    if currentUserProfiles == nil
    {
        print("Uh oh, no cached userProfiles available.")
        return nil
    }
    
    let mutableCopy = NSMutableDictionary(dictionary: currentUserProfiles)
    return mutableCopy
    
}

// Get timestamp as integer value
func getTimestampAsInt() -> Int!
{
    let date = NSDate()
    return Int(date.timeIntervalSince1970)
}

// For parsing return data (example use case: lambda)
func convertJSONStringToArray(jsonString: AnyObject) -> [String]
{
    let string = jsonString as! String
    
    let data = string.dataUsingEncoding(NSUTF8StringEncoding)
    var result : [String]!
    
    do
    {
        result = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String]
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
    let viewController = storyboard.instantiateViewControllerWithIdentifier("ProfilePopUp")
    let popup = KLCPopup()

    // Modify size of content view accordingly
    let contentView = viewController.view
    contentView.frame.size.height = 200.0
    contentView.frame.size.width = viewController.view.frame.size.width - 30.0
    contentView.layer.cornerRadius = 12.0
    
    // Set popup's content view to be what we just fetched
    popup.contentView = viewController.view

    return popup
}

func clearCookies (domain: String)
{
    let cookieJar : NSHTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    for cookie in cookieJar.cookies! as [NSHTTPCookie]{
        
        let url = "www." + domain + ".com"
        let appUrl = "api." + domain + ".com"
        
        if cookie.domain == url || cookie.domain == appUrl
        {
            cookieJar.deleteCookie(cookie)
            print("Cleared cookies for ", domain)
        }
    }
}

func showPopupForUser(username: String)
{
    let popup = getProfilePopup()
    let view = popup.contentView as! ProfilePopupView
    view.setDataForUser(username)
    popup.contentView = view
    popup.show()
}

