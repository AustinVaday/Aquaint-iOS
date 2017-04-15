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
  var analyticsDisplayVC: AnalyticsDisplay!
  var paymentsDisplayVC: PaymentsDisplay!
  var analyticsAddedToSubview = false
  var paymentsAddedToSubview = false
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    username = getCurrentCachedUser()
    
    var storyboard = UIStoryboard(name: "AnalyticsDisplay", bundle: nil)
    analyticsDisplayVC = storyboard.instantiateViewControllerWithIdentifier("AnalyticsDisplay") as! AnalyticsDisplay
    
    storyboard = UIStoryboard(name: "PaymentsDisplay", bundle: nil)
    paymentsDisplayVC = storyboard.instantiateViewControllerWithIdentifier("PaymentsDisplay") as! PaymentsDisplay
    paymentsDisplayVC.paidDelegate = self
  }
  
  // We want to check the user's subscription status every time Aqualytics is about to be displayed
  // as user may just subscribe in current session
  override func viewWillAppear(animated: Bool) {
    
      var viewController: UIViewController!
      
      // Check whether user has paid for the app or not.
      let subscribed = getCurrentCachedSubscriptionStatus()

      if self.username == nil {
        self.username = getCurrentCachedUser()
      }
    
      dispatch_async(dispatch_get_main_queue()) {
        
        if subscribed {
          viewController = self.analyticsDisplayVC
        } else {
          // Else, we show payment plan
          viewController = self.paymentsDisplayVC
        }

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
//    let storyboard = UIStoryboard(name: "AnalyticsDisplay", bundle: nil)
//    let viewController = storyboard.instantiateViewControllerWithIdentifier("AnalyticsDisplay") as! AnalyticsDisplay
    let viewController = analyticsDisplayVC
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
