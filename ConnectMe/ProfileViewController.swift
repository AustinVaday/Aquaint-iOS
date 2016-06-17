//
//  ProfileViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/7/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import SimpleAuth
import Firebase


class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var linkedAccountsCollectionView: UICollectionView!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var firebaseLinkedAccountsRef: Firebase!


    
    
    override func viewDidLoad() {
        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Fetch the user's username
        currentUserName = getCurrentUser()
        
        // Set up dictionary for user's social media names
        socialMediaUserNames = NSMutableDictionary()
        
        // Firebase LinkedSocialMediaAccoutns for user, our data is stored here
        firebaseLinkedAccountsRef = Firebase(url: firebaseRootRefString + "LinkedSocialMediaAccounts/" + currentUserName)

        
        
        firebaseLinkedAccountsRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            let socialMediaNameType = snapshot.key
            let socialMediaName = snapshot.value as! String
            
            // Store into dictionary
            self.socialMediaUserNames.setValue(socialMediaName, forKey: socialMediaNameType)
            
            print("OMAHA")
            print(self.socialMediaUserNames)
            
            self.linkedAccountsCollectionView.reloadData()
            
            
            
        })
        
        
        let size = possibleSocialMediaNameList.count
        
        socialMediaImageDictionary = Dictionary<String, UIImage>()
        
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
                print ("ERROR: ProfileViewController : social media emblem image not found.")
  
            }
            
        }

        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return socialMediaUserNames.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("accountsCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
         //Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        var userSocialMediaNames = socialMediaUserNames.allKeys as! Array<String>
    
        userSocialMediaNames = userSocialMediaNames.sort()

        let socialMediaName = userSocialMediaNames[indexPath.item % self.possibleSocialMediaNameList.count]

        // Generate a UI image for the respective social media type
        cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaName]

        cell.socialMediaName = socialMediaName
        
        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

        
    }
    
    
    
    
    
    @IBAction func onGetFacebookInfoButtonClicked(sender: UIButton) {
//        
//        SimpleAuth.authorize("facebook-web") { (result, error) in
//            
//            print ("RESULT IS: ", result, error)
//            
//            if (error == nil)
//            {
//                print ("RESULT IS: ", result)
//            }
//            
//        }

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
            showAlert("Error", message: "You have already linked your Facebook account.", buttonTitle: "Undo?", sender: self)
        }
    }

    
    @IBAction func onGetTwitterInfoClicked(sender: UIButton) {
//        showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

        
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
    
    }
    
    @IBAction func onGetInstagramInfoClicked(sender: UIButton) {

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
    }
    
    @IBAction func onGetYoutubeInfoClicked(sender: UIButton) {
        showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

    }
    
    @IBAction func onGetLinkedinInfoClicked(sender: UIButton) {
        
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

        
    }
    
}
