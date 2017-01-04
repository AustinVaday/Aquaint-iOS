//
//  RecentConnections.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit

class FollowingViewController: UIViewController, FollowerListSetUserAndActionDelegate {
  
  override func viewDidLoad() {
    // Let's use a re-usable view just for viewing user follows/followings!
    let storyboard = UIStoryboard(name: "FollowerListView", bundle: nil)
    let viewController = storyboard.instantiateViewControllerWithIdentifier("FollowerListViewController") as! FollowerListViewController
    viewController.dataDelegate = self
    
    viewController.view.frame = self.view.frame
    viewController.view.bounds = self.view.bounds
    
    self.view.addSubview(viewController.view)
    
    addChildViewController(viewController)
    viewController.didMoveToParentViewController(self)
    
  }
  
  func dataForUser() -> String {
    return getCurrentCachedUser()
  }
  
  func lambdaActionForUser() -> String {
    return "getFollowees"
  }
  
}
