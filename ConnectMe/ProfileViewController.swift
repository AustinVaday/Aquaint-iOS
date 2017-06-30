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
//import SimpleAuth
//import Firebase


class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var linkedAccountsCollectionView: UICollectionView!
        
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var firebaseLinkedAccountsRef: FIRDatabaseReference!
    var firebaseRootRef : FIRDatabaseReference!

    
    
    override func viewDidLoad() {
        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Fetch the user's username
        currentUserName = getCurrentCachedUser()
        
        // Set up dictionary for user's social media names
        socialMediaUserNames = NSMutableDictionary()
        
        // Firebase LinkedSocialMediaAccoutns for user, our data is stored here
        firebaseRootRef = FIRDatabase.database().reference()
        firebaseLinkedAccountsRef = firebaseRootRef.child("LinkedSocialMediaAccounts/" + currentUserName)
        
        firebaseLinkedAccountsRef.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            let socialMediaNameType = snapshot.key
            let socialMediaName = snapshot.value as! String
            
            // Store into dictionary
            self.socialMediaUserNames.setValue(socialMediaName, forKey: socialMediaNameType)
            
            print("OMAHA")
            print(self.socialMediaUserNames)
            
            self.linkedAccountsCollectionView.reloadData()
            
            
            
        })
        
        
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()

        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return socialMediaUserNames.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "accountsCollectionViewCell", for: indexPath) as! SocialMediaCollectionViewCell
        
         //Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        var userSocialMediaNames = socialMediaUserNames.allKeys as! Array<String>
    
        userSocialMediaNames = userSocialMediaNames.sorted()

        let socialMediaName = userSocialMediaNames[indexPath.item % getNumberPossibleSocialMedia()]

        // Generate a UI image for the respective social media type
        cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaName]

        cell.socialMediaName = socialMediaName
        
        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

        
    }
    
    
    
    
    
    @IBAction func onGetFacebookInfoButtonClicked(_ sender: UIButton) {
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
        if (FBSDKAccessToken.current() == nil)
        {
            let login = FBSDKLoginManager.init()
            
            // Open in app instead of web browser!
            login.loginBehavior = FBSDKLoginBehavior.native
            
            // Request basic profile permissions just to get user ID
            login.logIn(withReadPermissions: ["public_profile"], from: self) { (result, error) in
                
                // If no error, store facebook user ID
                if (error == nil)
                {
                    print("SUCCESS LOG IN!", result.debugDescription)
                    print(FBSDKAccessToken.current().userID)
                }
                else if (result?.isCancelled)!
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

    
    @IBAction func onGetTwitterInfoClicked(_ sender: UIButton) {
//        showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

        /*
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
       */
    
    }
    
    @IBAction func onGetInstagramInfoClicked(_ sender: UIButton) {

        /*
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
       */
    }
    
    @IBAction func onGetYoutubeInfoClicked(_ sender: UIButton) {
        showAlert("Hold Tight!", message: "Feature coming soon.", buttonTitle: "Ok", sender: self)

    }
    
    @IBAction func onGetLinkedinInfoClicked(_ sender: UIButton) {
      
        /*
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
        */
      
    }
    
}
