//
//  ScanCodeDisplayStoryboardViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/19/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class ScanCodeDisplayStoryboardViewController: UIViewController {
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      DispatchQueue.main.async { 
        // Get our special popup design from the XIB
        let storyboard = UIStoryboard(name: "ScanCodeDisplay", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ScanCodeDisplayViewController") as! ScanCodeDisplay
        
        viewController.view.bounds = self.view.bounds
        viewController.view.frame = self.view.frame
        
        self.view.addSubview(viewController.view)

        self.addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)

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
