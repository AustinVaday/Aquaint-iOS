//
//  NewsfeedViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSLambda
import FRHyperLabel

class NewsfeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {

    let cellIdentifier = "newsfeedCell"
    @IBOutlet weak var newsfeedTableView: UITableView!
    @IBOutlet weak var noContentMessageView: UIView!
    @IBOutlet weak var emblemButton: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var aquaintNewsfeed : Array<NewsfeedEntry>!
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var refreshControl : UIRefreshControl!
//    var connectionList : Array<Connection>!
    var defaultImage : UIImage!
    var newsfeedList : NSArray! // Array of dictionary to hold all newsfeed data
    var expansionObj:CellExpansion!
    var animatedObjects : Array<UIView>!
    var shouldShowAnimations = false
    
    
    override func viewDidAppear(animated: Bool) {
        if shouldShowAnimations && newsfeedList.count == 0
        {
            noContentMessageView.hidden = false
            newsfeedTableView.hidden = true
            setUpAnimations(self)
        }
        
    }
    
    // Remove animations after user leaves page. Prevents post-animation stale objects
    override func viewDidDisappear(animated: Bool) {
        clearUpAnimations()
        noContentMessageView.hidden = true
        newsfeedTableView.hidden = false
    }
    
    
    @IBAction func onUserClickedAquaintButton(sender: UIButton) {
        
        
        print("Button intended was clicked")
    }
    
    @IBAction func onUserClickedSubArea(sender: AnyObject) {
        // Animate one of our embles out
        addSingleEmblemAnimation(self.view.frame.width)
    }
    
    override func viewDidLoad() {
        makeViewShine(emblemButton.imageView!)

        print ("VIEW LOADED")
        newsfeedList = NSArray()
        aquaintNewsfeed = Array<NewsfeedEntry>()
        animatedObjects = Array<UIView>()
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()
        
        // Fetch the user's username
        currentUserName = getCurrentCachedUser()
        
        expansionObj = CellExpansion()

        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()
        
        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(NewsfeedViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        newsfeedTableView.addSubview(refreshControl)
        
        generateData()
        
    }
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
        newsfeedTableView.addSubview(refreshControl)
        
        generateData()
        // Need to end refreshing
        delay(0.5)
        {
            self.refreshControl.endRefreshing()
        }
    }
    
    
    
    // TABLE VIEW
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        // Extra check to wait for trigger until showing animations
        if shouldShowAnimations
        {
            if aquaintNewsfeed.count == 0
            {
                noContentMessageView.hidden = false
                newsfeedTableView.hidden = true
                setUpAnimations(self)
            }
            else
            {
                noContentMessageView.hidden = true
                newsfeedTableView.hidden = false
                clearUpAnimations()
            }
        }
        
    
        return aquaintNewsfeed.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! NewsfeedTableViewCell
        let newsfeedObject = aquaintNewsfeed[indexPath.row]
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        cell.sponsoredProfileImageButton.layer.cornerRadius = cell.sponsoredProfileImageButton.frame.size.width / 2
        
        // Set user image and profiles
        cell.cellImage.image = newsfeedObject.displayImage

        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        cell.collectionView.tag = indexPath.row
        
        // Set time dif of event on the cell
        cell.cellTimeConnected.text = computeTimeDiffFromNow(newsfeedObject.timestamp)
        
        switch newsfeedObject.event
        {
            // If someone I follow starts following another person
            case "newfollowing":
                
                let user = newsfeedObject.user
                let otherUsers = newsfeedObject.other
                let otherUser = otherUsers[0] as! String
                
                let handlerUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(user)
                }
                
                let handlerOtherUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(otherUser)
                }
                
                cell.cellMessage.text = newsfeedObject.textString
                cell.cellMessage.setLinkForSubstring(user, withLinkHandler: handlerUser)
                cell.cellMessage.setLinkForSubstring(otherUser, withLinkHandler: handlerOtherUser)

                
                break;
            // If someone I follow has a new follower
            case "newfollower":
                
                let followedUser = newsfeedObject.user
                let otherUsers = newsfeedObject.other
                let otherUser = otherUsers[0] as! String
                
                let handlerFolloweddUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(followedUser)
                }

                
                let handlerOtherUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(otherUser)
                }
                
    
                cell.cellMessage.text = newsfeedObject.textString
                cell.cellMessage.setLinkForSubstring(followedUser, withLinkHandler: handlerFolloweddUser)
                cell.cellMessage.setLinkForSubstring(otherUser, withLinkHandler: handlerOtherUser)

                break;
            
            // If a friend adds in a new profile
            case "newprofile":
                
                let followedUser = newsfeedObject.user
//                let profileData = newsfeedObject.other
//                let socialMediaType = profileData[0] as! String // Social platform name (i.e. facebook)
//                let socialMediaName = profileData[0] as! String // User's username on the platform

                let handlerOtherUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(followedUser)
                }
                
                cell.cellMessage.text = newsfeedObject.textString
                cell.cellMessage.setLinkForSubstring(followedUser, withLinkHandler: handlerOtherUser)
                

                // show the new account that was added
                cell.sponsoredProfileImageType = newsfeedObject.socialMediaType
                cell.sponsoredProfileImageName = newsfeedObject.socialMediaName
                
                cell.sponsoredProfileImageButton.hidden = false
                cell.cellTimeConnected.hidden = true
                
                print ("Image dict is: ", socialMediaImageDictionary)
                
                cell.sponsoredProfileImageButton.setBackgroundImage(socialMediaImageDictionary[newsfeedObject.socialMediaType], forState: .Normal)
                break;
            
            default:
                break;
            
        }
        
        cell.collectionView.collectionViewLayout.invalidateLayout()
        cell.collectionView.reloadData()
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Updates the index of the currently expanded row
        updateCurrentlyExpandedRow(&expansionObj, currentRow: indexPath.row)
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()

    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // Return height computed by our special function
        return getTableRowHeightForDropdownCell(&expansionObj, currentRow: indexPath.row)
        
        
    }
    
    // COLLECTION VIEW
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Use the tag to know which tableView row we're at
        let profiles = aquaintNewsfeed[collectionView.tag].displayProfiles
        let keyValSocialMediaPairs = convertDictionaryToSocialMediaKeyValPairList(profiles as! NSMutableDictionary)
        
       
        return keyValSocialMediaPairs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        print("CVTAG IS:", collectionView.tag)
        
        
        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        var keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(aquaintNewsfeed[collectionView.tag].displayProfiles as! NSMutableDictionary)
        
        
        if (!keyValSocialMediaPairList.isEmpty)
        {
            let socialMediaPair = keyValSocialMediaPairList[indexPath.item]
            let socialMediaType = socialMediaPair.socialMediaType
            let socialMediaUserName = socialMediaPair.socialMediaUserName
            
//            // Generate a UI image for the respective social media type
//            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
//            
//            cell.socialMediaName = socialMediaUserName // username
//            cell.socialMediaType = socialMediaType // facebook, snapchat, etc
//            
            // We will delay the image assignment to prevent buggy race conditions
            // (Check to see what happens when the delay is not set... then you'll understand)
            // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
            delay(0) { () -> () in
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Generate a UI image for the respective social media type
                    cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
                    
                    cell.socialMediaType = socialMediaType //i.e. facebook, twitter, ..
                    cell.socialMediaName = socialMediaUserName //i.e. austinvaday, avtheman, ..
                })
                
            }
        }
        

        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        // Make cell movements cleaner (increased FPM)
        //        cell.layer.shouldRasterize = true
        
        return cell
    }
    
    
    //    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    //        print("SELECTED ITEM AT ", indexPath.item)
    //
    //    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        print("SELECTED ITEM AT ", indexPath.item)
        
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
//        let socialMediaName = cell.socialMediaName
//        
//        var urlString:String!
//        var altString:String!
//        var socialMediaURL:NSURL!
//        
//        //        let userName = "AustinVaday"
//        let connectionSocialMediaUserNames = connectionList[collectionView.tag].socialMediaUserNames
//        
//        
//        urlString = ""
//        altString = ""
//        
//        switch (socialMediaName)
//        {
//        case "facebook":
//            
//            let facebookUserName = connectionSocialMediaUserNames["facebook"] as! String
//            urlString = "fb://requests/" + facebookUserName
//            altString = "http://www.facebook.com/" + facebookUserName
//            break;
//        case "snapchat":
//            
//            let snapchatUserName = connectionSocialMediaUserNames["snapchat"] as! String
//            urlString = "snapchat://add/" + snapchatUserName
//            altString = ""
//            break;
//        case "instagram":
//            
//            let instagramUserName = connectionSocialMediaUserNames["instagram"] as! String
//            urlString = "instagram://user?username=" + instagramUserName
//            altString = "http://www.instagram.com/" + instagramUserName
//            break;
//        case "twitter":
//            
//            let twitterUserName = connectionSocialMediaUserNames["twitter"] as! String
//            urlString = "twitter:///user?screen_name=" + twitterUserName
//            altString = "http://www.twitter.com/" + twitterUserName
//            break;
//        case "linkedin":
//            
//            let linkedinUserName = connectionSocialMediaUserNames["linkedin"] as! String
//            urlString = "linkedin://profile/" + linkedinUserName
//            altString = "http://www.linkedin.com/in/" + linkedinUserName
//            
//            break;
//        case "youtube":
//            
//            let youtubeUserName = connectionSocialMediaUserNames["youtube"] as! String
//            urlString = "youtube:www.youtube.com/user/" + youtubeUserName
//            altString = "http://www.youtube.com/" + youtubeUserName
//            break;
//        case "phone":
//            print ("COMING SOON")
//            
//            //                contact.familyName = "Vaday"
//            //                contact.givenName  = "Austin"
//            //
//            //                let phoneNum  = CNPhoneNumber(stringValue: "9493758223")
//            //                let cellPhone = CNLabeledValue(label: CNLabelPhoneNumberiPhone, value: phoneNum)
//            //
//            //                contact.phoneNumbers.append(cellPhone)
//            //
//            //                //TODO: Check if contact already exists in phone
//            //                let saveRequest = CNSaveRequest()
//            //                saveRequest.addContact(contact, toContainerWithIdentifier: nil)
//            //
//            
//            //                return
//            
//            break;
//        default:
//            break;
//        }
//        
//        socialMediaURL = NSURL(string: urlString)
//        
//        // If user doesn't have social media app installed, open using default browser instead (use altString)
//        if (!UIApplication.sharedApplication().canOpenURL(socialMediaURL))
//        {
//            if (altString != "")
//            {
//                socialMediaURL = NSURL(string: altString)
//            }
//            else
//            {
//                if (socialMediaName == "snapchat")
//                {
//                    showAlert("Sorry", message: "You need to have the Snapchat app! Please download it and try again!", buttonTitle: "Ok", sender: self)
//                }
//                else
//                {
//                    showAlert("Hold on!", message: "Feature coming soon...", buttonTitle: "Ok", sender: self)
//                }
//                return
//            }
//        }
//        
//        // Perform the request, go to external application and let the user do whatever they want!
//        UIApplication.sharedApplication().openURL(socialMediaURL)
        
    }
    
    private func generateData()
    {
        // Reset aquaint newsfeed object (so no duplicate entries on refresh)
        aquaintNewsfeed = Array<NewsfeedEntry>()
        
        spinner.hidden = false
        spinner.startAnimating()
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(NewsfeedResultObjectModel.self, hashKey: currentUserName, rangeKey: 0).continueWithSuccessBlock { (result) -> AnyObject? in
            
            var newsfeedResultObjectMapper : NewsfeedResultObjectModel!
            
            // If successfull find, use that data
            if (result.error == nil && result.exception == nil && result.result != nil)
            {
                newsfeedResultObjectMapper = result.result as! NewsfeedResultObjectModel
                
                self.newsfeedList = convertJSONStringToArray(newsfeedResultObjectMapper.data) as NSArray
                
                    
                    print("NEWSFEED LIST IS: ", self.newsfeedList)
                    
                    var runningRequests = 0
                    // Get all data from dynamo, store all into local newsfeed data structure
                    for entry in self.newsfeedList
                    {
                        runningRequests = runningRequests + 1

                        let newsfeedEntry = NewsfeedEntry()
                        self.aquaintNewsfeed.append(newsfeedEntry)
                        let index = self.aquaintNewsfeed.count - 1
                        
                        var getImageAndProfilesForUser : String!
                        
                        self.aquaintNewsfeed[index].event = entry.valueForKey("event")! as! String
                        self.aquaintNewsfeed[index].timestamp = entry.valueForKey("time")! as! Int
                        
                        switch self.aquaintNewsfeed[index].event
                        {
                        // If someone I follow starts following another person
                        case "newfollowing":
                            
                            self.aquaintNewsfeed[index].user = entry.valueForKey("user")! as! String
                            self.aquaintNewsfeed[index].other = NSArray(array: entry.valueForKey("other") as! NSArray)
                            let otherUser = self.aquaintNewsfeed[index].other[0] as! String
                            
                            self.aquaintNewsfeed[index].textString = self.aquaintNewsfeed[index].user +  " started following " + otherUser + ".  "
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = self.aquaintNewsfeed[index].user
                            print("getImageUser 1 is: ", getImageAndProfilesForUser)
                            
                            break;
                        // If someone I follow has a new follower
                        case "newfollower":
                            
                            self.aquaintNewsfeed[index].user = entry.valueForKey("user")! as! String
                            self.aquaintNewsfeed[index].other = NSArray(array: entry.valueForKey("other") as! NSArray)
                            let otherUser = self.aquaintNewsfeed[index].other[0] as! String
                            
                            // Note: Extra characters needed at end to fix weird bug where hyperlink would extend as a 'ghost link' near the end
                            self.aquaintNewsfeed[index].textString = "Your friend " + self.aquaintNewsfeed[index].user  +  " was followed by " + otherUser + ".  "
              
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = self.aquaintNewsfeed[index].user
                            print("getImageUser 2 is: ", getImageAndProfilesForUser)
                            break;
                            
                        // If a friend adds in a new profile
                        case "newprofile":
                            
                            self.aquaintNewsfeed[index].user = entry.valueForKey("user")! as! String
                            let profileData = NSArray(array: entry.valueForKey("other") as! NSArray)
                            
                            self.aquaintNewsfeed[index].socialMediaType = profileData[0] as! String // Social platform name (i.e. facebook)
                            self.aquaintNewsfeed[index].socialMediaName = profileData[1] as! String // User's username on the platform
                            
                            
                            self.aquaintNewsfeed[index].textString = self.aquaintNewsfeed[index].user +  " added a " + self.aquaintNewsfeed[index].socialMediaType + " account, check it out!"
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = self.aquaintNewsfeed[index].user
                            print("getImageUser 3 is: ", getImageAndProfilesForUser)

                            break;
                            
                        default:
                            break;
                            
                        }
                        
                        print("getImageUser 4 is: ", getImageAndProfilesForUser)

                        
                        getUserDynamoData(getImageAndProfilesForUser, completion: { (result, error) in
                            if result != nil && error == nil
                            {
                                let user = result! as User
                                self.aquaintNewsfeed[index].displayProfiles = user.accounts
                                
                                
                                // Now, get S3 image and profiles for necessary user
                                print("getImageUser 5 is: ", getImageAndProfilesForUser)
                                getUserS3Image(getImageAndProfilesForUser, completion: { (result, error) in
                                    if result != nil && error == nil
                                    {
                                        print("Success got image!")
                                        self.aquaintNewsfeed[index].displayImage = result! as UIImage
                                    }
                                    
                                    runningRequests = runningRequests - 1
                                    
                                    if runningRequests == 0
                                    {
                                        // Update UI when no more running requests! (last async call finished)
                                        // Update UI on main thread
                                        dispatch_async(dispatch_get_main_queue(), {
                                            self.spinner.stopAnimating()
                                            self.spinner.hidden = true
                                            self.newsfeedTableView.reloadData()
                                            self.newsfeedTableView.layoutIfNeeded()
                                            
                                        })
                                        
                                    }

                                })
                                
                              
                            }
                            
                        })
                        
                        


                    
                    }
                
                
            }
            else // Else, use new mapper class
            {
                print("FAIL!!: ", result.error)
            }
            
            
            return nil
        }
        

    }
    
    private func setUpAnimations(viewController: UIViewController)
    {
        // Only add more animations if none exist already. Prevents user abuse
        if !animatedObjects.isEmpty
        {
            return
        }
        
        for i in 0...10
        {
            
            // Set up object to animate
            let object = UIView()
            
            // Generate random size offset from 0.0 to 20.0
            let randomSizeOffset = CGFloat(arc4random_uniform(20))
            
            if i == 7
            {
                let aquaintEmblemImage = UIImage(named: "Emblem")
                let aquaintEmblemView  = UIImageView(image: aquaintEmblemImage!)
                aquaintEmblemView.frame = CGRect(x:0, y:0, width:100, height:100)
                object.addSubview(aquaintEmblemView)
            }
            else
            {
                object.frame = CGRect(x:55, y:300, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
                object.backgroundColor = generateRandomColor()
                object.layer.cornerRadius = object.frame.size.width / 2
            
            }

            // Generate random number from 0.0 and 200.0
            let randomYOffset = CGFloat( arc4random_uniform(200))
            
            // Add object to subview
            self.view.addSubview(object)
            
            // Create a cool path that defines animation curve
            let path = UIBezierPath()
            path.moveToPoint(CGPoint(x:-20, y:239 + randomYOffset))
            path.addCurveToPoint(CGPoint(x:viewController.view.frame.width + 50 , y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
            
            // Set up animation with path
            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.path = path.CGPath
            
            // Set up rotational animations
            animation.rotationMode = kCAAnimationRotateAuto
            animation.repeatCount = Float.infinity
            animation.duration = 5.0
            // Each object will take between 4.0 and 8.0 seconds
            // to complete one animation loop
            animation.duration = Double(arc4random_uniform(40)+30) / 10
            
            // stagger each animation by a random value
            // `290` was chosen simply by experimentation
            animation.timeOffset = Double(arc4random_uniform(290))
            
            object.layer.addAnimation(animation, forKey: "animate position along path")
            animatedObjects.append(object)
        }
    }
    
    private func addSingleEmblemAnimation(viewWidth: CGFloat)
    {
        
        // Set up object to animate
        let object = UIView()
        
        let aquaintEmblemImage = UIImage(named: "Emblem")
        let aquaintEmblemView  = UIImageView(image: aquaintEmblemImage!)
        // Set location off of screen so that user doesn't see object when animation completes
        aquaintEmblemView.frame = CGRect(x:-50, y:-25, width:20, height:20)
        object.addSubview(aquaintEmblemView)
    
        // Generate random number from 0.0 and 200.0
        let randomYOffset = CGFloat( arc4random_uniform(200))
        
        // Add object to subview
        self.view.addSubview(object)
        
        // Create a cool path that defines animation curve
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x:-20, y:239 + randomYOffset))
        path.addCurveToPoint(CGPoint(x:viewWidth + 50 , y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
        
        // Set up animation with path
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.CGPath
        
        // Set up rotational animations
        animation.rotationMode = kCAAnimationRotateAuto
        animation.repeatCount = 1
        // Each object will take between 4.0 and 8.0 seconds
        // to complete one animation loop
        animation.duration = Double(arc4random_uniform(40)+30) / 10
        
        // stagger each animation by a random value
        // `290` was chosen simply by experimentation
        animation.timeOffset = Double(arc4random_uniform(290))
        
        object.layer.addAnimation(animation, forKey: "animate position along path")

        delay(4)
        {
            object.layer.removeAllAnimations()
            object.removeFromSuperview()
        }
    }
    
    private func clearUpAnimations()
    {
        // Only remove animations if there are some that exist already. O(1) if empty
        if animatedObjects.isEmpty
        {
            return
        }
        
        for object in animatedObjects
        {
            object.layer.removeAllAnimations()
            object.removeFromSuperview()
        }
        
        animatedObjects.removeAll()
    }
    
    private func makeViewShine(view:UIView)
    {
        // UI Color for #12BBD5 (www.uicolor.xyz)
        let aquaLightColor = UIColor(red:0.07, green:0.73, blue:0.84, alpha:1.0)
        view.layer.shadowColor = aquaLightColor.CGColor
        view.layer.shadowRadius = 1.0
        view.layer.shadowOpacity = 1.0
        view.layer.shadowOffset = CGSizeZero
        
        
        UIView.animateWithDuration(1.5, delay: 0, options: [UIViewAnimationOptions.Autoreverse, UIViewAnimationOptions.CurveEaseInOut, UIViewAnimationOptions.Repeat, UIViewAnimationOptions.AllowUserInteraction], animations: {
                UIView.setAnimationRepeatCount(Float.infinity)
                view.transform = CGAffineTransformMakeScale(1.2, 1.2)
            
            }) { (finished) in
                view.layer.shadowRadius = 0.0
                view.transform = CGAffineTransformMakeScale(1.0, 1.0)
                
        }
    }
    
}
