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
import SCLAlertView


protocol AddSocialMediaProfileDelegate {
    func userDidAddNewProfile(socialMediaType:String, socialMediaName:String)
}

class AddSocialMediaProfilesController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var delegate: AddSocialMediaProfileDelegate?
    
    override func viewDidLoad() {
       
        // Set up dictionary for user's social media names
        socialMediaUserNames = NSMutableDictionary()
            
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()
        
        // Set up pan gesture recognizer for when the user wants to swipe left/right
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .Left
        view.addGestureRecognizer(edgePan)
    
    }
    
    
    func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == .Ended
        {
            print("Screen swiped!")
            dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    /*************************************************************************
     *    TABLE VIEW PROTOCOL
     **************************************************************************/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNumberPossibleSocialMedia()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddSocialMediaPageTableViewCell
        
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
            //            SimpleAuth.authorize("facebook") { (result, error) in
            //
            //                print("ERROR IS: ", error)
            //                if (result == nil)
            //                {
            //                    print("CANCELLED REQUEST")
            //                }
            //                else if (error == nil)
            //                {
            //                    print ("RESULT IS: ", result)
            //
            //                    let jsonResult = result as! NSDictionary
            //
            //                    // Get user's nickname from JSON object returned. I.e:
            //                    // info
            //                    // {
            //                    //    nickname = "AustinVaday";
            //                    //    ...
            //                    // }
            //
            ////                    socialMediaName = jsonResult["info"]!["nickname"]! as String!
            ////                    print("Twitter username returned is: ", socialMediaName)
            ////
            ////                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
            //
            //                }
            //                else
            //                {
            //                    print ("FAILED TO PROCESS REQUEST")
            //                }
            //
            //            }
            
            
            
            
            let login = FBSDKLoginManager.init()
            login.logOut()
            
            // Open in app instead of web browser!
            login.loginBehavior = FBSDKLoginBehavior.Native
            
            // Request basic profile permissions just to get user ID
            login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
                
                // If no error, store facebook user ID
                if (error == nil && result != nil)
                {
                    print("SUCCESS LOG IN!", result.debugDescription)
                    print(result.description)
                    
                    print("RESULTOO: ", result)
                    
                    if (FBSDKAccessToken.currentAccessToken() != nil)
                    {
                        print("FBSDK userID is:", FBSDKAccessToken.currentAccessToken().userID)
                        
                        socialMediaName = FBSDKAccessToken.currentAccessToken().userID
                        
                        if self.delegate != nil
                        {
                            self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                            
                            // Delay the animation because it happens too fast!
                            delay(0.2)
                            {
                                cell.showSuccessAnimation()
                            }
                        }
                        
                        
                        login.logOut()
                    }
                    
                    
                    
                }
                else if (result == nil && error != nil)
                {
                    print ("ERROR IS: ", error)
                }
                else
                {
                    print("FAIL LOG IN")
                }
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
                    
                    let jsonResult = result as! NSDictionary
                    
                    socialMediaName = jsonResult["info"]!["nickname"]! as String!
                    print("Twitter username returned is: ", socialMediaName)
                    
                    //                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
                    
                    if self.delegate != nil
                    {
                        self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                        cell.showSuccessAnimation()

                    }
                    
                }
                else
                {
                    print ("FAILED TO PROCESS REQUEST")
                }
                
            }
            
            
            break
        case "instagram" :
            
            // Make sure to clear Instagram cookies. This will allow users to obtain a fresh login page every time.
            clearCookies("instagram")
            
            /*************************************************************************
             * INSTAGRAM DATA FETCH
             **************************************************************************/
            SimpleAuth.authorize("instagram") { (result, error) in
                
                print("INSTAGRAM")
                
                if (result == nil && error == nil)
                {
                    print("CANCELLED REQUEST")
                }
                else if (error == nil)
                {
                    let jsonResult = result as! NSDictionary
                    
                    print("RESULTOO: ", jsonResult)

                    socialMediaName = jsonResult["user_info"]!["username"]! as String!
                    print("Instagram username returned is: ", socialMediaName)
                    
                    if self.delegate != nil
                    {
                        self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                        cell.showSuccessAnimation()

                    }
                    
                }
                else
                {
                    
                    print ("FAILED TO PROCESS REQUEST")
                    print("ERROR IS: ", error)
                    
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
                    
                    let profileUrl = jsonResult["raw_info"]!["siteStandardProfileRequest"]!["url"]! as String!
                    
                    
                    if (profileUrl != nil)
                    {
                        let urlArray = profileUrl.componentsSeparatedByString("id=")
                        
                        if urlArray.count == 2
                        {
                            print ("FIRST PART", urlArray[0])
                            print ("SECOND PART", urlArray[1])
                            
                            // This is not a username, but a special ID linkedin generated for us.
                            socialMediaName = urlArray[1]
                            //                            self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
                            
                            if self.delegate != nil
                            {
                                self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                                cell.showSuccessAnimation()
                            }
                            
                        }
                    }
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
            showAndProcessUsernameAlert(socialMediaType, forCell: cell)
            
            break
        case "youtube" :
            /*************************************************************************
             * YOUTUBE DATA FETCH
             **************************************************************************/
            showAndProcessUsernameAlert(socialMediaType, forCell: cell)
            
            break
            
        case "soundcloud" :
            /*************************************************************************
             * Soundcloud DATA FETCH
             **************************************************************************/
            showAndProcessUsernameAlert(socialMediaType, forCell: cell)
            
            break

        case "tumblr" :
            /*************************************************************************
             * TUMBLR DATA FETCH
             **************************************************************************/
            SimpleAuth.authorize("tumblr") { (result, error) in
                
                if (result == nil)
                {
                    print("CANCELLED REQUEST")
                }
                else if (error == nil)
                {
                    print ("RESULT IS: ", result)
                    
                    let jsonResult = result as! NSDictionary
                    
                    socialMediaName = jsonResult["extra"]!["raw_info"]!["name"]! as String!
                    print("Tumblr username returned is: ", socialMediaName)
                    
                    //                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
                    
                    if self.delegate != nil
                    {
                        self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                        
                        cell.showSuccessAnimation()
                    }
                    
                    
                }
                else
                {
                    print ("FAILED TO PROCESS REQUEST")
                }
                
            }
            
            break
        default:
            
            
            break
            
        }
        
        
        // Row was highlighted (selected), make sure to deselect the row after a few seconds
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addProfileTableViewCell") as! AddSocialMediaPageTableViewCell
        
        let allSocialMediaList = getAllPossibleSocialMediaList()
        let socialMediaType = allSocialMediaList[indexPath.item % allSocialMediaList.count]
        
        // Generate a UI image for the respective social media type
        cell.emblemImage.image = socialMediaImageDictionary[socialMediaType]
        
        cell.socialMediaType = socialMediaType
        cell.socialMediaTypeLabel.text = socialMediaType.capitalizedString
        
        // Make cell image circular
        cell.emblemImage.layer.cornerRadius = cell.emblemImage.frame.width / 2
        
        // Change background color of a selected cell
        let selectionColorView = UIView()
        selectionColorView.backgroundColor = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        cell.selectedBackgroundView = selectionColorView
        
        return cell

    }
    
    
//    /*************************************************************************
//    *    COLLECTION VIEW PROTOCOL
//    **************************************************************************/
//    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return getNumberPossibleSocialMedia()
//    }
//    
//    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//       
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
//        
//        print ("SELECTED:", cell.socialMediaType)
//        
//        let socialMediaType = cell.socialMediaType
//        
//        // This will store the username that will be uploaded to Dynamo
//        var socialMediaName: String!
//        
//        switch (socialMediaType)
//        {
//        case "facebook" :
//            /*************************************************************************
//             * FACEBOOK DATA FETCH
//             **************************************************************************/
////            SimpleAuth.authorize("facebook") { (result, error) in
////                
////                print("ERROR IS: ", error)
////                if (result == nil)
////                {
////                    print("CANCELLED REQUEST")
////                }
////                else if (error == nil)
////                {
////                    print ("RESULT IS: ", result)
////                    
////                    let jsonResult = result as! NSDictionary
////                    
////                    // Get user's nickname from JSON object returned. I.e:
////                    // info
////                    // {
////                    //    nickname = "AustinVaday";
////                    //    ...
////                    // }
////                    
//////                    socialMediaName = jsonResult["info"]!["nickname"]! as String!
//////                    print("Twitter username returned is: ", socialMediaName)
//////                    
//////                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
////                    
////                }
////                else
////                {
////                    print ("FAILED TO PROCESS REQUEST")
////                }
////                
////            }
//
//            
//            
//
//                let login = FBSDKLoginManager.init()
//                login.logOut()
//                
//                // Open in app instead of web browser!
//                login.loginBehavior = FBSDKLoginBehavior.Native
//                
//                // Request basic profile permissions just to get user ID
//                login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
//                    
//                    // If no error, store facebook user ID
//                    if (error == nil && result != nil)
//                    {
//                        print("SUCCESS LOG IN!", result.debugDescription)
//                        print(result.description)
//                        
//                        if (FBSDKAccessToken.currentAccessToken() != nil)
//                        {
//                            print("FBSDK userID is:", FBSDKAccessToken.currentAccessToken().userID)
//                            
//                            socialMediaName = FBSDKAccessToken.currentAccessToken().userID
//                            
//                            if self.delegate != nil
//                            {
//                                self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
//                            }
//
//                        
//                            login.logOut()
//                        }
//                        
//                        
//
//                    }
//                    else if (result == nil && error != nil)
//                    {
//                        print ("ERROR IS: ", error)
//                    }
//                    else
//                    {
//                        print("FAIL LOG IN")
//                    }
//                }
//            
//        
//            
//            break
//        case "twitter" :
//            /*************************************************************************
//             * TWITTER DATA FETCH
//             **************************************************************************/
//            SimpleAuth.authorize("twitter-web") { (result, error) in
//                
//                if (result == nil)
//                {
//                    print("CANCELLED REQUEST")
//                }
//                else if (error == nil)
//                {
//                    print ("RESULT IS: ", result)
//                    
//                    let jsonResult = result as! NSDictionary
//                    
//                    socialMediaName = jsonResult["info"]!["nickname"]! as String!
//                    print("Twitter username returned is: ", socialMediaName)
//                    
////                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
//                    
//                    if self.delegate != nil
//                    {
//                        self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
//                    }
//                    
//                }
//                else
//                {
//                    print ("FAILED TO PROCESS REQUEST")
//                }
//                
//            }
//
//            
//            break
//        case "instagram" :
//            
//            // Make sure to clear Instagram cookies. This will allow users to obtain a fresh login page every time.
//            clearCookies("instagram")
//            
//            /*************************************************************************
//             * INSTAGRAM DATA FETCH
//             **************************************************************************/
//            SimpleAuth.authorize("instagram") { (result, error) in
//                
//                print("INSTAGRAM")
//
//                if (result == nil && error == nil)
//                {
//                    print("CANCELLED REQUEST")
//                }
//                else if (error == nil)
//                {
//                    let jsonResult = result as! NSDictionary
//                    
//                    socialMediaName = jsonResult["user_info"]!["username"]! as String!
//                    print("Instagram username returned is: ", socialMediaName)
//                    
//                    if self.delegate != nil
//                    {
//                        self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
//                    }
//                    
//                }
//                else
//                {
//                    
//                    print ("FAILED TO PROCESS REQUEST")
//                    print("ERROR IS: ", error)
//
//                }
//                
//            }
//
//            
//            break
//        case "linkedin" :
//            /*************************************************************************
//             * LINKEDIN DATA FETCH
//             **************************************************************************/
//            SimpleAuth.authorize("linkedin-web") { (result, error) in
//                
//                if (result == nil)
//                {
//                    print("CANCELLED REQUEST")
//                }
//                else if (error == nil)
//                {
//                    print ("RESULT IS: ", result)
//                    
//                    let jsonResult = result as! NSDictionary
//                    
//                    let profileUrl = jsonResult["raw_info"]!["siteStandardProfileRequest"]!["url"]! as String!
//
//                    
//                    if (profileUrl != nil)
//                    {
//                        let urlArray = profileUrl.componentsSeparatedByString("id=")
//                        
//                        if urlArray.count == 2
//                        {
//                            print ("FIRST PART", urlArray[0])
//                            print ("SECOND PART", urlArray[1])
//                            
//                            // This is not a username, but a special ID linkedin generated for us.
//                            socialMediaName = urlArray[1]
////                            self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
//                            
//                            if self.delegate != nil
//                            {
//                                self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
//                            }
//                            
//                        }
//                    }
//                }
//                else
//                {
//                    print ("FAILED TO PROCESS REQUEST")
//                }
//                
//            }
//
//            break
//        case "snapchat" :
//            /*************************************************************************
//             * SNAPCHAT DATA FETCH
//             **************************************************************************/
//            showAndProcessUsernameAlert(socialMediaType)
//            
//            break
//        case "youtube" :
//            /*************************************************************************
//             * YOUTUBE DATA FETCH
//             **************************************************************************/
//            showAndProcessUsernameAlert(socialMediaType)
//
//            
//            break
//        case "tumblr" :
//            /*************************************************************************
//             * TUMBLR DATA FETCH
//             **************************************************************************/
//            SimpleAuth.authorize("tumblr") { (result, error) in
//                
//                if (result == nil)
//                {
//                    print("CANCELLED REQUEST")
//                }
//                else if (error == nil)
//                {
//                    print ("RESULT IS: ", result)
//                    
//                    let jsonResult = result as! NSDictionary
//                    
//                    socialMediaName = jsonResult["extra"]!["raw_info"]!["name"]! as String!
//                    print("Tumblr username returned is: ", socialMediaName)
//                    
////                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)
//                    
//                    if self.delegate != nil
//                    {
//                        self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
//                    }
//                }
//                else
//                {
//                    print ("FAILED TO PROCESS REQUEST")
//                }
//                
//            }
//            
//            break
//        default:
//            
//            
//            break
//        
//        }
//        
//        
//    }
    
//    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("addProfileCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
//    
//        let allSocialMediaList = getAllPossibleSocialMediaList()
//        let socialMediaType = allSocialMediaList[indexPath.item % allSocialMediaList.count]
//        
//        // Generate a UI image for the respective social media type
//        cell.emblemImage.image = socialMediaImageDictionary[socialMediaType]
//        
//        cell.socialMediaType = socialMediaType
//        
//        // Make cell image circular
//        cell.layer.cornerRadius = cell.frame.width / 2
//        
//        return cell
//    }

    @IBAction func backButtonClicked(sender: AnyObject) {

        
        // It's good to dismiss it, but in this case we want to 
        // refresh the collection view on the previous page
        // when we go back. So instead, we will use an unwind action.
//        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func usernameTextFieldDidChange(textField: UITextField)
    {
        let usernameString = textField.text?.lowercaseString
        
        textField.text = removeAllNonAlphaNumeric(usernameString!, charactersToKeep: "_-")
    }
    
    
    private func showAndProcessUsernameAlert(socialMediaType: String, forCell: AddSocialMediaPageTableViewCell)
    {
        var alertViewResponder: SCLAlertViewResponder!
        let subview = UIView(frame: CGRectMake(0,0,216,70))
        let x = (subview.frame.width - 180) / 2
        let colorDarkBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        
        // Add text field for username
        let textField = UITextField(frame: CGRectMake(x,10,180,25))
        
        //            textField.layer.borderColor = colorLightBlue.CGColor
        //            textField.layer.borderWidth = 1.5
        //            textField.layer.cornerRadius = 5
        textField.font = UIFont(name: "Avenir Roman", size: 14.0)
        textField.textColor = colorDarkBlue
        textField.placeholder = "Enter Username"
        textField.textAlignment = NSTextAlignment.Center
        
        // Add target to text field to validate/fix user input of a proper input
        textField.addTarget(self, action: #selector(usernameTextFieldDidChange), forControlEvents: UIControlEvents.EditingChanged)
        subview.addSubview(textField)
        
        let alertAppearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 60,
            kCircleHeight: 55,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
            
        )
        
        let alertView = SCLAlertView(appearance: alertAppearance)
        
        alertView.customSubview = subview
        alertView.addButton("Save", action: {
            print("Save button clicked for textField data:", textField.text)
            
            if alertViewResponder == nil
            {
                print("Something went wrong...")
                return
            }
            
            let username = textField.text!
            
            if username.isEmpty
            {
                //TODO: Nothing?
            }
            else if username.characters.count > 30
            {
                //TODO: Notify that username is too long
                alertViewResponder.close()
                
            }
            else
            {
                
                let socialMediaName = username
                print(socialMediaType, " username returned is: ", socialMediaName)
                
                if self.delegate != nil
                {
                    self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                    forCell.showSuccessAnimation()

                }
                
                alertViewResponder.close()
                
            }
            
            
        })
        
        let alertViewIcon = UIImage(named: socialMediaType)

        alertViewResponder = alertView.showTitle(socialMediaType.capitalizedString,
                                                 subTitle: "",
                                                 duration:0.0,
                                                 completeText: "Cancel",
                                                 style: .Success,
                                                 colorStyle: 0x0F7A9D,
                                                 colorTextButton: 0xFFFFFF,
                                                 circleIconImage: alertViewIcon,
                                                 animationStyle: .BottomToTop
        )
    }
    
    
    // The below function is too specific -- see general one
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
