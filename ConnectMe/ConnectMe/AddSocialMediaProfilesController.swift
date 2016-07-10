//
//  AddSocialMediaProfilesController.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/8/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import SimpleAuth

class AddSocialMediaProfilesController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)
    
    override func viewDidLoad() {
       
        // Set up dictionary for user's social media names
        socialMediaUserNames = NSMutableDictionary()
        
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
    }
    
    
    
    /*************************************************************************
    *    COLLECTION VIEW PROTOCOL
    **************************************************************************/
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return possibleSocialMediaNameList.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
       
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        
        print ("SELECTED:", cell.socialMediaType)
        
        let socialMediaType = cell.socialMediaType
        
        switch (socialMediaType)
        {
        case "facebook" :
            /*************************************************************************
             * FACEBOOK DATA FETCH
             **************************************************************************/
            
            // If no user currently logged in with access token, get one
            if (FBSDKAccessToken.currentAccessToken() == nil)
            {
                let login = FBSDKLoginManager.init()
                
                // Open in app instead of web browser!
                login.loginBehavior = FBSDKLoginBehavior.Native
                
                // Request basic profile permissions just to get user ID
                login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
                    
                    // If no error, store facebook user ID
                    if (error == nil)
                    {
                        print("SUCCESS LOG IN!", result.debugDescription)
                        print(FBSDKAccessToken.currentAccessToken().userID)
                    }
                    else if (result.isCancelled)
                    {
                        print ("LOG IN CANCELLED")
                    }
                    else
                    {
                        print("FAIL LOG IN")
                    }
                }
            }
            else
            {
                showAlert("Error", message: "You have already linked this facebook account.", buttonTitle: "Undo?", sender: self)
            }

            
            break
        case "twitter" :
            /*************************************************************************
             * TWITTER DATA FETCH
             **************************************************************************/
            SimpleAuth.authorize("twitter-web") { (result, error) in
                
                if (result == nil)
                {
                    print("CANCELLED REQUEST")
                }
                else if (error == nil)
                {
                    print ("RESULT IS: ", result)
                }
                else
                {
                    print ("FAILED TO PROCESS REQUEST")
                }
                
            }

            
            break
        case "instagram" :
            /*************************************************************************
             * INSTAGRAM DATA FETCH
             **************************************************************************/
            SimpleAuth.authorize("instagram") { (result, error) in
                
                if (result == nil)
                {
                    print("CANCELLED REQUEST")
                }
                else if (error == nil)
                {
                    print ("RESULT IS: ", result)
                }
                else
                {
                    print ("FAILED TO PROCESS REQUEST")
                }
                
            }

            
            break
        case "linkedin" :
            /*************************************************************************
             * LINKEDIN DATA FETCH
             **************************************************************************/
            SimpleAuth.authorize("linkedin-web") { (result, error) in
                
                if (result == nil)
                {
                    print("CANCELLED REQUEST")
                }
                else if (error == nil)
                {
                    print ("RESULT IS: ", result)
                }
                else
                {
                    print ("FAILED TO PROCESS REQUEST")
                }
                
            }

            break
        case "snapchat" :
            /*************************************************************************
             * SNAPCHAT DATA FETCH
             **************************************************************************/
            showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

            
            break
        case "youtube" :
            /*************************************************************************
             * YOUTUBE DATA FETCH
             **************************************************************************/
            showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

            
            break
        default:
            
            
            break
        
        }
        
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("addProfileCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
    
        let socialMediaType = possibleSocialMediaNameList[indexPath.item % possibleSocialMediaNameList.count]
        
        // Generate a UI image for the respective social media type
        cell.emblemImage.image = socialMediaImageDictionary[socialMediaType]
        
        cell.socialMediaType = socialMediaType
        
        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        return cell
    }

}
