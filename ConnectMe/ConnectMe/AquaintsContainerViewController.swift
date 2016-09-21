//
//  AquaintsContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 9/21/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class AquaintsContainerViewController: UIViewController, UIPageViewControllerDelegate, AquaintsPageSectionUnderLineViewDelegate {
    
    @IBOutlet weak var sectionUnderlineView0: UILabel!
    @IBOutlet weak var sectionUnderlineView1: UILabel!
    
    @IBOutlet weak var button0: UIButton!
    @IBOutlet weak var button1: UIButton!

    
    // This is our child (container) view controller that holds all our pages
    var childPageViewController: AquaintsPageViewController!
    
    // Self-added protocol for AquaintsPageViewControllerDelegate
    func didTransitionPage(sender: AquaintsPageViewController) {
        
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
        childPageViewController = self.childViewControllers.last as! AquaintsPageViewController
        
        // SET UP CONTROL BAR (ON TOP)
        // ----------------------------------------------
        hideAllSectionUnderlineViews()
        
        // Show only the bar for the aquaints icon
        sectionUnderlineView0.hidden = false
    }
    
    // BUTTONS TO CHANGE THE PAGE
    @IBAction func goToPage0(sender: UIButton) {
        
        childPageViewController.changePage(0)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView0.hidden = false
    }
    
    @IBAction func goToPage1(sender: UIButton) {
        
        childPageViewController.changePage(1)

        hideAllSectionUnderlineViews()
        sectionUnderlineView1.hidden = false
    }
    
    func updateSectionUnderLineView(newViewNum: Int) {
        
        hideAllSectionUnderlineViews()
        
        switch(newViewNum)
        {
        case 0: sectionUnderlineView1.hidden = false
        break;
        case 1: sectionUnderlineView0.hidden = false
        break;
        default:
            break;
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let controller = segue.destinationViewController as! AquaintsPageViewController
        controller.sectionDelegate = self
    }
    
}
