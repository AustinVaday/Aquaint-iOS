//
//  ScanCodeDisplayStoryboardViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/19/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class ScanCodeDisplayStoryboardViewController: UIViewController {

  @IBOutlet weak var displayView: UIView!
  @IBOutlet weak var userNameLabel: UILabel!
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      let currentUser = getCurrentCachedUser()
      
      if currentUser != nil {
        userNameLabel.text = currentUser
      }

      dispatch_async(dispatch_get_main_queue()) { 
        // Get our special popup design from the XIB
        let storyboard = UIStoryboard(name: "ScanCodeDisplay", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier("ScanCodeDisplayViewController")
        
        self.addChildViewController(viewController)
        self.displayView.addSubview(viewController.view)
        viewController.didMoveToParentViewController(self)
        
        // Set popup's content view to be what we just fetched
//        self.view.addSubview(viewController.view)
        // Do any additional setup after loading the view.

      }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
