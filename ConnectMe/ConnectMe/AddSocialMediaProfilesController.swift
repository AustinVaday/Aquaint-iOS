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
//import SimpleAuth
import AWSDynamoDB
import SCLAlertView


protocol AddSocialMediaProfileDelegate {
  func userDidAddNewProfile(
    _ socialMediaType:String,
    socialMediaName:String
  )
}

class AddSocialMediaProfilesController: ViewControllerPannable, UITableViewDelegate, UITableViewDataSource {
  var socialMediaImageDictionary: Dictionary<String, UIImage>!
  var socialMediaUserNames: NSMutableDictionary!
  var delegate: AddSocialMediaProfileDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set up dictionary for user's social media names
    socialMediaUserNames = NSMutableDictionary()

    // Fill the dictionary of all social media names (key) with an image (val).
    // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
    socialMediaImageDictionary = getAllPossibleSocialMediaImages()

    // Set up pan gesture recognizer for when the user wants to swipe left/right
    let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
    edgePan.edges = .left
    view.addGestureRecognizer(edgePan)
  }

  override func viewDidAppear(_ animated: Bool) {
    awsMobileAnalyticsRecordPageVisitEventTrigger("AddSocialMediaProfilesController", forKey: "page_name")
  }

  func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
    if recognizer.state == .ended {
      print("Screen swiped!")
      dismiss(animated: true, completion: nil)
    }
  }

  /*************************************************************************
  *    TABLE VIEW PROTOCOL
  **************************************************************************/
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return getNumberPossibleSocialMedia()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath) as! AddSocialMediaPageTableViewCell

    print ("SELECTED:", cell.socialMediaType)

    let socialMediaType = cell.socialMediaType

    // This will store the username that will be uploaded to Dynamo
    var socialMediaName: String!

    switch (socialMediaType){
      case ?"facebook" :
        // Create alert to send to user
        let alert = UIAlertController(title: nil, message: "Are you a company?", preferredStyle: UIAlertControllerStyle.alert)
        
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action) in
          self.showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        })
        
        // Create the action to add to alert
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: { (action) in
          let login = FBSDKLoginManager.init()
          login.logOut()
          
          // Open in app instead of web browser!
          login.loginBehavior = FBSDKLoginBehavior.native
          
          // Request basic profile permissions just to get user ID. UPDATE: also get friends list for 'find friends via facebook' feature
          login.logIn(withPublishPermissions: ["public_profile", "user_friends" /*, "manage_pages"*/], from: self) { (result, error) in
            // If no error, store facebook user ID
            if (error == nil && result != nil) {
              print("SUCCESS LOG IN!", result.debugDescription)
              print(result?.description)
              
            
              print("RESULTOO: ", result)
              if (FBSDKAccessToken.current() != nil) {
                print("FBSDK userID is:", FBSDKAccessToken.current().userID)
                
                let fbUID = FBSDKAccessToken.current().userID
                let currentUserName = getCurrentCachedUser()
                
                // Needed for 'find friends via facebook' feature
                uploadUserFBUIDToDynamo(currentUserName, fbUID: fbUID)
                
                socialMediaName = FBSDKAccessToken.current().userID
                
//                //Get user-specific data including name, email, and ID.
//                let request = FBSDKGraphRequest(graphPath: "/me/accounts", parameters: nil)
//                request.startWithCompletionHandler { (connection, result, error) in
//                  if error == nil {
//                    let resultMap = result as! Dictionary<String, Array<Dictionary<String,String>>>
//                    let dataArray = resultMap["data"]!
//                    print("PRINTING PAGES")
//                    for data in dataArray {
//                      print(data["name"])
//                    }
//                  }
//                }
                

                
                if self.delegate != nil {
                  self.delegate?.userDidAddNewProfile(
                    socialMediaType!,
                    socialMediaName: socialMediaName
                  )
                  
                  // Delay the animation because it happens too fast!
                  delay(0.2) {
                    cell.showSuccessAnimation()
                  }
                }
                login.logOut()
              }
            } else if (result == nil && error != nil) {
              print ("ERROR IS: ", error)
            } else {
              print("FAIL LOG IN")
            }
          }

        })

        // Add the action to the alert
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.show(alert, sender: nil)

        break

      case ?"twitter" :
        /*************************************************************************
        * TWITTER DATA FETCH
        **************************************************************************/
        /*
        SimpleAuth.authorize("twitter-web") { (result, error) in
          if (result == nil) {
            print("CANCELLED REQUEST")
          } else if (error == nil) {
            print ("RESULT IS: ", result)

            let jsonResult = result as! NSDictionary

            socialMediaName = jsonResult["info"]!["nickname"]! as String!
            print("Twitter username returned is: ", socialMediaName)

            // self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)

            if self.delegate != nil {
              self.delegate?.userDidAddNewProfile(
                socialMediaType,
                socialMediaName: socialMediaName
              )
              cell.showSuccessAnimation()
            }
          } else {
            print ("FAILED TO PROCESS REQUEST")
          }
        }
        break
        */
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break

      case ?"instagram" :
        // Make sure to clear Instagram cookies. This will allow users to obtain a fresh login page every time.
        clearCookies("instagram")

        /*************************************************************************
        * INSTAGRAM DATA FETCH
        **************************************************************************/
        /*
        SimpleAuth.authorize("instagram") { (result, error) in
          print("INSTAGRAM")

          if (result == nil && error == nil) {
            print("CANCELLED REQUEST")
          } else if (error == nil) {
            let jsonResult = result as! NSDictionary

            print("RESULTOO: ", jsonResult)

            socialMediaName = jsonResult["user_info"]!["username"]! as String!
            print("Instagram username returned is: ", socialMediaName)

            if self.delegate != nil {
              self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
              cell.showSuccessAnimation()
            }
          } else {
            print ("FAILED TO PROCESS REQUEST")
            print("ERROR IS: ", error)
          }

        }
        break
        */
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break

      case ?"linkedin" :
        /*************************************************************************
        * LINKEDIN DATA FETCH
        **************************************************************************/
        /*
        // Create alert to send to user
        let alert = UIAlertController(title: nil, message: "Are you a company?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (action) in
          self.showAndProcessUsernameAlert(socialMediaType, forCell: cell)
        })
        
        // Create the action to add to alert
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: { (action) in
          SimpleAuth.authorize("linkedin-web") { (result, error) in
            if (result == nil) {
              print("CANCELLED REQUEST")
            } else if (error == nil) {
              print ("RESULT IS: ", result)

              let jsonResult = result as! NSDictionary

              let profileUrl = jsonResult["raw_info"]!["siteStandardProfileRequest"]!["url"]! as String!

              if (profileUrl != nil){
                let urlArray = profileUrl.componentsSeparatedByString("id=")

                if urlArray.count == 2 {
                  print ("FIRST PART", urlArray[0])
                  print ("SECOND PART", urlArray[1])

                  // This is not a username, but a special ID linkedin generated for us.
                  socialMediaName = urlArray[1]
                  // self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)

                  if self.delegate != nil {
                    self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
                    cell.showSuccessAnimation()
                  }
                }
              }
            } else {
              print ("FAILED TO PROCESS REQUEST")
            }
          }
        })
        
        // Add the action to the alert
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.showViewController(alert, sender: nil)
        
        break
        */
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break
      

      case ?"snapchat" :
        /*************************************************************************
        * SNAPCHAT DATA FETCH
        **************************************************************************/
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break

      case ?"youtube" :
        /*************************************************************************
        * YOUTUBE DATA FETCH
        **************************************************************************/
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break

      case ?"soundcloud" :
        /*************************************************************************
        * Soundcloud DATA FETCH
        **************************************************************************/
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break
    
      case ?"ios" :
        /*************************************************************************
         * Soundcloud DATA FETCH
         **************************************************************************/
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break
      
      case ?"android" :
        /*************************************************************************
         * Soundcloud DATA FETCH
         **************************************************************************/
        showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
        break

      case ?"tumblr" :
        /*************************************************************************
        * TUMBLR DATA FETCH
        **************************************************************************/
        /*
        SimpleAuth.authorize("tumblr") { (result, error) in
          if (result == nil) {
            print("CANCELLED REQUEST")
          } else if (error == nil) {
            print ("RESULT IS: ", result)

            let jsonResult = result as! NSDictionary

            socialMediaName = jsonResult["extra"]!["raw_info"]!["name"]! as String!
            print("Tumblr username returned is: ", socialMediaName)

            //                    self.updateProfilesDynamoDB(socialMediaType, socialMediaName: socialMediaName)

            if self.delegate != nil {
              self.delegate?.userDidAddNewProfile(socialMediaType, socialMediaName: socialMediaName)
              cell.showSuccessAnimation()
            }
          } else {
            print ("FAILED TO PROCESS REQUEST")
          }
        }
        break
       */
      showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
      break
      
    case ?"website" :
      showAndProcessUsernameAlert(socialMediaType!, forCell: cell)
      break

      default:
        break
    }

    // Row was highlighted (selected), make sure to deselect the row after a few seconds
    tableView.deselectRow(at: indexPath, animated: true)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "addProfileTableViewCell") as! AddSocialMediaPageTableViewCell
    
    // Temp iOS versions, iPad white background fix < 10
    cell.backgroundColor = cell.contentView.backgroundColor;
    
    let allSocialMediaList = getAllPossibleSocialMediaList()
    let socialMediaType = allSocialMediaList[indexPath.item % allSocialMediaList.count]

    // Generate a UI image for the respective social media type
    cell.emblemImage.image = socialMediaImageDictionary[socialMediaType]

    cell.socialMediaType = socialMediaType
    
    
    cell.socialMediaTypeLabel.text = getSocialMediaDisplayName(socialMediaType)

    // Make cell image circular
    cell.emblemImage.layer.cornerRadius = cell.emblemImage.frame.width / 2

    // Change background color of a selected cell
    let selectionColorView = UIView()
    selectionColorView.backgroundColor = UIColor(
      red: 0.06,
      green: 0.48,
      blue: 0.62,
      alpha: 1.0
    )
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
  
  

  @IBAction func backButtonClicked(_ sender: AnyObject) {
    /* It's good to dismiss it, but in this case we want to
      refresh the collection view on the previous page
     when we go back. So instead, we will use an unwind action. */

    // self.dismissViewControllerAnimated(true, completion: nil)
  }

  func usernameTextFieldDidChange(_ textField: UITextField) {
    let usernameString = textField.text?.lowercased()
    textField.text = removeAllNonAlphaNumeric(
      usernameString!,
      charactersToKeep: "_-."
    )
  }

  fileprivate func showAndProcessUsernameAlert(_ socialMediaType: String, forCell: AddSocialMediaPageTableViewCell) {
    var alertViewResponder: SCLAlertViewResponder!
    let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 70))
    let x = (subview.frame.width - 180) / 2
    let colorDarkBlue = UIColor(
      red:  0.06,
      green: 0.48,
      blue: 0.62,
      alpha: 1.0
    )

    // Add text field for username
    let textField = UITextField(frame: CGRect(x: x,y: 10,width: 180,height: 25))

    // textField.layer.borderColor = colorLightBlue.CGColor
    // textField.layer.borderWidth = 1.5
    // textField.layer.cornerRadius = 5
    textField.font          = UIFont(name: "Avenir Roman", size: 14.0)
    textField.textColor     = colorDarkBlue
    textField.textAlignment = NSTextAlignment.center
    textField.autocorrectionType = .no
    textField.autocapitalizationType = .none
    
    if socialMediaType == "website" {
      textField.placeholder   = "Enter Website URL"
    } else if socialMediaType == "ios" {
      textField.placeholder = "Enter App Store URL"
    } else if socialMediaType == "android" {
      textField.placeholder = "Enter Play Store URL"
    } else if socialMediaType == "linkedin" {
      textField.placeholder = "Enter Personal Profile URL"  // example: https://www.linkedin.com/in/yingbo-wang-104b12b3/
    } else if socialMediaType == "tumblr" {
      textField.placeholder = "Enter Nickname"  // example: yeshelloworldthings
    } else {
      textField.placeholder = "Enter Username"
      // twitter example: wybmax
      // instagram example: wybmax
      
      // Add target to text field to validate/fix user input of a proper input
      textField.addTarget(
        self,
        action: #selector(usernameTextFieldDidChange),
        for: UIControlEvents.editingChanged
      )
    }
    
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
    alertView.addButton(
      "Save",
      action: {
        print("Save button clicked for textField data:", textField.text)

        if alertViewResponder == nil {
          print("Something went wrong...")
          return
        }

        let username = textField.text!

        if username.isEmpty {
          // TODO: Nothing?
        } else if username.characters.count > 100 {
          dispatch_async(dispatch_get_main_queue(), {
            showAlert("Too long entry", message: "Please enter a valid entry", buttonTitle: "Try again", sender: self)
          })
          
          alertViewResponder.close()
          alertViewResponder.close()
        } else {
          var socialMediaName = username
          print(socialMediaType, " username returned is: ", socialMediaName)
          
          
          if socialMediaType == "website" || socialMediaType == "ios" || socialMediaType == "android" || socialMediaType == "linkedin"
          {
            // If website url does not have 'http://' or 'https://', add http:// it in
            if !socialMediaName.hasPrefix("http://") && !socialMediaName.hasPrefix("https://") {
              socialMediaName = "http://" + socialMediaName
            }
            
            // With android apps, URL is tough to check because of the 'com.appName' url scheme. Instead check for google.com domain
            if socialMediaType == "android" {
              if !socialMediaName.containsString("google.com") && !socialMediaName.containsString("goo.gl") {
                showAlert("Invalid Play Store URL", message: "Please enter a valid Android Play Store URL", buttonTitle: "Try again", sender: self)
                alertViewResponder.close()
                return
              }
            }
            else if !verifyUrl(socialMediaName){
              
                dispatch_async(dispatch_get_main_queue(), {
                  showAlert("Invalid Website URL", message: "Please enter a valid URL", buttonTitle: "Try again", sender: self)
                })
              
              alertViewResponder.close()
              return 
            }
          }
          // TODO: separate Linkedin company page support should be added after implementing OAuth2 authentication
          /*
          else if socialMediaType == "linkedin" {
            // LinkedIn requires company/ before all company names. So this should only be appended for company accounts
            socialMediaName = "company/" + socialMediaName
            
          }
          */
          
          if self.delegate != nil {
            self.delegate?.userDidAddNewProfile(
              socialMediaType,
              socialMediaName: socialMediaName
            )
            forCell.showSuccessAnimation()
          }
          alertViewResponder.close()
        }
      }
    )

    let alertViewIcon = UIImage(named: socialMediaType)

    alertViewResponder = alertView.showTitle(getSocialMediaDisplayName(socialMediaType),
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
  fileprivate func updateProfilesDynamoDB(_ socialMediaType: String!, socialMediaName: String!) {
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    let currentUser = getCurrentCachedUser()
    let currentRealName = getCurrentCachedFullName()
    let currentAccounts = getCurrentCachedUserProfiles() as NSMutableDictionary

    // update only if user requests to
    if (socialMediaName != nil) {
      /********************************
      *  UPLOAD USER DATA TO DYNAMODB
      ********************************/
      // Update account data

      // If user does not have a particular social media type,
      // we need to create a list
      print("Accounts data was: ", currentAccounts)

      if (currentAccounts.value(forKey: socialMediaType) == nil) {
        currentAccounts.setValue(
          [ socialMediaName ],
          forKey: socialMediaType
        )
      } else { // If it already exists, append value to end of list
        var list = currentAccounts.value(forKey: socialMediaType) as! Array<String>
        list.append(socialMediaName)

        currentAccounts.setValue(list, forKey: socialMediaType)
      }

      print("Accounts data is now: ", currentAccounts)

      // Upload user DATA to DynamoDB
      let dynamoDBUser = User()

      dynamoDBUser?.username = currentUser
      dynamoDBUser?.realname = currentRealName
      dynamoDBUser?.accounts = currentAccounts

      dynamoDBObjectMapper.save(dynamoDBUser!).continue(
        { (resultTask) -> AnyObject? in
          if (resultTask.error != nil) {
            print ("DYNAMODB ADD PROFILE ERROR: ", resultTask.error)
          }

          if (resultTask.exception != nil) {
            print ("DYNAMODB ADD PROFILE EXCEPTION: ", resultTask.exception)
          }

          if (resultTask.result == nil) {
            print ("DYNAMODB ADD PROFILE result is nil....: ")
          } else if (resultTask.error == nil) {
            // If successful save
            print ("DYNAMODB ADD PROFILE SUCCESS: ", resultTask.result)

            // Also cache accounts data
            setCurrentCachedUserProfiles(currentAccounts)

            // Refresh something...
          }
          return nil
        }
      )
    }
  }
}
