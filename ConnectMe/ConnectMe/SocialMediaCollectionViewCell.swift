//
//  SocialMediaCollectionViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/12/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

protocol SocialMediaCollectionDeletionDelegate
{
    func userDidDeleteSocialMediaProfile(socialMediaType:String, socialMediaName:String)
}

class SocialMediaCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var emblemImage: UIImageView!
    @IBOutlet weak var deleteSocialMediaButton: UIButton!
//    @IBOutlet weak var profilesLockedIcon: UIImageView!
  
    var socialMediaName: String!// I.e. austinvaday, samsung, etc...
    var socialMediaType: String!// I.e. Facebook, IG, Snapchat...
    var delegate: SocialMediaCollectionDeletionDelegate?
    
    
    @IBAction func onDeleteSocialMediaButtonClicked(sender: AnyObject) {
        if delegate != nil
        {
            delegate?.userDidDeleteSocialMediaProfile(socialMediaType, socialMediaName: socialMediaName)
        }
    }
    
    
}

