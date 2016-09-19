//
//  AddSocialMediaPageTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 9/19/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class AddSocialMediaPageTableViewCell: UITableViewCell {

    
    @IBOutlet weak var socialMediaTypeLabel: UILabel!
    @IBOutlet weak var emblemImage: UIImageView!
    
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!

    var checkMarkFlippedCopy: UIImageView!
    var socialMediaType: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        self.emblemImage.hidden = false
        
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        
        flipImageHorizontally(checkMarkFlippedCopy)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    func showSuccessAnimation()
    {
        emblemImage.hidden = true
        
        UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
            
            self.checkMarkFlipped.hidden = false
            self.checkMarkFlipped.image = self.checkMark.image
            
            }, completion: { (boolResult) -> Void in
                
                UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
                    
                    self.checkMarkFlipped.hidden = true
                    self.emblemImage.hidden = false
                    
                }, completion: nil)
                
            })
        
        self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image

    }
    
}
