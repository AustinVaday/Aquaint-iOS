//
//  HomeContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Firebase

class HomeContainerViewController: UIViewController, UIPageViewControllerDelegate {
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var sectionUnderlineView0: UILabel!
    @IBOutlet weak var sectionUnderlineView1: UILabel!

    @IBOutlet weak var aquaintsButton: UIButton!
    @IBOutlet weak var youButton: UIButton!
    
    var connectionRequestList : Array<String>! // MAKE IT Connection type LATER
    var firebaseRootRef : Firebase!
    var userName : String!
    
    // This is our child (container) view controller that holds all our pages
    var homePageViewController: HomePageViewController!
    
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
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
        
        homePageViewController.delegate = self
        
        // SET UP CONTROL BAR (ON TOP)
        // ----------------------------------------------
        hideAllSectionUnderlineViews()
        
        // Show only the bar for the aquaints icon
        sectionUnderlineView0.hidden = false
        
        // Set up Firebase
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        
        // Get current user from NSUserDefaults
        userName = getCurrentUser()
        
        connectionRequestList = Array<String>()
        
        // Set username label 
        userNameLabel.text = userName
        
        // Set up Firebase listener for listening for new friend requests
        let firebaseReceivedRequestsRef = Firebase(url: firebaseRootRefString + "/ReceivedRequests")
        
//        // WATCH FOR NEW NOTIFICATIONS
//        firebaseReceivedRequestsRef.childByAppendingPath(userName).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
//            
//            
//            print("childAdded:", snapshot.key)
//            
//            self.connectionRequestList.append(snapshot.key as String)
//            
//            // If there are connection requests, show the notification view and how many requests.
//            if (self.connectionRequestList.count > 0)
//            {
//                self.notificationView.hidden = false
//                self.notificationViewLabel.text = String(self.connectionRequestList.count)
//            }
//            else
//            {
//                self.notificationView.hidden = true
//            }
//            
//        })
//        
//        // DELETE NOTIFICATIONS
//        firebaseReceivedRequestsRef.childByAppendingPath(userName).observeEventType(FEventType.ChildRemoved, withBlock: { (snapshot) -> Void in
//            
//            print("childRemoved:", snapshot.key)
//            
//            
//            // If there are connection requests, show the notification view and how many requests.
//            if (self.connectionRequestList.count > 0)
//            {
//                
//                // Find person in list, remove that person from list
//                for (var i = 0; i < self.connectionRequestList.count; i++)
//                {
//                    if (self.connectionRequestList[i] == snapshot.key as String)
//                    {
//                        self.connectionRequestList.removeAtIndex(i)
//                    }
//                    
//                }
//                
//                let numConnections = self.connectionRequestList.count
//                
//                if (numConnections == 0)
//                {
//                    self.notificationView.hidden = true
//                }
//                else
//                {
//                    self.notificationView.hidden = false
//                    
//                }
//                self.notificationViewLabel.text = String(self.connectionRequestList.count)
//            }
//            else
//            {
//                self.notificationView.hidden = true
//            }
//            
//        })
//        
//        
//        
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

}
