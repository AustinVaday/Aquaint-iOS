//
//  PaymentsDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import Stripe

// Will have the real displays and data
class PaymentsDisplay: UIViewController {
  
  override func viewDidLoad() {
    
  }
  
  @IBAction func onClickBuyTop(sender: AnyObject) {
    let checkoutViewController = CheckoutViewController(product: "le producto",
                                                        price: 200)
    self.presentViewController(checkoutViewController, animated: true, completion: nil)

  }
  
  @IBAction func onClickBuyMiddle(sender: AnyObject) {
  }
  
  @IBAction func onClickBuyBottom(sender: AnyObject) {
  }
  
  
}
