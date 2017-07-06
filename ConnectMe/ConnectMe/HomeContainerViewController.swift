//
//  HomeContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import AWSLambda
import AWSDynamoDB

class HomeContainerViewController: UIViewController, UIPageViewControllerDelegate, HomePageSectionUnderLineViewDelegate {
    
    
//    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var sectionUnderlineView0: UILabel!
    @IBOutlet weak var sectionUnderlineView1: UILabel!
    @IBOutlet weak var aquaintsButton: UIButton!
    @IBOutlet weak var youButton: UIButton!
    @IBOutlet weak var followRequestsView: UIView!
    @IBOutlet weak var numberRequestsLabel: UILabel!
    
    var userName : String!
    
    // This is our child (container) view controller that holds all our pages
    var homePageViewController: HomePageViewController!

  @IBAction func followRequestsButtonClicked(_ sender: UIButton) {
    /*
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let vcFollowRequest = storyboard.instantiateViewControllerWithIdentifier("followRequestsViewController")
    self.presentViewController(vcFollowRequest, animated: true, completion: nil)
    */
    self.performSegue(withIdentifier: "toFollowRequestsViewController", sender: self)
    
  }
  
    // Self-added protocol for MainPageViewControllerDelegate
    func didTransitionPage(_ sender: MainPageViewController) {
        
        showAlert("DELEGATE IMPLEMENTATION SUCCESS", message: "", buttonTitle: "OK", sender: self)
        
    }
    
    // Hides all the section bars for the section underline view/bars under the footer icons
    func hideAllSectionUnderlineViews()
    {
        sectionUnderlineView0.isHidden = true
        sectionUnderlineView1.isHidden = true

    }
  
    override func viewDidLoad() {
      
        // Get the mainPageViewController, this holds all our pages!
        homePageViewController = self.childViewControllers.last as! HomePageViewController
                
        // SET UP CONTROL BAR (ON TOP)
        // ----------------------------------------------
        hideAllSectionUnderlineViews()
        
        // Show only the bar for the aquaints icon
        sectionUnderlineView0.isHidden = false
        
        // Get current user from NSUserDefaults
        userName = getCurrentCachedUser()
      
        // Set username label 
//        userNameLabel.text = userName
      

    }
  
  override func viewDidAppear(_ animated: Bool) {
    
    let privacyStatus = getCurrentCachedPrivacyStatus()
    
    if privacyStatus != nil && privacyStatus == "private" {
      followRequestsView.isHidden = false
      getAndDisplayNumberRequests()
    } else {
      followRequestsView.isHidden = true
    }

    // TESTING
    //self.performSegueWithIdentifier("toFollowRequestsViewController", sender: self)
    
  }
  
    // BUTTONS TO CHANGE THE PAGE
    
        
    
    @IBAction func goToPage0(_ sender: UIButton) {
        
        homePageViewController.changePage(0)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView0.isHidden = false
    }
    
    @IBAction func goToPage1(_ sender: UIButton) {

//        TEMP.. UNCOMMENT IF WANT MORE THAN 1 PAGE.
//        homePageViewController.changePage(1)
//        
//        hideAllSectionUnderlineViews()
//        sectionUnderlineView1.hidden = false
    }
  
  
    func getAndDisplayNumberRequests() {
      let lambdaInvoker = AWSLambdaInvoker.default()
      let parameters = ["action":"getNumFollowRequests", "target": userName]
      lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
        if resultTask.result != nil && resultTask.error == nil
        {
          let num = resultTask.result as! Int
          
          DispatchQueue.main.async(execute: {
            if num < 100 {
              self.numberRequestsLabel.text = String(num)
            } else {
              self.numberRequestsLabel.text = "99+"
            }
          })
        }
        
        return nil
        
      }
      
    }
  
    func updateSectionUnderLineView(_ newViewNum: Int) {
        
        hideAllSectionUnderlineViews()
        
        switch(newViewNum)
        {
        case 0: sectionUnderlineView1.isHidden = false
            break;
        case 1: sectionUnderlineView0.isHidden = false
            break;
        default:
            break;
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
      if segue.identifier == "toHomePageViewController" {
        let controller = segue.destination as! HomePageViewController
        controller.sectionDelegate = self
      }
    }
  
    // Use to go back to previous VC at ease.
    @IBAction func unwindBackToHome(_ segue: UIStoryboardSegue)
    {
      print("CALLED UNWIND VC")
    }

  
}
