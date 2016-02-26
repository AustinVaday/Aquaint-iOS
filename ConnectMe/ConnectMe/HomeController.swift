//
//  HomeController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/21/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Parse

class HomeController: UIViewController {
    
    override func viewDidLoad() {
        
        // Add gesture recognizer programatacially (buggy if doing so through XIB)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        self.view.userInteractionEnabled = true
        self.view.addGestureRecognizer(panGestureRecognizer)
        
    }
    
    // Functionality to handle user pan gestures (dragging left, right, up, down, etc)
    func handlePan (recognizer: UIPanGestureRecognizer)
    {
        print("IN HANDLEPAN")
        // Get the translation (how much the user moved their finger)
        let translation = recognizer.translationInView(self.view)
        let velocity = recognizer.velocityInView(self.view)
        let view = recognizer.view!
        
        // Set the new view's center based on x/y translations that the user initiated
        // No y translation for now
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y /*+ translation.y*/)
    
        // Make sure to set recognizer's translation back to 0 to prevent compounding issues
        recognizer.setTranslation(CGPointZero, inView: self.view)
//
        
    }

    @IBAction func logOutButtonClicked(sender: UIButton) {
        
        // Ask user if they really want to log out...
        let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            // present the log in home page
            
            //TODO: Add spinner functionality
            self.performSegueWithIdentifier("LogOut", sender: nil)
            
            // Log out of Parse, too
            PFUser.logOutInBackground()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
        
    }
}
