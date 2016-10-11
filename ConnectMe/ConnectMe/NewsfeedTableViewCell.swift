//
//  NewsfeedTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FRHyperLabel

class NewsfeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellMessage: FRHyperLabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cellUserName: UILabel!
    @IBOutlet weak var cellTimeConnected: UILabel!
    @IBOutlet weak var caretImageView: UIImageView!
    @IBOutlet weak var sponsoredProfileImageButton: UIButton!
    @IBOutlet weak var newsfeedView: UIView!
    
    var sponsoredProfileImageType : String!
    var sponsoredProfileImageName : String!
    
    
    // Set default FRHyperLabel for this app. Set it here so that we
    // do not have to set it later (if not, user might see default hyperlink while this is loading)
    override func awakeFromNib() {
        // UI Color for #0F7A9D (www.uicolor.xyz)
        let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        let attributes = [NSForegroundColorAttributeName: aquaBlue,
                          NSFontAttributeName: UIFont.boldSystemFontOfSize(11)]
        cellMessage.numberOfLines = 0
        cellMessage.linkAttributeDefault = attributes
//        cellMessage.adjustsFontSizeToFitWidth = true
//        cellMessage.minimumScaleFactor = 0.2
        
        // Change cellMessage max width to a value close to the width of the frame itself
        // Note: 10 is arbritrary
//        cellMessageWidthConstraint.constant = self.frame.width - cellImage.frame.width - cellTimeConnected.frame.width - 10
    }
    
    func rotateCaret180Degrees()
    {
        
        print("ROTATE")
        
        caretImageView.transform = CGAffineTransformRotate(caretImageView.transform, CGFloat(M_PI))
    }
    

    @IBAction func onSponsoredProfileImageClicked(sender: UIButton) {
        
        print("SPONSORED BUTTON CLICKED")
        
        let socialMediaURL = getUserSocialMediaURL(sponsoredProfileImageName, socialMediaTypeName: sponsoredProfileImageType, sender: self)
        
        // Perform the request, go to external application and let the user do whatever they want!
        UIApplication.sharedApplication().openURL(socialMediaURL)
        
    }
    
}
