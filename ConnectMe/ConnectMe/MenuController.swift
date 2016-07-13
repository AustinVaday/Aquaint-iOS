//
//  MenuController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import AWSCognitoIdentityProvider
import AWSDynamoDB
import AWSS3

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    enum MenuData: Int {
        case YOUR_ACCOUNT
        case LINKED_ACCOUNTS
        case NOTIFICATIONS
        case INVITE_FRIENDS
        case HELP
        case TERMS
        case CLEAR_HISTORY
        case LOG_OUT
    }
    
    // The dictionary we receive from AWS DynamoDB maps a string to an array.
    // When we have a collection view, we need a way to propogate this 
    // datastructure linearly, because we're given indices based on
    // how many usernames we have. A solution to this is using  
    // an array of structs to keep tabs on what social media type we have
    // and what the respective username is.
    struct KeyValSocialMediaPair
    {
        var socialMediaType : String!       // i.e. "Facebook"
        var socialMediaUserName : String!   // i.e. "austinvaday"
    }
    
    @IBOutlet weak var linkedAccountsCollectionView: UICollectionView!
    @IBOutlet weak var realNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var numFollowersLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    var currentUserName : String!
//    var currentUserId: String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var keyValSocialMediaPairList : Array<KeyValSocialMediaPair>!
    var dynamoDBObjectMapper: AWSDynamoDBObjectMapper!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)

    // AWS credentials provider
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")

    override func viewDidLoad() {
        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Fetch the user's username and real name
        currentUserName = getCurrentCachedUser()
//        currentUserId = getCurrentUserID()
//      currentRealName = getCurrentRealUser()
        
        // Initialize array so that collection view has something to check while we 
        // fetch data from dynamo
        
        keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
        // Set up DB
        dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
//        print("CUR USER ID: ", currentUserId)
        print("CUR USERNAME: ", currentUserName)
        dynamoDBObjectMapper.load(User.self, hashKey: currentUserName, rangeKey: nil).continueWithBlock(
            { (resultTask) -> AnyObject? in
                
                if(resultTask.result == nil)
                {
                    print("DYNAMODB LOAD : USER", self.currentUserName ,"NOT FOUND, result is nil")
                }
                else if (resultTask.error == nil && resultTask.exception == nil) // If successful save

                {
                    print ("DYNAMODB LOAD SUCCESS:", resultTask.result)
                    
                    let user = resultTask.result as! User
                    
                    // Set user attributes on the view
                    self.realNameLabel.text = user.realname
                    
                    /***************************************
                    * If user image not cached, get from S3
                    ***************************************/
                    // if user image not cached, then..
                    // AWS TRANSFER REQUEST
                    
                    let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString("temp")
                    let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
                    let downloadRequest = AWSS3TransferManagerDownloadRequest()
                    downloadRequest.bucket = "aquaint-userfiles-mobilehub-146546989"
                    downloadRequest.key = "public/" + self.currentUserName
                    downloadRequest.downloadingFileURL = downloadingFileURL
                    
                    let transferManager = AWSS3TransferManager.defaultS3TransferManager()
                    
                    transferManager.download(downloadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (resultTask) -> AnyObject? in
                        
                        // if sucessful file transfer
                        if resultTask.error == nil && resultTask.exception == nil && resultTask.result != nil
                        {
                            print("SUCCESS FILE DOWNLOAD")
                            
                            self.profileImageView.image = UIImage(contentsOfFile: downloadingFileURL.absoluteString)
                            
                        }
                        else // If fail file transfer
                        {
                            
                            print("ERROR FILE DOWNLOAD: ", resultTask.error)
                        }
                        
                        return nil
                        
                    })
 
                    
                    
                    // If user has added accounts/profiles, show them
                    if(user.accounts != nil)
                    {
                        // Dictionary with key: string of social media types (i.e. "facebook"), 
                        // val: array of usernames for that social media (i.e. "austinvaday, austinv, sammyv")
                        self.socialMediaUserNames = user.accounts as! NSMutableDictionary
                        
                        // Convert dictionary to key,val pairs. Redundancy allowed
                        self.keyValSocialMediaPairList = self.convertDictionaryToSocialMediaKeyValPairList(self.socialMediaUserNames, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
                        
                        
                        // Perform update on UI on main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            // Propogate collection view with new data
                            self.linkedAccountsCollectionView.reloadData()
                            print("RELOADING COLLECTIONVIEW")
                        })
                    }
                    
                    
                }
                
                if (resultTask.error != nil)
                {
                    print ("DYNAMODB LOAD ERROR:", resultTask.error)
                }
                
                if (resultTask.exception != nil)
                {
                    print ("DYNAMODB LOAD EXCEPTION:", resultTask.exception)
                }
                
                return nil
        })
        
        // Set the UI
        realNameLabel.text = "Real name"
        userNameLabel.text = currentUserName
        numFollowersLabel.text = "120"
        
        // Set up dictionary for user's social media names
//       socialMediaUserNames = NSMutableDictionary()
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)

    }
    
    @IBAction func onAddSocialMediaClicked(sender: AnyObject) {
        
        print("YO MAN YOU CLICKED IT.")
    }
    
    /**************************************************************************
     *    COLLECTION VIEW PROTOCOL
     **************************************************************************/
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if (keyValSocialMediaPairList.isEmpty)
        {
            return 0
        }
    
        return keyValSocialMediaPairList.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        
        print ("SELECTED", cell.socialMediaName)
        
        let socialMediaUserName = cell.socialMediaName
        let socialMediaType = cell.socialMediaType
        
        let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)

        // Perform the request, go to external application and let the user do whatever they want!
        UIApplication.sharedApplication().openURL(socialMediaURL)
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("accountsCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        if (!keyValSocialMediaPairList.isEmpty)
        {
            let socialMediaPair = keyValSocialMediaPairList[indexPath.item % keyValSocialMediaPairList.count]
            let socialMediaType = socialMediaPair.socialMediaType
            let socialMediaUserName = socialMediaPair.socialMediaUserName

                
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
            
            cell.socialMediaName = socialMediaUserName // username
            cell.socialMediaType = socialMediaType // facebook, snapchat, etc
            
            // Make cell image circular
            cell.layer.cornerRadius = cell.frame.width / 2
        }
        
        return cell
    }
    
    
    
    /**************************************************************************
     *    TABLE VIEW PROTOCOL
     **************************************************************************/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
        
        let menuOption = MenuData(rawValue: indexPath.row)!
        
        switch (menuOption)
        {
        case .YOUR_ACCOUNT:
            cell.cellName.text = "Your Account"
            break;
        case .LINKED_ACCOUNTS:
            cell.cellName.text = "Linked Social Media Accounts"
            break;
        case .NOTIFICATIONS:
            cell.cellName.text = "Notification Settings"
            break;
        case .INVITE_FRIENDS:
            cell.cellName.text = "Invite Friends"
            break;
        case .HELP:
            cell.cellName.text = "Help & About Us"
            break;
        case .TERMS:
            cell.cellName.text = "Terms of Service"
            break;
        case .CLEAR_HISTORY:
            cell.cellName.text = "Clear Search History"
            break;
        case .LOG_OUT:
            cell.cellName.text = "Log Out"
            break;
    
//        default:
//            cell.cellName.text = "Error"
//            break;
        }
        

        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    
    }
    
    
    func logUserOut()
    {
        
        // Ask user if they really want to log out...
        let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            // present the log in home page
            
            //TODO: Add spinner functionality
            self.performSegueWithIdentifier("logOut", sender: nil)
            
            // Log out AWS
            
            
            
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
    }
    
    // Private helper functions
    //---------------------------------------------------------------------------------------------------
    private func convertDictionaryToSocialMediaKeyValPairList(dict: NSMutableDictionary,
                                                              possibleSocialMediaNameList: Array<String>)
                                                                -> Array<KeyValSocialMediaPair>!
    {
        
        var pairList = Array<KeyValSocialMediaPair>()
        
        // dict is a dictionary that maps a social media name (i.e. facebook) to every
        // single username that the user has for that social media type. We need to find how many
        // total there are
        for socialMediaName in possibleSocialMediaNameList
        {
            // need to check if user has respective social media type first
            if (dict[socialMediaName] != nil)
            {
                // Get a list of usernames for just one social media type (i.e. all usernames for facebook)
                let socialMediaUserNamesList = dict[socialMediaName] as! Array<String>
                
                for username in socialMediaUserNamesList
                {
                    let pair = KeyValSocialMediaPair(socialMediaType: socialMediaName, socialMediaUserName: username)
                    pairList.append(pair)
                }
            }
        }
        
        return pairList
        
    }
    
    @IBAction func onLogoutButtonClicked(sender: UIButton) {
        
        // Ask user if they really want to log out...
        let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            // present the log in home page
            
            //TODO: Add spinner functionality
            self.performSegueWithIdentifier("logOut", sender: nil)
            
            // Log out AWS
            self.credentialsProvider.clearCredentials()
            self.credentialsProvider.invalidateCachedTemporaryCredentials()
            self.credentialsProvider.clearKeychain()
 
            // get the IDENTITY POOL to log out AWS Cognito
            let pool = getAWSCognitoIdentityUserPool()
            
            print("*** MenuController *** currentUser 1", pool.currentUser()?.username)
            pool.currentUser()?.signOut()
            
            print("*** MenuController *** currentUser 2", pool.currentUser()?.username)
            pool.getUser(self.currentUserName).signOut()
            
            
            // Update new identity ID
            self.credentialsProvider.getIdentityId().continueWithBlock { (resultTask) -> AnyObject? in
              
                print("LOGOUT, identity id is:", resultTask.result)
                print("LOG2, ", self.credentialsProvider.identityId)
                return nil
            }
            

            
            // Clear local cache and user identity
            clearUserDefaults()
            
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
        
    }
    
    // Use to go back to previous VC at ease.
    @IBAction func unwindBackMenuVC(segue: UIStoryboardSegue)
    {
        print("CALLED UNWIND MENUCONTROLLER VC")
    }
    
}
