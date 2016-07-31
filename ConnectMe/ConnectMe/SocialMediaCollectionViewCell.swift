//
//  SocialMediaCollectionViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/12/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class SocialMediaCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var emblemImage: UIImageView!
    @IBOutlet weak var deleteSocialMediaButton: UIButton!
    var socialMediaName: String!// I.e. austinvaday, samsung, etc...
    var socialMediaType: String!// I.e. Facebook, IG, Snapchat...
    
}

