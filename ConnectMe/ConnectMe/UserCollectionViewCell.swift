//
//  UserCollectionViewCell.swift
//  Aquaint
//
//  Created by Yingbo Wang on 5/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

/*
protocol UserCollectionViewDelegate {
  // TODO
  func didClickUserProfile()
}
*/

class UserCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var userProfileImage: UIImageView!
  @IBOutlet weak var followNumberLabel: UILabel!
  @IBOutlet weak var userNameLabel: UILabel!
  // Self-designed UserCollectionViewCellDelegate protocol
  /*
  var delegate: UserCollectionViewDelegate?
  
  @IBAction func onUserProfileClicked(sender: AnyObject) {
    if delegate != nil {
      delegate!.didClickUserProfile()
    }
  }
  */
}
