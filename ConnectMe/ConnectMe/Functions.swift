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
