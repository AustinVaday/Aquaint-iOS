//
//  SocialMediaCollectionViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/12/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class SocialMediaCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var emblemButton: UIButton!

    @IBAction func emblemButtonClicked(sender: AnyObject) {
        
        print("The button was clicked!")
        
        var socialMediaURL = NSURL(string: "twitter:///user?screen_name=AustinVaday")
//        var socialMediaURL = NSURL(string: "snapchat://?u=AustinVaday")
//        var socialMediaURL = NSURL(string: "instagram://user?username=avtheman")

        
        // If user doesn't have social media app installed, open using default browser instead.
        if(!UIApplication.sharedApplication().canOpenURL(socialMediaURL!))
        {
            socialMediaURL = NSURL(string: "http://www.twitter.com/AustinVaday")
            
        }
 
        UIApplication.sharedApplication().openURL(socialMediaURL!)


    }
}
