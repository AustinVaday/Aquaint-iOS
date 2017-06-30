//
//  FollowRequestsTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/23/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FRHyperLabel
import AWSLambda

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
                      NSFontAttributeName: UIFont.boldSystemFont(ofSize: cellName.font.pointSize)]
    cellName.linkAttributeDefault = attributes
    
  }
  
  @IBAction func onAcceptButtonClicked(_ sender: AnyObject) {
    print("Woot accepted!")
    let follower = cellUserName.text!
    let currentUser = getCurrentCachedUser()
    removeFollowRequest(follower, followee: currentUser!)
    createFollow(follower, followee: currentUser!)
    self.cellDeleteButton.isHidden = true
    
  }
  
  @IBAction func onDeleteButtonClicked(_ sender: AnyObject) {
    print("Ouch rejected..")
    removeFollowRequest(cellUserName.text!, followee: getCurrentCachedUser())
    self.cellAcceptButton.isHidden = true
  }
  
  
  func removeFollowRequest(_ follower: String, followee: String) {
    let lambdaInvoker = AWSLambdaInvoker.default()
    let parameters = ["action":"unfollowRequest", "me": follower, "target": followee]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        // Do some animation
      }
      
      return nil
    }
  }
  
  func createFollow(_ follower: String, followee: String) {
    let lambdaInvoker = AWSLambdaInvoker.default()
    let parameters = ["action":"follow", "me": follower, "target": followee, "userapproved": 1] as [String : Any]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        // Do some animation
      }
      
      return nil
    }
  }

  
}
