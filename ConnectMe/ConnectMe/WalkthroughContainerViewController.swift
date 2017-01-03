//
//  WalkthroughContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/2/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit


class WalkthroughContainerViewController: UIViewController, WalkthroughPageViewDelegate {

  @IBOutlet weak var footerButton: UIButton!
  
  // This is our child (container) view controller that holds all our pages
  var walkthroughPageViewController: WalkthroughPageViewController!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Get the walkthroughPageViewController, this holds all our pages!
    walkthroughPageViewController = self.childViewControllers.last as! WalkthroughPageViewController
    walkthroughPageViewController.pageDelegate = self
      // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func didHitLastPage() {
    footerButton.setTitle("LINK PROFILES", forState: UIControlState.Normal)
  }
  
  func didLeaveLastPage() {
    footerButton.setTitle("NEXT", forState: UIControlState.Normal)

  }

  @IBAction func onNextButtonClicked(sender: AnyObject) {
    walkthroughPageViewController.goToNextPage()
  }
   

}
