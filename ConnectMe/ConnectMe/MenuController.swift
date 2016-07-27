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
    
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var realNameTextFieldLabel: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var numFollowersLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    var currentUserName : String!
    var currentRealName : String!
    var currentUserAccounts : NSMutableDictionary!
    var currentUserImage: UIImage!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    var keyValSocialMediaPairList : Array<KeyValSocialMediaPair>!
    
    var tableViewSectionsDictionary : NSMutableDictionary!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)

    // AWS credentials provider
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e")

    override func viewDidLoad() {
        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2

        // Fetch the user's username and real name
        currentUserName = getCurrentCachedUser()
        currentRealName = getCurrentCachedFullName()
        currentUserImage = getCurrentCachedUserImage()
        currentUserAccounts = getCurrentCachedUserProfiles()
        
        // Set up the data for the table views section. 
        tableViewSectionsDictionary = [ "Linked Profiles" : 1,
                                        "My Information" : 3,
                                      ]
        
        // Initialize array so that collection view has something to check while we
        // fetch data from dynamo
        keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
        
        print("CUR USERNAME: ", currentUserName)
        
        
        // If any values are nil, we need to re-cache
        if (currentRealName == nil ||
            currentUserImage == nil ||
            currentUserAccounts == nil)
        {
            setCachedUserFromAWS(currentUserName)
            
            //re-set attributes
//            currentUserName = getCurrentCachedUser()
            currentRealName = getCurrentCachedFullName()
            currentUserImage = getCurrentCachedUserImage()
            currentUserAccounts = getCurrentCachedUserProfiles()
        }
            
        // Set the UI
        userNameLabel.text = currentUserName
        realNameTextFieldLabel.text  = currentRealName
        profileImageView.image = currentUserImage
        numFollowersLabel.text = "200"
        
        // Set up dictionary for user's social media names
        socialMediaUserNames = currentUserAccounts
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
        
        // If user has added accounts/profiles, show them
        if(currentUserAccounts != nil)
        {
            // Dictionary with key: string of social media types (i.e. "facebook"),
            // val: array of usernames for that social media (i.e. "austinvaday, austinv, sammyv")
            self.socialMediaUserNames = currentUserAccounts
            
            // Convert dictionary to key,val pairs. Redundancy allowed
            self.keyValSocialMediaPairList = self.convertDictionaryToSocialMediaKeyValPairList(self.socialMediaUserNames, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
            
            
            // Perform update on UI on main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // Propogate collection view with new data
                self.settingsTableView.reloadData()
                
                print("RELOADING COLLECTIONVIEW")
            })
        }

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
    // Specify number of sections in our table
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        // Return number of sections
        return tableViewSectionsDictionary.count
    }
    
    // Specify height of header
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return (tableViewSectionsDictionary.allKeys)[section] as? String
    }
    
    
    // Return the number of rows in each given section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionTitle = (tableViewSectionsDictionary.allKeys)[section]
        let sectionCount = tableViewSectionsDictionary.objectForKey(sectionTitle) as! Int
        
        return sectionCount
    }

    // Configure which cell to display
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
    
        // For Linked Profiles, we need to display the profiles cell
        if (indexPath.section == 0)
        {
            let cell = tableView.dequeueReusableCellWithIdentifier("menuProfilesCell") as! MenuProfilesCell!
            return cell
        }

        //else return regular cell
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
        return cell

        

    
        
    }
    
    // Configure/customize each table header view
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionTitle = (tableViewSectionsDictionary.allKeys)[section] as! String
        
        let cell = tableView.dequeueReusableCellWithIdentifier("sectionHeaderCell") as! SectionHeaderCell!
        
        cell.sectionTitle.text = sectionTitle
        
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
    
    
    @IBAction func unwindBackToMenuVC(segue:UIStoryboardSegue)
    {
        print("Success unwind to menu VC")
        print("REFRESH COLLECTION VIEW")
        viewDidLoad()
    }
    
    
}
