//
//  CustomRefreshControl.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/28/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class CustomRefreshControl: UIRefreshControl {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
  var customView : UIView!
  var spinnerImageView : UIView!
  let darkBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
  let aquaLightBlue = UIColor(red:0.62, green:0.97, blue:0.98, alpha:1.0)
  
  override init() {
    super.init()
    
    self.backgroundColor = UIColor.clearColor()
    self.tintColor = UIColor.clearColor()
    let refreshContents = NSBundle.mainBundle().loadNibNamed("RefreshContents", owner: self, options: nil)
    customView = refreshContents[0] as! UIView
    spinnerImageView = customView.subviews.first! as UIView
    customView.bounds = self.bounds
    customView.frame = self.frame
    self.addSubview(customView)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func beginRefreshing() {
    spinnerImageView.hidden = false
    super.beginRefreshing()
    
    let rotate = CABasicAnimation(keyPath: "transform.rotation")
    rotate.fromValue = 0
    rotate.toValue = 2 * M_PI
    rotate.duration = 1.2;
    rotate.repeatCount = 6;
    
    spinnerImageView.layer.addAnimation(rotate, forKey: "10")

    // Can't find a color animation that looks good
//    UIView.animateWithDuration(1, animations: {
//      self.customView.backgroundColor = UIColor.blueColor()
//    })
//    
//    UIView.animateWithDuration(1.5, animations: {
//      self.customView.backgroundColor = self.aquaLightBlue
//    })
    
    
//    self.customView.backgroundColor = self.darkBlue
    
  }
  
  override func endRefreshing() {
    spinnerImageView.hidden = true
    super.endRefreshing()
  }


}
