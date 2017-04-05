//
//  AnalyticsDisplayViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import Graphs
import AWSLambda



class AnalyticsDisplayViewController: UIViewController, PaymentsDisplayDelegate {

  var username: String!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    username = getCurrentCachedUser()
  }
  
  // We want to check the user's subscription status every time Aqualytics is about to be displayed
  // as user may just subscribe in current session
  override func viewWillAppear(animated: Bool) {
    
      var storyboard: UIStoryboard!
      var viewController: UIViewController!
      
      // Check whether user has paid for the app or not.
      var subscribed = getCurrentCachedSubscriptionStatus()
    
      if self.username == nil {
        self.username = getCurrentCachedUser()
      }
    
    
    if subscribed {
      storyboard = UIStoryboard(name: "AnalyticsDisplay", bundle: nil)
      viewController = storyboard.instantiateViewControllerWithIdentifier("AnalyticsDisplay") as! AnalyticsDisplay
    } else {
      // Else, we show payment plan
      storyboard = UIStoryboard(name: "PaymentsDisplay", bundle: nil)
      viewController = storyboard.instantiateViewControllerWithIdentifier("PaymentsDisplay") as! PaymentsDisplay
      (viewController as! PaymentsDisplay).paidDelegate = self
    }
    
      dispatch_async(dispatch_get_main_queue()) {
        // Get our special popup design from the XIB
        viewController.view.bounds = self.view.bounds
        viewController.view.frame = self.view.frame
        
        self.view.addSubview(viewController.view)
        
        self.addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
      }
    
    if subscribed {
      updateLocalSubscriptionStatusForFuture()
    }
      
  }
  
  func didPayForProduct() {
    let storyboard = UIStoryboard(name: "AnalyticsDisplay", bundle: nil)
    let viewController = storyboard.instantiateViewControllerWithIdentifier("AnalyticsDisplay") as! AnalyticsDisplay
    dispatch_async(dispatch_get_main_queue()) {
      // Get our special popup design from the XIB
      viewController.view.bounds = self.view.bounds
      viewController.view.frame = self.view.frame
      
      self.view.addSubview(viewController.view)
      
      self.addChildViewController(viewController)
      viewController.didMoveToParentViewController(self)
    }

  }
  
  func updateLocalSubscriptionStatusForFuture() {
    
    fetchAndSetCurrentCachedSubscriptionStatus(self.username)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
