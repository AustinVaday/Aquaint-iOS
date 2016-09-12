//
//  ContactsTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/31/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FRHyperLabel

class ContactsTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: FRHyperLabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cellUserName: UILabel!
    @IBOutlet weak var cellTimeConnected: UILabel!

    
    // Set default FRHyperLabel for this app. Set it here so that we
    // do not have to set it later (if not, user might see default hyperlink while this is loading)
    override func awakeFromNib() {
        // UI Color for #0F7A9D (www.uicolor.xyz)
        let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        let attributes = [NSForegroundColorAttributeName: aquaBlue,
                          NSFontAttributeName: UIFont.boldSystemFontOfSize(15.0)]
        cellName.numberOfLines = 0
        cellName.linkAttributeDefault = attributes
    }
   
}
