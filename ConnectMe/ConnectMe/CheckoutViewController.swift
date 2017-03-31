//
//  CheckoutViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/30/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import Stripe

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {
  
  
  var paymentInProgress: Bool = false {
    didSet {
      UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
        if self.paymentInProgress {
          self.activityIndicator.startAnimating()
          self.activityIndicator.alpha = 1
          self.buyButton.alpha = 0
        }
        else {
          self.activityIndicator.stopAnimating()
          self.activityIndicator.alpha = 0
          self.buyButton.alpha = 1
        }
        }, completion: nil)
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  

}
