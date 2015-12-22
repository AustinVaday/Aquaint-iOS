//
//  HomeController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/21/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit

class HomeController: UIViewController {
    
    // Functionality to handle user pan gestures (dragging left, right, up, down, etc)
    @IBAction func handlePan (recognizer: UIPanGestureRecognizer)
    {
        print("IN HANDLEPAN")
        // Get the translation (how much the user moved their finger)
        let translation = recognizer.translationInView(self.view)
        
        let view = recognizer.view!
        
        // Set the new view's center based on x/y translations that the user initiated
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
    
        // Make sure to set recognizer's translation back to 0 to prevent compounding issues
        recognizer.setTranslation(CGPointZero, inView: self.view)
        
        
    }

}
