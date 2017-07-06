//
//  AquaintsSingleFollowerListViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/1/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class AquaintsSingleFollowerListViewController: ViewControllerPannable, FollowerListSetUserAndActionDelegate {
  
  @IBOutlet weak var dataView: UIView!
  @IBOutlet weak var nameHeaderLabel: UILabel!
  var currentUserName: String!
  var lambdaAction: String!
  
  // Store the popup that this VC came from. Will need to restore later
  var profilePopupView : ProfilePopupView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if lambdaAction == "getFollowers" {
      nameHeaderLabel.text = "Followers"
    } else if lambdaAction == "getFollowees" {
      nameHeaderLabel.text = "Following"
    } else {
      print("ERROR AquaintsSingleFollowerListViewController - invalid lambdaAction. Current options: getFollowers, getFollowees.")
    }
    
    
    // Let's use a re-usable view just for viewing user follows/followings!
    let storyboard = UIStoryboard(name: "FollowerListView", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "FollowerListViewController") as! FollowerListViewController
    viewController.dataDelegate = self
    
    viewController.view.frame = dataView.frame
    viewController.view.frame.origin = CGPoint(x: 0, y: 20)
    viewController.view.bounds = dataView.bounds
    viewController.view.bounds.origin = CGPoint(x: 0, y: 20)

    dataView.addSubview(viewController.view)
    
    addChildViewController(viewController)
    viewController.didMove(toParentViewController: self)
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    awsMobileAnalyticsRecordPageVisitEventTrigger("AquaintsSingleFollowerListViewController", forKey: "page_name")
  }
  
  func dataForUser() -> String {
    return currentUserName
  }
  
  func lambdaActionForUser() -> String {
    return lambdaAction
  }
  
  @IBAction func backButtonClicked(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)
    
    if (profilePopupView != nil)
    {
      showPopupForUserWithView(profilePopupView)
    }
  }

}
