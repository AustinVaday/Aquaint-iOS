//
//  FollowRequestsTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/23/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FRHyperLabel

class FollowRequestsTableViewCell: UITableViewCell {
  @IBOutlet weak var cellImage: UIImageView!
  @IBOutlet weak var cellName: FRHyperLabel!
  @IBOutlet weak var cellAcceptButton: UIButton!
  @IBOutlet weak var cellDeleteButton: UIButton!
  @IBOutlet weak var cellUserName: UILabel!

  // Set default FRHyperLabel for this app. Set it here so that we
  // do not have to set it later (if not, user might see default hyperlink while this is loading)
  override func awakeFromNib() {
    // UI Color for #0F7A9D (www.uicolor.xyz)
    cellName.numberOfLines = 0
    
    let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
    let attributes = [NSForegroundColorAttributeName: aquaBlue,
                      NSFontAttributeName: UIFont.boldSystemFontOfSize(cellName.font.pointSize)]
    cellName.linkAttributeDefault = attributes
    
  }
  
  @IBAction func onAcceptButtonClicked(sender: AnyObject) {
    print("Ouch rejected..")
  }
  
  @IBAction func onDeleteButtonClicked(sender: AnyObject) {
    print("Woot accepted!")
  }
  
  

  
}
