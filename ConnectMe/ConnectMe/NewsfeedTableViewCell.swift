//
//  NewsfeedTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FRHyperLabel

protocol SponsoredProfileButtonDelegate {
    func didClickSponsoredProfileButton(sponsoredProfileImageName: String, sponsoredProfileImageType: String)
}

class NewsfeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellMessage: FRHyperLabel!
    @IBOutlet weak var cellUserName: UILabel!
    @IBOutlet weak var cellTimeConnected: UILabel!
    @IBOutlet weak var caretImageView: UIImageView!
    @IBOutlet weak var sponsoredProfileImageButton: UIButton!
    @IBOutlet weak var newsfeedView: UIView!
    
    var sponsoredDelegate:SponsoredProfileButtonDelegate?
    var sponsoredProfileImageType : String!
    var sponsoredProfileImageName : String!
    let maxFitScreenWidth = CGFloat(350.0)
    
    // Set default FRHyperLabel for this app. Set it here so that we
    // do not have to set it later (if not, user might see default hyperlink while this is loading)
    override func awakeFromNib() {
        // UI Color for #0F7A9D (www.uicolor.xyz)
        cellMessage.numberOfLines = 0
        
        let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        let attributes = [NSForegroundColorAttributeName: aquaBlue,
                          NSFontAttributeName: UIFont.boldSystemFontOfSize(cellMessage.font.pointSize)]
        cellMessage.linkAttributeDefault = attributes
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let screenWidth = self.superview!.frame.width

        // If we're on iPhone 4S or 5, screen sizes are small and text fields will overflow.
        // Reduce font as a result
        if screenWidth < maxFitScreenWidth
        {
            cellMessage.font = UIFont(name: "Avenir Book", size: 11)
            
            // Reset attributes
            let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
            let attributes = [NSForegroundColorAttributeName: aquaBlue,
                              NSFontAttributeName: UIFont.boldSystemFontOfSize(11)]
            cellMessage.linkAttributeDefault = attributes
            
            cellMessage.reloadInputViews()
            
            

        }
      
    }
    
    func rotateCaret180Degrees()
    {
        
        print("ROTATE")
        
        caretImageView.transform = CGAffineTransformRotate(caretImageView.transform, CGFloat(M_PI))
    }
    

    @IBAction func onSponsoredProfileImageClicked(sender: UIButton) {
        
        print("SPONSORED BUTTON CLICKED")
        
        if sponsoredDelegate != nil
        {
            sponsoredDelegate?.didClickSponsoredProfileButton(sponsoredProfileImageName, sponsoredProfileImageType: sponsoredProfileImageType)
        }
        
    }
    
}
