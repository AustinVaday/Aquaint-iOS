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
import AWSDynamoDB

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
        
        // This will store the username that will be uploaded to Dynamo
        var socialMediaName: String!
        
        switch (socialMediaType)
        {
        case "facebook" :
            /*************************************************************************
             * FACEBOOK DATA FETCH
             **************************************************************************/
            SimpleAuth.authorize("facebook-web") { (result, error) in
                
                if (result == nil)
                {
                    print("CANCELLED REQUEST")
                }
                else if (error == nil)
                {
                    print ("RESULT IS: ", result)
                    
                    let jsonResult = result as! NSDictionary
                    
                    // Get user's nickname from JSON object returned. I.e:
                    // info
                    // {
                    //    nickname = "AustinVaday";
                    //    ...
                    // }
                    
//                    socialMediaName = jsonResult["info"]!["nickname"]! as String!
//                    print("Twitter username returned is: ", socialMediaName)
//                    
//                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
                    
                }
                else
                {
                    print ("FAILED TO PROCESS REQUEST")
                }
                
            }

            
            

//                let login = FBSDKLoginManager.init()
//                
//                // Open in app instead of web browser!
//                login.loginBehavior = FBSDKLoginBehavior.Native
//                
//                // Request basic profile permissions just to get user ID
//                login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
//                    
//                    // If no error, store facebook user ID
//                    if (error == nil)
//                    {
//                        print("SUCCESS LOG IN!", result.debugDescription)
//                        print(result.description)
//                        
////                        // Below can be nil????
////                        if (FBSDKAccessToken.currentAccessToken() != nil)
////                        {
////                            print(FBSDKAccessToken.currentAccessToken().userID)    
//                        FBSDKAccessToken.currentAccessToken().userID
////                        }
//
//                    }
//                    else if (result == nil)
//                    {
//                        print ("RESULT IS NIL")
//                    }
//                    else
//                    {
//                        print("FAIL LOG IN")
//                    }
//                }
            
        
            
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
                    
                    let jsonResult = result as! NSDictionary
                    
                    // Get user's nickname from JSON object returned. I.e:
                    // info
                    // {
                    //    nickname = "AustinVaday";
                    //    ...
                    // }
                    
                    socialMediaName = jsonResult["info"]!["nickname"]! as String!
                    print("Twitter username returned is: ", socialMediaName)
                    
                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
                    
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
                    
                    let jsonResult = result as! NSDictionary
                    
                    // Get user's LinkedIn screenname from JSON object returned. I.e:
                    // extra
                    // {
                    //    raw_info
                    //    {
                    //       screen_name = ....
                    //    }
                    //    ...
                    // }
                    
//                    socialMediaName = jsonResult["extra"]!["raw_info"]!["screen_name"]! as String!
//                    
//                    if (socialMediaName != nil)
//                    {
//                        print("Twitter username returned is: ", socialMediaName)
//                    
//                        self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
//                    }
//                    else
//                    {
//                        print("LINKEDIN USERNAME IS NIL.")
//                    }

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

    @IBAction func backButtonClicked(sender: AnyObject) {

        
        // It's good to dismiss it, but in this case we want to 
        // refresh the collection view on the previous page
        // when we go back. So instead, we will use an unwind action.
//        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    private func updateProfilesDynamoDB(socialMediaType: String!, socialMediaName: String!)
    {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let currentUser = getCurrentCachedUser()
        let currentRealName = getCurrentCachedFullName()
        let currentAccounts = getCurrentCachedUserProfiles() as NSMutableDictionary
        
        // update only if user requests to
        if (socialMediaName != nil)
        {
            // Upload to Dynamo
            /********************************
             *  UPLOAD USER DATA TO DYNAMODB
             ********************************/
            
            
            // Update account data
            
            // If user does not have a particular social media type,
            // we need to create a list
            print("Accounts data was: ", currentAccounts)
            
            if (currentAccounts.valueForKey(socialMediaType) == nil)
            {
                currentAccounts.setValue([ socialMediaName ], forKey: socialMediaType)
                
                
            } // If it already exists, append value to end of list
            else
            {
                
                var list = currentAccounts.valueForKey(socialMediaType) as! Array<String>
                list.append(socialMediaName)
                
                currentAccounts.setValue(list, forKey: socialMediaType)
                
            }
            
            print("Accounts data is now: ", currentAccounts)
            
            
            // Upload user DATA to DynamoDB
            let dynamoDBUser = User()
            
            dynamoDBUser.username = currentUser
            dynamoDBUser.realname = currentRealName
            dynamoDBUser.accounts = currentAccounts
            
            dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
                
                if (resultTask.error != nil)
                {
                    print ("DYNAMODB ADD PROFILE ERROR: ", resultTask.error)
                }
                
                if (resultTask.exception != nil)
                {
                    print ("DYNAMODB ADD PROFILE EXCEPTION: ", resultTask.exception)
                }
                
                if (resultTask.result == nil)
                {
                    print ("DYNAMODB ADD PROFILE result is nil....: ")

                }
                // If successful save
                else if (resultTask.error == nil)
                {
                    print ("DYNAMODB ADD PROFILE SUCCESS: ", resultTask.result)
                    
                    // Also cache accounts data
                    setCurrentCachedUserProfiles(currentAccounts)
                    
                    // Refresh something...
                }
            
                
                return nil
            })
        }

    }
}
