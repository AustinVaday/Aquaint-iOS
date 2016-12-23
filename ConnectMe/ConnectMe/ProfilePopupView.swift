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
    @IBOutlet weak var cellAddButton: UIButton!
    @IBOutlet weak var cellDeleteButton: UIButton!
    @IBOutlet weak var noProfilesLinkedLabel: UITextField!
  
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
    var me: String!
  
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
  
    func setDataForUser(username: String, me: String)
    {
        userNameLabel.text = username
        self.me = me
      
        // Get data from Dynamo
        getUserDynamoData(username) { (result, error) in
            if error == nil && result != nil
            {
                let resultUser = result! as UserPrivacyObjectModel
              
              // CHECK IF USER IS PRIVATE.
              if resultUser.isprivate != nil && resultUser.isprivate == 1 {
                //TODO: Display a different UI
              }
              else {
                // User is public, continue as normal
              }
              
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.realNameTextFieldLabel.text = resultUser.realname
                    
                    if resultUser.accounts != nil
                    {
                        self.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(resultUser.accounts)
                        self.noProfilesLinkedLabel.hidden = true
                    }
                    else
                    {
                        self.keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
                        self.noProfilesLinkedLabel.hidden = false
                    }
                
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
                        self.socialMediaImageDictionary = getAllPossibleSocialMediaImages()
                                              
                        self.socialMediaCollectionView.reloadData()
                    })
                })
            }
            
        }
        
        // Determine whether "me" follows user or not
        var lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        var parameters = ["action":"doIFollow", "me": self.me, "target": username]
        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil
            {
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let doIFollow = resultTask.result as? Int
                    if (doIFollow == 1)
                    {
                        self.activateDeleteButton()
                    }
//                    else
//                    {
//                        self.activateAddButton()
//                    }
                })
                
            }
            return nil
        }
        
        // Fetch num followers from lambda
        lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        parameters = ["action":"getNumFollowers", "target": username]
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
  
    @IBAction func onAddConnectionButtonClicked(sender: AnyObject) {
        // Fetch current user from NSUserDefaults
        let currentUserName = self.me
        
        // If currentUser is not trying to add themselves
        if (currentUserName != userNameLabel.text!)
        {
            // Call lambda to store user connectons in database!
            let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
            let parameters = ["action": "follow", "target": userNameLabel.text!, "me": currentUserName]
            
            lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock({ (resultTask) -> AnyObject? in
                
                if resultTask.error != nil
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
                }
                else if resultTask.exception != nil
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
                    
                }
                else if resultTask.result != nil
                {
                    // Perform update on UI on main thread
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.activateDeleteButton()
                    })
                }
                else
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                }
                
                return nil
                
            })
            
        }

    }

    @IBAction func onDeleteConnectionButtonClicked(sender: AnyObject) {
        // Fetch current user from NSUserDefaults
        let currentUserName = me
        
        // If currentUser is not trying to add themselves
        if (currentUserName != userNameLabel.text!)
        {
            // Call lambda to store user connectons in database!
            let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
            let parameters = ["action": "unfollow", "target": userNameLabel.text!, "me": currentUserName]
            
            lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock({ (resultTask) -> AnyObject? in
                
                if resultTask.error != nil
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
                }
                else if resultTask.exception != nil
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
                    
                }
                else if resultTask.result != nil
                {
                    // Perform update on UI on main thread
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.activateAddButton()
                    })  
                }
                else
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                    
                }
                
                return nil
                
            })
            
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
        if socialMediaURL != nil
        {
            UIApplication.sharedApplication().openURL(socialMediaURL)
        }
    }
  
  private func activateAddButton()
  {
    cellAddButton.superview?.bringSubviewToFront(cellAddButton)
    
  }
  
  private func activateDeleteButton()
  {
    cellDeleteButton.superview?.bringSubviewToFront(cellDeleteButton)
  }


  
  
}
