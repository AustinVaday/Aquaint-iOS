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
import AWSMobileAnalytics

class NewsfeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SponsoredProfileButtonDelegate {

    let cellIdentifier = "newsfeedCell"
    @IBOutlet weak var newsfeedTableView: UITableView!
    @IBOutlet weak var noContentMessageView: UIView!
    @IBOutlet weak var emblemButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var aquaintNewsfeed : Array<NewsfeedEntry>!
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var refreshControl : CustomRefreshControl!
    var defaultImage : UIImage!
    var newsfeedList : NSArray! // Array of dictionary to hold all newsfeed data
    var animatedObjects : Array<UIView>!
    var shouldShowAnimations = false
    var userDidRefreshTable = false
    var isNewDataLoading = false
    var newsfeedPageNum = 0
    var didExceedMaxDataDepth = false // Tells us when to stop requesting more data
    
    override func viewDidAppear(animated: Bool) {
        if shouldShowAnimations && newsfeedList.count == 0
        {            
            // attempt to regenerate data again
            generateData(0)
        }
      
      awsMobileAnalyticsRecordPageVisitEventTrigger("NewsfeedViewController", forKey: "page_name")
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

  @IBAction func onFindFacebookFriendsButtonClicked(sender: AnyObject) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let findFBFriendsVC = storyboard.instantiateViewControllerWithIdentifier("AddSocialContactsViewController") as! AddSocialContactsViewController
    self.presentViewController(findFBFriendsVC, animated: true, completion: nil)
  }
  
    override func viewDidLoad() {
        makeViewShine(emblemButton.imageView!)

        print ("VIEW LOADED")
        print ("Screen width is: ", self.view.frame.width)
        newsfeedList = NSArray()
        aquaintNewsfeed = Array<NewsfeedEntry>()
        animatedObjects = Array<UIView>()
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()
        
        // Fetch the user's username
        currentUserName = getCurrentCachedUser()
      
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = CustomRefreshControl()
      
        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(NewsfeedViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        newsfeedTableView.addSubview(refreshControl)
        
        // Generates data needed -- fetches newsfeed from AWS
        generateData(0)
        
    }
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
        userDidRefreshTable = true
        self.refreshControl.beginRefreshing()

        generateData(0)
        newsfeedPageNum = 0
        
        // Need to end refreshing
        delay(1.5)
        {
            self.refreshControl.endRefreshing()
        }
    }
    
    func didClickSponsoredProfileButton(sponsoredProfileImageName: String, sponsoredProfileImageType: String) {
        let socialMediaURL = getUserSocialMediaURL(sponsoredProfileImageName, socialMediaTypeName: sponsoredProfileImageType, sender: self)

        // Perform the request, go to external application and let the user do whatever they want!
        if socialMediaURL != nil
        {
            UIApplication.sharedApplication().openURL(socialMediaURL)
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
        cell.sponsoredDelegate = self
        
        if aquaintNewsfeed == nil || aquaintNewsfeed.count == 0
        {
            return cell
        }
        
        let newsfeedObject = aquaintNewsfeed[indexPath.row]
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        cell.sponsoredProfileImageButton.layer.cornerRadius = cell.sponsoredProfileImageButton.frame.size.width / 2
        
        // Set user image and profiles
        if newsfeedObject.displayImage != nil
        {
            cell.cellImage.image = newsfeedObject.displayImage
        }
        else // else: use default image
        {
            cell.cellImage.image = defaultImage
        }
        
        // Set time dif of event on the cell
        cell.cellTimeConnected.text = computeTimeDiffFromNow(newsfeedObject.timestamp)
        
        // Default hidden states
        cell.sponsoredProfileImageButton.hidden = true
        cell.cellTimeConnected.hidden = false
        
        // Clear FRHyperLabel for re-use (prevents case where user clicked may be used from a previously recycled cell)
        cell.cellMessage.clearActionDictionary()
        
        switch newsfeedObject.event
        {
            // If someone I follow starts following another person
            case "newfollowing":
                
                let user = newsfeedObject.user
                let otherUsers = newsfeedObject.other
                let otherUser = otherUsers[0] as! String
                
                let handlerUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(user, me: self.currentUserName)
                }
                
                let handlerOtherUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(otherUser, me: self.currentUserName)
                }
                
                cell.cellMessage.text = newsfeedObject.textString
                cell.cellMessage.reloadInputViews()
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
                    showPopupForUser(followedUser, me: self.currentUserName)
                }

                
                let handlerOtherUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(otherUser, me: self.currentUserName)
                }
                
    
                cell.cellMessage.text = newsfeedObject.textString
                cell.cellMessage.reloadInputViews()

                cell.cellMessage.setLinkForSubstring(followedUser, withLinkHandler: handlerFolloweddUser)
                cell.cellMessage.setLinkForSubstring(otherUser, withLinkHandler: handlerOtherUser)

                break;
            
            // If a friend adds in a new profile
            case "newprofile":
                
                let followedUser = newsfeedObject.user

                let handlerOtherUser = {
                    (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
                    showPopupForUser(followedUser, me: self.currentUserName)
                }
                
                cell.cellMessage.text = newsfeedObject.textString
                cell.cellMessage.reloadInputViews()

                cell.cellMessage.setLinkForSubstring(followedUser, withLinkHandler: handlerOtherUser)
                

                // show the new account that was added
                cell.sponsoredProfileImageType = newsfeedObject.socialMediaType
                cell.sponsoredProfileImageName = newsfeedObject.socialMediaName
                cell.sponsoredProfileImageButton.hidden = false
                cell.cellTimeConnected.hidden = true
                                
                cell.sponsoredProfileImageButton.setBackgroundImage(socialMediaImageDictionary[newsfeedObject.socialMediaType], forState: .Normal)
                break;
            
            default:
                break;
            
        }
        
//        cell.cellMessage.
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        /*
        if !tableView.dragging && !tableView.tracking
        {
            // Updates the index of the currently expanded row
            updateCurrentlyExpandedRow(&expansionObj, currentRow: indexPath.row)
            
            // Update UI with animation
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        */
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
       return 60
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == newsfeedTableView
        {
            let location = scrollView.contentOffset.y + scrollView.frame.size.height
            
            if location >= scrollView.contentSize.height
            {
                // Load data only if more data is not loading. 
                if !isNewDataLoading
                {
                    isNewDataLoading = true
                    print("DATA IS LOADING")
                    
                    //Note: newsfeedPageNum will keep being incremented
                    newsfeedPageNum = newsfeedPageNum + 1
                    
                    // Only attempt to load more data if we did not exceed max data depth
                    if !didExceedMaxDataDepth
                    {
                        generateData(newsfeedPageNum)
                    }
                }
            }
            
        }
    }
    
//    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        if scrollView == newsfeedTableView
//        {
//            let location = scrollView.contentOffset.y + scrollView.frame.size.height
//            
//            if location >= scrollView.contentSize.height
//            {
//                // Load data only if more data is loading
//                if !isNewDataLoading
//                {
//                    isNewDataLoading = true
//                    print("DATA IS LOADING")
//                    newsfeedPageNum = newsfeedPageNum + 1
//                    generateData(newsfeedPageNum)
//                    
//                }
//            }
//            
//        }
//    }
    
  
    
    private func generateData(pageNum: Int)
    {
        // If we don't store our data into a temporary object -- we'll be modifying the table data source while it may still
        // be used in the tableView methods! This prevents a crash.
        var newAquaintsNewsfeed = Array<NewsfeedEntry>()
        
        // Only show the middle spinner if user did not refresh table (or else there would be two spinners!)
        if !userDidRefreshTable && !isNewDataLoading
        {
            spinner.hidden = false
            spinner.startAnimating()
        }
        else
        {
            userDidRefreshTable = false
        }

        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dynamoDBObjectMapper.load(NewsfeedResultObjectModel.self, hashKey: currentUserName, rangeKey: pageNum).continueWithSuccessBlock { (result) -> AnyObject? in
            
            var newsfeedResultObjectMapper : NewsfeedResultObjectModel!
            
            // If successfull find, use that data
            if (result.error == nil && result.exception == nil && result.result != nil)
            {
                newsfeedResultObjectMapper = result.result as! NewsfeedResultObjectModel
                
                if self.isNewDataLoading
                {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.addTableViewFooterSpinner()
                    })
                }
                
                let getResults = convertJSONStringToArray(newsfeedResultObjectMapper.data) as NSArray
                

                
//                    print("NEWSFEED LIST IS: ", newAquaintsNewsfeed)
                    if getResults.count == 0
                    {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.spinner.hidden = true
                            self.spinner.stopAnimating()
                            
                            // If pageNum is anything other than zero, we do not want to
                            // show the "no content" animations. We just have no more data
                            // to add to our existing data.
                            if pageNum == 0
                            {
                                self.shouldShowAnimations = true
                                self.noContentMessageView.hidden = false
                                
                            }
                            else // if pageNum is anything other than 0 (1, 2, etc).. append to current newsfeed
                            {
                                self.removeTableViewFooterSpinner()
                                // Note: possible race condition below
                                self.isNewDataLoading = false
                            }
                            
                            self.newsfeedTableView.reloadData()
                            
                        })

                    }
                    
                    var runningRequests = 0
                    // Get all data from dynamo, store all into local newsfeed data structure
                    for entry in getResults
                    {
                        runningRequests = runningRequests + 1

                        let newsfeedEntry = NewsfeedEntry()
                        newAquaintsNewsfeed.append(newsfeedEntry)
                        let index = newAquaintsNewsfeed.count - 1
                        
                        var getImageAndProfilesForUser : String!
                        
                        newAquaintsNewsfeed[index].event = entry.valueForKey("event")! as! String
                        newAquaintsNewsfeed[index].timestamp = entry.valueForKey("time")! as! Int
                        
                        switch newAquaintsNewsfeed[index].event
                        {
                        // If someone I follow starts following another person
                        case "newfollowing":
                            
                            newAquaintsNewsfeed[index].user = entry.valueForKey("user")! as! String
                            newAquaintsNewsfeed[index].other = NSArray(array: entry.valueForKey("other") as! NSArray)
                            let otherUser = newAquaintsNewsfeed[index].other[0] as! String
                            
                            newAquaintsNewsfeed[index].textString = newAquaintsNewsfeed[index].user +  " started following " + otherUser + ".  "
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = newAquaintsNewsfeed[index].user
                            print("getImageUser 1 is: ", getImageAndProfilesForUser)
                            
                            break;
                        // If someone I follow has a new follower
                        case "newfollower":
                            
                            newAquaintsNewsfeed[index].user = entry.valueForKey("user")! as! String
                            newAquaintsNewsfeed[index].other = NSArray(array: entry.valueForKey("other") as! NSArray)
                            let otherUser = newAquaintsNewsfeed[index].other[0] as! String
                            
                            // Note: Extra characters needed at end to fix weird bug where hyperlink would extend as a 'ghost link' near the end
                            newAquaintsNewsfeed[index].textString = "Your friend " + newAquaintsNewsfeed[index].user  +  " was followed by " + otherUser + ".  "
              
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = newAquaintsNewsfeed[index].user
                            print("getImageUser 2 is: ", getImageAndProfilesForUser)
                            break;
                            
                        // If a friend adds in a new profile
                        case "newprofile":
                            
                            newAquaintsNewsfeed[index].user = entry.valueForKey("user")! as! String
                            let profileData = NSArray(array: entry.valueForKey("other") as! NSArray)
                            
                            newAquaintsNewsfeed[index].socialMediaType = profileData[0] as! String // Social platform name (i.e. facebook)
                            newAquaintsNewsfeed[index].socialMediaName = profileData[1] as! String // User's username on the platform
                            
                            
                            newAquaintsNewsfeed[index].textString = newAquaintsNewsfeed[index].user +  " added a new " + newAquaintsNewsfeed[index].socialMediaType + " account, check it out!"
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = newAquaintsNewsfeed[index].user
                            print("getImageUser 3 is: ", getImageAndProfilesForUser)

                            break;
                            
                        default:
                            break;
                            
                        }
                        
                        print("getImageUser 4 is: ", getImageAndProfilesForUser)

                        
                        getUserDynamoData(getImageAndProfilesForUser, completion: { (result, error) in
                            if result != nil && error == nil
                            {
                                let user = result! as! UserPrivacyObjectModel

                              // Update UI when no more running requests! (last async call finished)
                              // Update UI on main thread
                              dispatch_async(dispatch_get_main_queue(), {
                                
                                
                                if pageNum == 0
                                {
                                  self.aquaintNewsfeed = newAquaintsNewsfeed
                                }
                                else // if pageNum is anything other than 0 (1, 2, etc).. append to current newsfeed
                                {
                                  
                                  runningRequests = runningRequests - 1
                                  
                                  if runningRequests == 0 {
                                    self.aquaintNewsfeed.appendContentsOf(newAquaintsNewsfeed)
                                    self.removeTableViewFooterSpinner()
                                    // Note: possible race condition below
                                    self.isNewDataLoading = false
                            
                                  }
                                }
                                
                                self.shouldShowAnimations = false
                                self.spinner.stopAnimating()
                                self.spinner.hidden = true
                                self.newsfeedTableView.reloadData()
                                self.newsfeedTableView.layoutIfNeeded()
                                
                              })

                              
                                // Now, get S3 image and profiles for necessary user
                                print("getImageUser 5 is: ", getImageAndProfilesForUser)
                                getUserS3Image(getImageAndProfilesForUser, extraPath: nil, completion: { (result, error) in
                                    if result != nil && error == nil
                                    {
                                        print("Success got image!")
                                        newAquaintsNewsfeed[index].displayImage = result! as UIImage
                                        dispatch_async(dispatch_get_main_queue(), {
                                          
                                          
                                          self.newsfeedTableView.reloadData()
                                          self.newsfeedTableView.layoutIfNeeded()
                                          
                                        })
                                    }
                                    
//                                    runningRequests = runningRequests - 1
//                                  
//                                    if runningRequests == 0
//                                    {
                                        // Update UI when no more running requests! (last async call finished)
                                        // Update UI on main thread
                                  
                                        
//                                    }

                                })
                              
                              
                            }
                            
                        })
                        
                        


                    
                    }
                
                
            }
            else // Else, no newsfeed found
            {
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.spinner.hidden = true
                    self.spinner.stopAnimating()
                    
                    // If pageNum is anything other than zero, we do not want to
                    // show the "no content" animations. We just have no more data 
                    // to add to our existing data.
                    if pageNum == 0
                    {
                        self.shouldShowAnimations = true
                        self.noContentMessageView.hidden = false
    
                    }
                    else // if pageNum is anything other than 0 (1, 2, etc).. append to current newsfeed
                    {
                        self.removeTableViewFooterSpinner()
                        self.isNewDataLoading = false
                        
                        // set max data depth so we know whether or not to proceed farther for newsfeed requests
                        self.didExceedMaxDataDepth = true
                    }
                    
                    self.newsfeedTableView.reloadData()

                })
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
    
    private func addTableViewFooterSpinner() {
        let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        footerSpinner.startAnimating()
        footerSpinner.frame = CGRectMake(0, 0, self.view.frame.width, 44)
        newsfeedTableView.tableFooterView = footerSpinner
    }
    
    private func removeTableViewFooterSpinner() {
        newsfeedTableView.tableFooterView = nil
    }
    
}
