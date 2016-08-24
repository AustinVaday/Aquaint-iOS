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

class NewsfeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {

    let cellIdentifier = "newsfeedCell"
    @IBOutlet weak var newsfeedTableView: UITableView!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube")
    
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var refreshControl : UIRefreshControl!
//    var connectionList : Array<Connection>!
    var defaultImage : UIImage!
    
    var newsfeedList : NSArray! // Array of dictionary to hold all newsfeed data
    
    
    var expansionObj:CellExpansion!

    override func viewDidLoad() {
        
        newsfeedList = NSArray()
    
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
        
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action":"getNewsfeed", "target": "tolvstad"]
        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error != nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
            }
            else if resultTask.exception != nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
                
            }
            else if resultTask.result == nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            else
            {
                print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
                self.newsfeedList = resultTask.result as! NSArray
                
                
                print (self.newsfeedList[0]["user"])
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.newsfeedTableView.reloadData()
                })

                
            }
            
            return nil
            
        }

        // Fetch the user's username
        currentUserName = getCurrentCachedUser()

//        connectionList = Array<Connection>()
        expansionObj = CellExpansion()

        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()
        
        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(NewsfeedViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        newsfeedTableView.addSubview(refreshControl)
        
    }
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
        newsfeedTableView.addSubview(refreshControl)
        
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
        
        return newsfeedList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! NewsfeedTableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        cell.sponsoredProfileImageButton.layer.cornerRadius = cell.sponsoredProfileImageButton.frame.size.width / 2
        
        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        cell.collectionView.tag = indexPath.row
        
//        let connectedUserName = newsfeedList[indexPath.row]["user"]!
        let event = newsfeedList[indexPath.row]["event"]!
//        let time = newsfeedList[indexPath.row]["time"]!

        switch event!
        {
            // If a friend starts following new people
            case "newfollowing":
                
                let user = newsfeedList[indexPath.row]["user"]!!
                let otherUser = newsfeedList[indexPath.row]["otheruser"]!!
                
                let textString = user +  " started following " + otherUser
                let textStringLength = textString.characters.count
                
                // Find location of and bold the user names in the text string, store as cell message.
                cell.cellMessage.attributedText = createAttributedTextString(textString, boldStartArray: [0, textStringLength - otherUser.characters.count], boldEndArray: [user.characters.count, textStringLength])
                
                break;
            // If I myself have a new follower
            case "newfollower":
                
                let otherUser = newsfeedList[indexPath.row]["otheruser"]!!
                
                let textString = otherUser +  " started following you"
                let textStringLength = textString.characters.count
                
                // Find location of and bold the user names in the text string, store as cell message.
                cell.cellMessage.attributedText = createAttributedTextString(textString, boldStartArray: [0], boldEndArray: [otherUser.characters.count])
                break;
            
            // If a friend adds in a new profile
            case "newprofile":
                
                let otherUser = newsfeedList[indexPath.row]["otheruser"]!!
                let socialMediaType = newsfeedList[indexPath.row]["data"]!["type"]!!
                let socialMediaName = newsfeedList[indexPath.row]["data"]!["name"]!!
                
                print("SOCIAL MEDIA TYPE: ", newsfeedList[indexPath.row]["data"]!["type"])
                print("SOCIAL MEDIA NAME: ", newsfeedList[indexPath.row]["data"]!["name"])

                
                let textString = otherUser +  " added a " + socialMediaType + " account, check it out!"
                
                cell.cellMessage.attributedText = createAttributedTextString(textString, boldStartArray: [0], boldEndArray: [otherUser.characters.count])
                
                // show the new account that was added
                cell.sponsoredProfileImageType = socialMediaType
                cell.sponsoredProfileImageName = socialMediaName
                
                cell.sponsoredProfileImageButton.hidden = false
                print("SocialMediaType var is: ", socialMediaType)
                cell.sponsoredProfileImageButton.imageView!.image = socialMediaImageDictionary[socialMediaType]
                

                break;
            
            default:
                break;
            
        }
        
        
        
        cell.cellImage.image = defaultImage
        cell.cellTimeConnected.text = "2s"
        
        
        
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
//        return connectionList[collectionView.tag].socialMediaUserNames.count

        return 2
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        print("CVTAG IS:", collectionView.tag)
        
//        
//        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
//        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
//        var userSocialMediaNames = connectionList[collectionView.tag].socialMediaUserNames.allKeys as! Array<String>
//        userSocialMediaNames = userSocialMediaNames.sort()
//        
//        print(indexPath.item)
//        let socialMediaName = userSocialMediaNames[indexPath.item % self.possibleSocialMediaNameList.count]
//        
//        print(socialMediaName)
//        
//        // We will delay the image assignment to prevent buggy race conditions
//        // (Check to see what happens when the delay is not set... then you'll understand)
//        // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
//        delay(0) { () -> () in
//            
//            // Generate a UI image for the respective social media type
//            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaName]
//            
//            cell.socialMediaName = socialMediaName
//            
//        }
        
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
    

}
