//
//  MainContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/7/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Firebase

class MainContainerViewController: UIViewController, MainPageViewControllerDelegate, UIPageViewControllerDelegate {
    
    @IBOutlet weak var sectionUnderlineView0: UIView!
    @IBOutlet weak var sectionUnderlineView1: UIView!
    @IBOutlet weak var sectionUnderlineView2: UIView!
    @IBOutlet weak var sectionUnderlineView3: UIView!
    @IBOutlet weak var sectionUnderlineView4: UIView!
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var recentConnectionsButton: UIButton!
    
    @IBOutlet weak var notificationView: UIView!
    @IBOutlet weak var notificationViewLabel: UILabel!
    
    var connectionRequestList : Array<String>! // MAKE IT Connection type LATER
    var firebaseRootRef : Firebase!
    var userName : String!
    
    // This is our child (container) view controller that holds all our pages
    var mainPageViewController: MainPageViewController!

    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
    
    
    // Self-added protocol for MainPageViewControllerDelegate
    func didTransitionPage(sender: MainPageViewController) {

        print("YUUUUUUUUUS")
        showAlert("DELEGATE IMPLEMENTATION SUCCESS", message: "", buttonTitle: "OK", sender: self)
        
    }
    
    // Hides all the section bars for the section underline view/bars under the footer icons
    func hideAllSectionUnderlineViews()
    {
        sectionUnderlineView0.hidden = true
        sectionUnderlineView1.hidden = true
        sectionUnderlineView2.hidden = true
        sectionUnderlineView3.hidden = true
        sectionUnderlineView4.hidden = true
    }
    
    
    
    override func viewDidLoad() {
        
        
        
        // Get the mainPageViewController, this holds all our pages!
        mainPageViewController = self.childViewControllers.last as! MainPageViewController
        
        mainPageViewController.delegate = self
        
        print("YOLO", mainPageViewController.delegate)
        
        // SET UP NOTIFICATIONS
        // ----------------------------------------------
        // Hide notificationView (if no notifications)
        notificationView.hidden = true
        
        // Set notificationViewLabel with value 0
        notificationViewLabel.text = "0"
        
        // Make notificationView circular
        notificationView.layer.cornerRadius = notificationView.frame.size.width / 2
        
        
        // SET UP CONTROL BAR (FOOTER)
        // ----------------------------------------------
        hideAllSectionUnderlineViews()
        
        // Show only the bar for the home icon
        sectionUnderlineView2.hidden = false
        
        // Set up Firebase
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        
        //*** NOTE: This is an extra check for top-notch security. It is not necessary.
        // If we're not logged in, immediately go back to beginning page.
        let authData = firebaseRootRef.authData
        
        if (authData == nil)
        {
            print("Error in HomeController. authData is somehow nil!")
            
        }
        
        
        // Get current user from NSUserDefaults
        userName = getCurrentUser()
        
        
        connectionRequestList = Array<String>()
        
        // Set up Firebase listener for listening for new friend requests
        let firebaseReceivedRequestsRef = Firebase(url: firebaseRootRefString + "/ReceivedRequests")
        
        // WATCH FOR NEW NOTIFICATIONS
        firebaseReceivedRequestsRef.childByAppendingPath(userName).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            
            print("childAdded:", snapshot.key)
            
            self.connectionRequestList.append(snapshot.key as String)
            
            // If there are connection requests, show the notification view and how many requests.
            if (self.connectionRequestList.count > 0)
            {
                self.notificationView.hidden = false
                self.notificationViewLabel.text = String(self.connectionRequestList.count)
            }
            else
            {
                self.notificationView.hidden = true
            }
            
        })
        
        // DELETE NOTIFICATIONS
        firebaseReceivedRequestsRef.childByAppendingPath(userName).observeEventType(FEventType.ChildRemoved, withBlock: { (snapshot) -> Void in
            
            print("childRemoved:", snapshot.key)
            
            
            // If there are connection requests, show the notification view and how many requests.
            if (self.connectionRequestList.count > 0)
            {
                
                // Find person in list, remove that person from list
                for (var i = 0; i < self.connectionRequestList.count; i++)
                {
                    if (self.connectionRequestList[i] == snapshot.key as String)
                    {
                        self.connectionRequestList.removeAtIndex(i)
                    }
                    
                }
                
                let numConnections = self.connectionRequestList.count
                
                if (numConnections == 0)
                {
                    self.notificationView.hidden = true
                }
                else
                {
                    self.notificationView.hidden = false
                    
                }
                self.notificationViewLabel.text = String(self.connectionRequestList.count)
            }
            else
            {
                self.notificationView.hidden = true
            }
            
        })
        
        
        
    }
    
    // BUTTONS TO CHANGE THE PAGE
    
    @IBAction func goToMenuPage(sender: UIButton) {
                
        mainPageViewController.changePage(0)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView0.hidden = false
    }
    
    @IBAction func goToProfilePage(sender: UIButton) {

        mainPageViewController.changePage(1)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView1.hidden = false
    }
    
    @IBAction func goToHomePage(sender: UIButton) {

        mainPageViewController.changePage(2)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView2.hidden = false
    }
    
    @IBAction func goToSearchPage(sender: UIButton) {
    
        mainPageViewController.changePage(3)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView3.hidden = false
    }
    
    @IBAction func goToRecentConnectionsPage(sender: UIButton) {
        
        mainPageViewController.changePage(4)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView4.hidden = false
    }
    
    
    
}