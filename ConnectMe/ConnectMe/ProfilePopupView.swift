//
//  ProfilePopupView.swift
//  Aquaint
//
//  Created by Austin Vaday on 8/23/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda

// Used to enforce consistency of buttons between popup and search table view cell
protocol ProfilePopupSearchCellConsistencyDelegate {
  func profilePopupUserAdded(username: String, isPrivate: Bool)
  func profilePopupUserDeleted(username: String, isPrivate: Bool)
}

class ProfilePopupView: UIView, UICollectionViewDelegate, UICollectionViewDataSource{

    @IBOutlet weak var realNameTextFieldLabel: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var numFollowersLabel: UILabel!
    @IBOutlet weak var numFollowsLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var socialMediaCollectionView: UICollectionView!
    @IBOutlet weak var cellAddButton: UIButton!
    @IBOutlet weak var cellDeleteButton: UIButton!
    @IBOutlet weak var cellPendingButton: UIButton!
    @IBOutlet weak var noProfilesLinkedLabel: UITextField!
    @IBOutlet weak var privateProfileView: UIView!
  
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
    var me: String!
    var displayPrivate = false
    var popupSearchConsistencyDelegate : ProfilePopupSearchCellConsistencyDelegate?
    var GApageName: String!
  
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
  
    func setDataForUser(username: String, me: String)
    {
        // Send view trigger (Profile Views) to Google analytics
        print("Popup profile initiated!")
        let tracker = GAI.sharedInstance().defaultTracker
        GApageName = "/user/" + username + "/iOS"
        tracker.set(kGAIPage, value: GApageName)
      
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
      
        userNameLabel.text = username
        self.me = me
      
        // Determine whether "me" follows user or not
        var lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        var parameters = ["action":"doIFollow", "me": self.me, "target": username]
      
        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
          if resultTask.error == nil && resultTask.result != nil
          {
            
              let doIFollow = resultTask.result as? Int
              if doIFollow == 1 {
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                  self.activateDeleteButton()
                })
              }
            
            
            parameters = ["action":"didISendFollowRequest", "me": self.me, "target": username]
            lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
              if resultTask.error == nil && resultTask.result != nil {
                let didISendRequest = resultTask.result as? Int
                if didISendRequest == 1 {
                  // Update UI on main thread
                  dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.activatePendingButton()
                  })
                }
              }
              return nil
            }
            
            // Get data from Dynamo
            getUserDynamoData(username) { (result, error) in
              if error == nil && result != nil
              {
                let resultUser = result! as UserPrivacyObjectModel
                
                // CHECK IF USER IS PRIVATE and if we do not follow user (and if we are not that user)
                if resultUser.isprivate != nil && resultUser.isprivate == 1 &&
                    doIFollow != 1 && resultUser.username != getCurrentCachedUser() {
                  //TODO: Display a different UI
                  self.displayPrivate = true
                }
                else {
                  // User is public, continue as normal
                  self.displayPrivate = false
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
                getUserS3Image(username, extraPath: nil, completion: { (result, error) in
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
            // Call lambda to store user connectons in database! If private account, we store in follow_requests. If public, we 
            // store in follows
            var targetAction : String!
            if displayPrivate {
              targetAction = "followRequest"
            } else {
              targetAction = "follow"
            }
          
            let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
            let parameters = ["action": targetAction, "target": userNameLabel.text!, "me": currentUserName]
            
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
                      if self.displayPrivate {
                        self.activatePendingButton()
                      } else {
                        self.activateDeleteButton()
                      }
                      
                      self.popupSearchConsistencyDelegate?.profilePopupUserAdded(self.userNameLabel.text!, isPrivate: self.displayPrivate)
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
  
      func unFollowUser() {
        // Fetch current user from NSUserDefaults
        let currentUserName = me

        // If currentUser is not trying to add themselves
        if (currentUserName != userNameLabel.text!)
        {
          // Call lambda to store user connectons in database! If private account, we store in follow_requests. If public, we
          // store in follows
          var targetAction : String!
          if displayPrivate {
            targetAction = "unfollowRequest"
          } else {
            targetAction = "unfollow"
        }

        // Call lambda to store user connectons in database!
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action": targetAction, "target": userNameLabel.text!, "me": currentUserName]

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
            self.popupSearchConsistencyDelegate?.profilePopupUserDeleted(self.userNameLabel.text!, isPrivate: self.displayPrivate)
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
  
    // Note: We also link pending button to this method as well. Very functionality
    @IBAction func onDeleteConnectionButtonClicked(sender: AnyObject) {

          self.unFollowUser()
          // ISSUE WITH BELOW: Cannot present view controller on top of a popup....
//        // Add in action sheet to have user verify if they want to delete
//        let optionMenu = UIAlertController(title: "Are you sure you want to unfollow this person?", message: "", preferredStyle: .ActionSheet)
//        let unfollowAction = UIAlertAction(title: "Unfollow", style: .Destructive) { (alert) in
//          // Unfollow code here
//          self.unFollowUser()
//        }
//      
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//      
//        optionMenu.addAction(unfollowAction)
//        optionMenu.addAction(cancelAction)
//      
//        self.superview.presentViewController(optionMenu, animated: true, completion: nil)
      
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
          
            // Create a faded emblem if private account
            if displayPrivate {
                cell.emblemImage.alpha = 0.25
                self.socialMediaCollectionView.hidden = true
                self.privateProfileView.hidden = false
            } else {
              cell.emblemImage.alpha = 1
              self.socialMediaCollectionView.hidden = false
              self.privateProfileView.hidden = true
            }
        }
        
        return cell

    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
      
      // Do not let users click on profiles if private setting
      if !displayPrivate {
        print("SELECTED ITEM AT ", indexPath.item)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        let socialMediaUserName = cell.socialMediaName // username..
        let socialMediaType = cell.socialMediaType // "facebook", "snapchat", etc..
        
        let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)
        
        // Send trigger to Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIPage, value: GApageName)
        let builder = GAIDictionaryBuilder.createEventWithCategory("SocialClicksMobile", action: "click", label: cell.socialMediaType, value: nil)
        tracker.send(builder.build() as [NSObject : AnyObject])
        
        // Perform the request, go to external application and let the user do whatever they want!
        if socialMediaURL != nil
        {
            UIApplication.sharedApplication().openURL(socialMediaURL)
        }
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

  private func activatePendingButton()
  {
    cellDeleteButton.superview?.bringSubviewToFront(cellPendingButton)
  }

  @IBAction func viewFollowersButtonClicked(sender: AnyObject) {
    showViewController("getFollowers")
  }
  
  @IBAction func viewFollowingButtonClicked(sender: AnyObject) {
    showViewController("getFollowees")
  }
  
  func showViewController(lambdaAction: String) {
    // Let's use a re-usable view just for viewing user follows/followings!
    let storyboard = UIStoryboard(name: "PopUpAlert", bundle: nil)
    let viewController = storyboard.instantiateViewControllerWithIdentifier("AquaintsSingleFollowerListViewController") as! AquaintsSingleFollowerListViewController
    viewController.currentUserName = self.userNameLabel.text
    viewController.lambdaAction = lambdaAction
    viewController.profilePopupView = self
    
    // Fetch VC on top view
    var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
    while ((topVC!.presentedViewController) != nil) {
      topVC = topVC!.presentedViewController
    }
    
    // Note: Need to dismiss this popup so we can display another VC. We will restore the popup later,
    // which is why we pass in this class and it's data to the next view controller. 
    self.dismissPresentingPopup()
    topVC?.presentViewController(viewController, animated: true, completion: nil)

  }
  
  
}
