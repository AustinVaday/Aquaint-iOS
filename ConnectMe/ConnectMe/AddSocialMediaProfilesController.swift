//
//  AddSocialMediaProfilesController.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/8/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class AddSocialMediaProfilesController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)
    
    override func viewDidLoad() {
       
        // Set up dictionary for user's social media names
        socialMediaUserNames = NSMutableDictionary()
        
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
    }
    
    
    
    /*************************************************************************
    *    COLLECTION VIEW PROTOCOL
    **************************************************************************/
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print ("SELECTED")
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("addProfileCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
    
        let socialMediaName = possibleSocialMediaNameList[indexPath.item % possibleSocialMediaNameList.count]
        
        // Generate a UI image for the respective social media type
        cell.emblemImage.image = socialMediaImageDictionary[socialMediaName]
        
        cell.socialMediaName = socialMediaName
        
        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        return cell
    }

}
