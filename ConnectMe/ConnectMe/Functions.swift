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


// Get the current user that is signed into the app
func getCurrentUser() -> String!
{
    // Get the user defaults set previously in the program (username of user)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    return defaults.stringForKey("username")
    
}


// Get timestamp as integer value
func getTimestampAsInt() -> Int!
{
    let date = NSDate()
    return Int(date.timeIntervalSince1970)
}
