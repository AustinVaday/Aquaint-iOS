//
//  HomeContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Firebase

class HomeContainerViewController: UIViewController, UIPageViewControllerDelegate, HomePageSectionUnderLineViewDelegate {
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var sectionUnderlineView0: UILabel!
    @IBOutlet weak var sectionUnderlineView1: UILabel!

    @IBOutlet weak var aquaintsButton: UIButton!
    @IBOutlet weak var youButton: UIButton!
    
    var connectionRequestList : Array<String>! // MAKE IT Connection type LATER
    var firebaseRootRef : FIRDatabaseReference!
    var userName : String!
    
    // This is our child (container) view controller that holds all our pages
    var homePageViewController: HomePageViewController!
    
    // Self-added protocol for MainPageViewControllerDelegate
    func didTransitionPage(sender: MainPageViewController) {
        
        showAlert("DELEGATE IMPLEMENTATION SUCCESS", message: "", buttonTitle: "OK", sender: self)
        
    }
    
    // Hides all the section bars for the section underline view/bars under the footer icons
    func hideAllSectionUnderlineViews()
    {
        sectionUnderlineView0.hidden = true
        sectionUnderlineView1.hidden = true

    }
    
    
    
    override func viewDidLoad() {
        
        // Get the mainPageViewController, this holds all our pages!
        homePageViewController = self.childViewControllers.last as! HomePageViewController
                
        // SET UP CONTROL BAR (ON TOP)
        // ----------------------------------------------
        hideAllSectionUnderlineViews()
        
        // Show only the bar for the aquaints icon
        sectionUnderlineView0.hidden = false
        
        // Set up Firebase
        firebaseRootRef = FIRDatabase.database().reference()
        
        // Get current user from NSUserDefaults
        userName = getCurrentCachedUser()
        
        connectionRequestList = Array<String>()
        
        // Set username label 
        userNameLabel.text = userName
        

    }
    
    // BUTTONS TO CHANGE THE PAGE
    
        
    
    @IBAction func goToPage0(sender: UIButton) {
        
        homePageViewController.changePage(0)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView0.hidden = false
    }
    
    @IBAction func goToPage1(sender: UIButton) {
        
        homePageViewController.changePage(1)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView1.hidden = false
    }
    
    func updateSectionUnderLineView(newViewNum: Int) {
        
        hideAllSectionUnderlineViews()
        
        switch(newViewNum)
        {
        case 0: sectionUnderlineView0.hidden = false
            break;
        case 1: sectionUnderlineView1.hidden = false
            break;
        default: sectionUnderlineView0.hidden = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let controller = segue.destinationViewController as! HomePageViewController
        
        controller.sectionDelegate = self
    }

}
