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
    
    override func viewDidAppear(_ animated: Bool) {
        if shouldShowAnimations && newsfeedList.count == 0
        {            
            // attempt to regenerate data again
            generateData(0)
        }
      
      awsMobileAnalyticsRecordPageVisitEventTrigger("NewsfeedViewController", forKey: "page_name")
    }
    
    // Remove animations after user leaves page. Prevents post-animation stale objects
    override func viewDidDisappear(_ animated: Bool) {
        clearUpAnimations()
        noContentMessageView.isHidden = true
        newsfeedTableView.isHidden = false
    }
  
  
  
    @IBAction func onUserClickedAquaintButton(_ sender: UIButton) {
        
        
        print("Button intended was clicked")
    }
    
    @IBAction func onUserClickedSubArea(_ sender: AnyObject) {
        // Animate one of our embles out
        addSingleEmblemAnimation(self.view.frame.width)
    }

  @IBAction func onFindFacebookFriendsButtonClicked(_ sender: AnyObject) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let findFBFriendsVC = storyboard.instantiateViewController(withIdentifier: "AddSocialContactsViewController") as! AddSocialContactsViewController
    findFBFriendsVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    self.present(findFBFriendsVC, animated: true, completion: nil)
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
        refreshControl.addTarget(self, action: #selector(NewsfeedViewController.refreshTable(_:)), for: UIControlEvents.valueChanged)
        newsfeedTableView.addSubview(refreshControl)
        
        // Generates data needed -- fetches newsfeed from AWS
        generateData(0)
        
    }
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(_ sender:AnyObject)
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
    
    func didClickSponsoredProfileButton(_ sponsoredProfileImageName: String, sponsoredProfileImageType: String) {
        let socialMediaURL = getUserSocialMediaURL(sponsoredProfileImageName, socialMediaTypeName: sponsoredProfileImageType, sender: self)

        // Perform the request, go to external application and let the user do whatever they want!
        if socialMediaURL != nil
        {
            UIApplication.shared.openURL(socialMediaURL)
        }
    }
    
    
    // TABLE VIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        // Extra check to wait for trigger until showing animations
        if shouldShowAnimations
        {
            if aquaintNewsfeed.count == 0
            {
                noContentMessageView.isHidden = false
                newsfeedTableView.isHidden = true
                setUpAnimations(self)
            }
            else
            {
                noContentMessageView.isHidden = true
                newsfeedTableView.isHidden = false
                clearUpAnimations()
            }
        }
    
        return aquaintNewsfeed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! NewsfeedTableViewCell
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
        cell.sponsoredProfileImageButton.isHidden = true
        cell.cellTimeConnected.isHidden = false
        
        // Clear FRHyperLabel for re-use (prevents case where user clicked may be used from a previously recycled cell)
        cell.cellMessage.clearActionDictionary()
        
        switch newsfeedObject.event
        {
            // If someone I follow starts following another person
            case "newfollowing":
                
                let user = newsfeedObject.user
                let otherUsers = newsfeedObject.other
                let otherUser = otherUsers?[0] as! String
                
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
                let otherUser = otherUsers?[0] as! String
                
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
                cell.sponsoredProfileImageButton.isHidden = false
                cell.cellTimeConnected.isHidden = true
                                
                cell.sponsoredProfileImageButton.setBackgroundImage(socialMediaImageDictionary[newsfeedObject.socialMediaType], for: UIControlState())
                break;
            
            default:
                break;
            
        }
        
//        cell.cellMessage.
        
        
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return 60
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
  
    
    fileprivate func generateData(_ pageNum: Int)
    {
        // If we don't store our data into a temporary object -- we'll be modifying the table data source while it may still
        // be used in the tableView methods! This prevents a crash.
        var newAquaintsNewsfeed = Array<NewsfeedEntry>()
        
        // Only show the middle spinner if user did not refresh table (or else there would be two spinners!)
        if !userDidRefreshTable && !isNewDataLoading
        {
            spinner.isHidden = false
            spinner.startAnimating()
        }
        else
        {
            userDidRefreshTable = false
        }

        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(NewsfeedResultObjectModel.self, hashKey: currentUserName, rangeKey: pageNum).continue { (result) -> AnyObject? in
            
            var newsfeedResultObjectMapper : NewsfeedResultObjectModel!
            
            // If successfull find, use that data
            if (result.error == nil && result.exception == nil && result.result != nil)
            {
                newsfeedResultObjectMapper = result.result as! NewsfeedResultObjectModel
                
                if self.isNewDataLoading
                {
                    DispatchQueue.main.async(execute: {
                        self.addTableViewFooterSpinner()
                    })
                }
                
                let getResults = convertJSONStringToArray(newsfeedResultObjectMapper.data) as NSArray
                

                
//                    print("NEWSFEED LIST IS: ", newAquaintsNewsfeed)
                    if getResults.count == 0
                    {
                        DispatchQueue.main.async(execute: {
                            self.spinner.isHidden = true
                            self.spinner.stopAnimating()
                            
                            // If pageNum is anything other than zero, we do not want to
                            // show the "no content" animations. We just have no more data
                            // to add to our existing data.
                            if pageNum == 0
                            {
                                self.shouldShowAnimations = true
                                self.noContentMessageView.isHidden = false
                                
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
                        
                        newAquaintsNewsfeed[index].event = entry.value(forKey: "event")! as! String
                        newAquaintsNewsfeed[index].timestamp = entry.value(forKey: "time")! as! Int
                        
                        switch newAquaintsNewsfeed[index].event
                        {
                        // If someone I follow starts following another person
                        case "newfollowing":
                            
                            newAquaintsNewsfeed[index].user = entry.value(forKey: "user")! as! String
                            newAquaintsNewsfeed[index].other = NSArray(array: entry.value(forKey: "other") as! NSArray)
                            let otherUser = newAquaintsNewsfeed[index].other[0] as! String
                            
                            newAquaintsNewsfeed[index].textString = newAquaintsNewsfeed[index].user +  " started following " + otherUser + ".  "
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = newAquaintsNewsfeed[index].user
                            print("getImageUser 1 is: ", getImageAndProfilesForUser)
                            
                            break;
                        // If someone I follow has a new follower
                        case "newfollower":
                            
                            newAquaintsNewsfeed[index].user = entry.value(forKey: "user")! as! String
                            newAquaintsNewsfeed[index].other = NSArray(array: entry.value(forKey: "other") as! NSArray)
                            let otherUser = newAquaintsNewsfeed[index].other[0] as! String
                            
                            // Note: Extra characters needed at end to fix weird bug where hyperlink would extend as a 'ghost link' near the end
                            newAquaintsNewsfeed[index].textString = "Your friend " + newAquaintsNewsfeed[index].user  +  " was followed by " + otherUser + ".  "
              
                            
                            // Denotes which user to fetch data for in the dropdown!
                            getImageAndProfilesForUser = newAquaintsNewsfeed[index].user
                            print("getImageUser 2 is: ", getImageAndProfilesForUser)
                            break;
                            
                        // If a friend adds in a new profile
                        case "newprofile":
                            
                            newAquaintsNewsfeed[index].user = entry.value(forKey: "user")! as! String
                            let profileData = NSArray(array: entry.value(forKey: "other") as! NSArray)
                            
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
                              DispatchQueue.main.async(execute: {
                                
                                
                                if pageNum == 0
                                {
                                  self.aquaintNewsfeed = newAquaintsNewsfeed
                                }
                                else // if pageNum is anything other than 0 (1, 2, etc).. append to current newsfeed
                                {
                                  
                                  runningRequests = runningRequests - 1
                                  
                                  if runningRequests == 0 {
                                    self.aquaintNewsfeed.append(contentsOf: newAquaintsNewsfeed)
                                    self.removeTableViewFooterSpinner()
                                    // Note: possible race condition below
                                    self.isNewDataLoading = false
                            
                                  }
                                }
                                
                                self.shouldShowAnimations = false
                                self.spinner.stopAnimating()
                                self.spinner.isHidden = true
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
                                        DispatchQueue.main.async(execute: {
                                          
                                          
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
                DispatchQueue.main.async(execute: {
                    
                    self.spinner.isHidden = true
                    self.spinner.stopAnimating()
                    
                    // If pageNum is anything other than zero, we do not want to
                    // show the "no content" animations. We just have no more data 
                    // to add to our existing data.
                    if pageNum == 0
                    {
                        self.shouldShowAnimations = true
                        self.noContentMessageView.isHidden = false
    
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
    
    fileprivate func setUpAnimations(_ viewController: UIViewController)
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
                aquaintEmblemView.frame = CGRect(x:-105, y:-105, width:100, height:100)
                object.addSubview(aquaintEmblemView)
            }
            else
            {
                object.frame = CGRect(x:55, y:-300, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
                object.backgroundColor = generateRandomColor()
                object.layer.cornerRadius = object.frame.size.width / 2
            
            }

            // Generate random number from 0.0 and 200.0
            let randomYOffset = CGFloat( arc4random_uniform(200))
            
            // Add object to subview
            self.view.addSubview(object)
            
            // Create a cool path that defines animation curve
            let path = UIBezierPath()
            path.move(to: CGPoint(x:-20, y:239 + randomYOffset))
            path.addCurve(to: CGPoint(x:viewController.view.frame.width + 50 , y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
            
            // Set up animation with path
            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.path = path.cgPath
            
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
            
            object.layer.add(animation, forKey: "animate position along path")
            animatedObjects.append(object)
        }
    }
    
    fileprivate func addSingleEmblemAnimation(_ viewWidth: CGFloat)
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
        path.move(to: CGPoint(x:-20, y:239 + randomYOffset))
        path.addCurve(to: CGPoint(x:viewWidth + 50 , y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
        
        // Set up animation with path
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        
        // Set up rotational animations
        animation.rotationMode = kCAAnimationRotateAuto
        animation.repeatCount = 1
        // Each object will take between 4.0 and 8.0 seconds
        // to complete one animation loop
        animation.duration = Double(arc4random_uniform(40)+30) / 10
        
        // stagger each animation by a random value
        // `290` was chosen simply by experimentation
        animation.timeOffset = Double(arc4random_uniform(290))
        
        object.layer.add(animation, forKey: "animate position along path")

        delay(4)
        {
            object.layer.removeAllAnimations()
            object.removeFromSuperview()
        }
    }
    
    fileprivate func clearUpAnimations()
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
    
    fileprivate func makeViewShine(_ view:UIView)
    {
        // UI Color for #12BBD5 (www.uicolor.xyz)
        let aquaLightColor = UIColor(red:0.07, green:0.73, blue:0.84, alpha:1.0)
        view.layer.shadowColor = aquaLightColor.cgColor
        view.layer.shadowRadius = 1.0
        view.layer.shadowOpacity = 1.0
        view.layer.shadowOffset = CGSize.zero
        
        
        UIView.animate(withDuration: 1.5, delay: 0, options: [UIViewAnimationOptions.autoreverse, UIViewAnimationOptions.repeat, UIViewAnimationOptions.allowUserInteraction], animations: {
                UIView.setAnimationRepeatCount(Float.infinity)
                view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            
            }) { (finished) in
                view.layer.shadowRadius = 0.0
                view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                
        }
    }
    
    fileprivate func addTableViewFooterSpinner() {
        let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        footerSpinner.startAnimating()
        footerSpinner.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        newsfeedTableView.tableFooterView = footerSpinner
    }
    
    fileprivate func removeTableViewFooterSpinner() {
        newsfeedTableView.tableFooterView = nil
    }
    
}
