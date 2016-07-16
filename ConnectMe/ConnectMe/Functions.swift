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

// Struct used to encapsulate cell necessary expansion/collapse variables
struct CellExpansion {
    
    var selectedRowIndex:Int = -1
    var expandedRow:Int = -1
    var isARowExpanded:Bool = false
    
    let NO_ROW = -1
    let defaultRowHeight:CGFloat = 60
    let expandedRowHeight:CGFloat = 120
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
        urlString = "linkedin://profile/" + socialMediaUserName
        altString = "http://www.linkedin.com/in/" + socialMediaUserName
        
        break;
    case "youtube":
        urlString = "youtube:www.youtube.com/user/" + socialMediaUserName
        altString = "http://www.youtube.com/" + socialMediaUserName
        break;
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
func getAllPossibleSocialMediaImages(possibleSocialMediaNameList: Array<String>) -> Dictionary<String, UIImage>!
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
        
        if (numChar >= 6 && numChar <= 20)
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

// Check if phone number is proper
func verifyPhoneFormat(phoneString: String) -> Bool
{
    // User that length of phone is 
    return true
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
}

func setCurrentCachedFullName(userFullName: String)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(userFullName, forKey: "userfullname")
}


func setCurrentCachedUserImage(userImage: UIImage)
{
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(userImage, forKey: "userimage")
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
// Get the current user image that is signed into the app
func getCurrentCachedUserImage() -> UIImage!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUserImage = defaults.valueForKey("userimage") as! UIImage!
    
    if currentUserImage == nil
    {
        print("Uh oh, no cached userImage available.")
        return nil
    }
    
    return currentUserImage
    
}
// Get the current user that is signed into the app
func getCurrentCachedUserProfiles() -> NSMutableDictionary!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let currentUserProfiles = defaults.valueForKey("userprofiles") as! NSMutableDictionary!
    
    if currentUserProfiles == nil
    {
        print("Uh oh, no cached userProfiles available.")
        return nil
    }
    
    return currentUserProfiles
    
}


// Get timestamp as integer value
func getTimestampAsInt() -> Int!
{
    let date = NSDate()
    return Int(date.timeIntervalSince1970)
}
