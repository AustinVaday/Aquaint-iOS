//
//  ContactsTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/31/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class ContactsTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cellUserName: UILabel!
    @IBOutlet weak var cellTimeConnected: UILabel!
    
    @IBAction func nameButtonClicked(sender: AnyObject) {
        showPopupForUser(cellUserName.text!)
    }
}
