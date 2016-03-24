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
import Firebase

class HomeController: UIViewController {
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    var userName : String!
    var userId   : String!
    

    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    var firebaseRootRef : Firebase!
    
    
    override func viewDidLoad() {
        
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        
        //*** NOTE: This is an extra check for top-notch security. It is not necessary.
        // If we're not logged in, immediately go back to beginning page.
        let authData = firebaseRootRef.authData
        
        
        if (authData == nil)
        {
            print("Error in HomeController. authData is somehow nil!")
            self.performSegueWithIdentifier("LogOut", sender: nil)
        
        }
//        else
//        {
//            // Fetch unique user ID
//            userId = authData.uid
//            
//            print (userId)
//            
//            let firebaseUserIdToUserNameRef = firebaseRootRef.childByAppendingPath("UserIdToUserName/" + userId)
//            
//            // Fetch respective username from this id
//            firebaseUserIdToUserNameRef.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
//                print ("DONE1")
//
//                self.userName = snapshot.value as! String
//                
//                print ("DONE")
//                
//                print(self.userName)
//                
//                self.userNameLabel.text = self.userName
//            })
//
//        }
        
        userName = getCurrentUser()
        
        if (userName != nil)
        {
            print(userName)

            userNameLabel.text = userName
        }
        else
        {
            userNameLabel.text = "Welcome!"
        }
        

        
        
        
        
        
        
        
//        // Add gesture recognizer programatacially (buggy if doing so through XIB)
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
//        self.view.userInteractionEnabled = true
//        self.view.addGestureRecognizer(panGestureRecognizer)
        
    }
    
//    // Functionality to handle user pan gestures (dragging left, right, up, down, etc)
//    func handlePan (recognizer: UIPanGestureRecognizer)
//    {
//        print("IN HANDLEPAN")
//        // Get the translation (how much the user moved their finger)
//        let translation = recognizer.translationInView(self.view)
//        let velocity = recognizer.velocityInView(self.view)
//        let view = recognizer.view!
//        
//        // Set the new view's center based on x/y translations that the user initiated
//        // No y translation for now
//        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y /*+ translation.y*/)
//    
//        // Make sure to set recognizer's translation back to 0 to prevent compounding issues
//        recognizer.setTranslation(CGPointZero, inView: self.view)
////
//        
//    }

    @IBAction func menuButtonClicked(sender: AnyObject) {
        // Transition to page on left (menu)
        
//        let pageViewController = storyboard?.instantiateViewControllerWithIdentifier("MainPageViewController") as! MainPageViewController
//        
//        
//        let menuViewController = storyboard?.instantiateViewControllerWithIdentifier("MenuViewController") as! MenuController
//        
//        pageViewController.setViewControllers([menuViewController], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true) { (Bool) -> Void in
//            print("setviewControllers finished")
//        }
//        
//        print("TESTING OK")
//        menuViewController.testLabel.text = "TESTING TESTING"
//        
//        
//        
        
        
    }
    @IBAction func logOutButtonClicked(sender: UIButton) {
        
            // Ask user if they really want to log out...
            let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
            
            let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
                // present the log in home page
                
                //TODO: Add spinner functionality
                self.performSegueWithIdentifier("LogOut", sender: nil)
                
                // Log out of of firebase
                self.firebaseRootRef.unauth()
                
                // Remove all observers
                self.firebaseRootRef.removeAllObservers()
                
                if (self.firebaseRootRef.authData == nil)
                {
                    print("successful log out.")
                    
                    // Set initial view controller back to default
//
//                    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
//                    let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
//                    let viewControllerIdentifier = "BeginningViewController"
//                    
//                    // Go to beginning page, as if user was logged in already!
//                    window.rootViewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerIdentifier)
                }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
        
    }
}
