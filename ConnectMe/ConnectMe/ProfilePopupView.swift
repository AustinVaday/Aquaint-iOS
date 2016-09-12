//
//  ProfilePopupView.swift
//  Aquaint
//
//  Created by Austin Vaday on 8/23/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda

class ProfilePopupView: UIView, UICollectionViewDelegate, UICollectionViewDataSource{

    @IBOutlet weak var realNameTextFieldLabel: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var numFollowersLabel: UILabel!
    @IBOutlet weak var numFollowsLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var socialMediaCollectionView: UICollectionView!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube")
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    func setDataForUser(username: String)
    {
        userNameLabel.text = username

        // Get data from Dynamo
        getUserDynamoData(username) { (result, error) in
            if error == nil && result != nil
            {
                let resultUser = result! as User
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.realNameTextFieldLabel.text = resultUser.realname
                    self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(resultUser.accounts, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
                })
                // Get image data asynchronously (why is this in getUserDynamoData? IF we want to wait for all data to complete before displaying anything)
                getUserS3Image(username, completion: { (result, error) in
                    if error == nil
                    {
                        if result != nil
                        {
                            // Update UI on main thread
                            dispatch_async(dispatch_get_main_queue(), {
                                self.profileImageView.image = result! as UIImage
                                self.profileImageView.layer.cornerRadius = self.profileImageView.frame.width / 2
                            })

                        }
                    }
                    
                    
                    // Update UI on main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        // Generate dictionary
                        // Fill the dictionary of all social media names (key) with an image (val).
                        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
                        self.socialMediaImageDictionary = getAllPossibleSocialMediaImages(self.possibleSocialMediaNameList)
                        
                        self.socialMediaCollectionView.reloadData()
                    })
                })
            }
            
        }
        
        
        // Fetch num followers from lambda
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        var parameters = ["action":"getNumFollowers", "target": username]
        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil
            {
                print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let number = resultTask.result as? Int
                    self.numFollowersLabel.text = String(number!)
                })
                
            }
            return nil
        }
        
        // Fetch num followees from lambda
        parameters = ["action":"getNumFollowees", "target": username]
        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil
            {
                print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let number = resultTask.result as? Int
                    self.numFollowsLabel.text = String(number!)
                })
                
            }
            
            return nil
            
        }

    }
   
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keyValSocialMediaPairList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = socialMediaCollectionView.dequeueReusableCellWithReuseIdentifier("accountsCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        if (!keyValSocialMediaPairList.isEmpty)
        {
            let socialMediaPair = keyValSocialMediaPairList[indexPath.item % keyValSocialMediaPairList.count]
            let socialMediaType = socialMediaPair.socialMediaType
            let socialMediaUserName = socialMediaPair.socialMediaUserName
            
            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
            
            cell.socialMediaName = socialMediaUserName // username
            cell.socialMediaType = socialMediaType // facebook, snapchat, etc
            
            cell.emblemImage.layer.cornerRadius = cell.emblemImage.frame.width / 2
        }
        
        return cell

    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        print("SELECTED ITEM AT ", indexPath.item)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        let socialMediaUserName = cell.socialMediaName // username..
        let socialMediaType = cell.socialMediaType // "facebook", "snapchat", etc..
        
        let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)
        
        // Perform the request, go to external application and let the user do whatever they want!
        UIApplication.sharedApplication().openURL(socialMediaURL)
        
    }

    
    
}
