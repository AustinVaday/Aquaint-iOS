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
        let emailRegex = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
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
