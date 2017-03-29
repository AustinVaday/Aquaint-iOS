//
//  AnalyticsDisplayViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class AnalyticsDisplayViewController: UIViewController {

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dispatch_async(dispatch_get_main_queue()) {
      
      var storyboard: UIStoryboard!
      var viewController: UIViewController!
      
      // Check whether user has paid for the app or not.
      var subscribed = getCurrentCachedSubscriptionStatus()
      
      // DEBUG PURPOSES! REMOVE BEFORE SUBMIT
      subscribed = true
      
      // If user has paid for the app, show analytics)
      if (subscribed)
      {
        storyboard = UIStoryboard(name: "AnalyticsDisplay", bundle: nil)
        viewController = storyboard.instantiateViewControllerWithIdentifier("AnalyticsDisplay") as! AnalyticsDisplay
      } else {
        // Else, we show payment plan
        storyboard = UIStoryboard(name: "PaymentsDisplay", bundle: nil)
        viewController = storyboard.instantiateViewControllerWithIdentifier("PaymentsDisplay") as! PaymentsDisplay
      }
      
      // Get our special popup design from the XIB
      viewController.view.bounds = self.view.bounds
      viewController.view.frame = self.view.frame
      
      self.view.addSubview(viewController.view)
      
      self.addChildViewController(viewController)
      viewController.didMoveToParentViewController(self)
      
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
