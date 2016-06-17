//
//  FriendRequestsController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/21/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Firebase
import AWSS3

class FriendRequestsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
 
    @IBOutlet weak var requestsTableView: UITableView!
//    @IBOutlet weak var searchTableView: UITableView!
    
//    @IBOutlet weak var notificationViewLabel: UILabel!
//    @IBOutlet weak var notificationView: UIView!
//    
//    @IBOutlet weak var sectionUnderlineView0: UIView!
//    @IBOutlet weak var sectionUnderlineView1: UIView!
//    @IBOutlet weak var sectionUnderlineView2: UIView!
//    @IBOutlet weak var sectionUnderlineView3: UIView!
//    @IBOutlet weak var sectionUnderlineView4: UIView!
    
    var userName : String!
    var userId   : String!
    var firebaseRootRef : Firebase!
    var defaultImage : UIImage!
    
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    let awsBucketName = "aquaint-userimages"
    
    var connectionRequestList : Array<Connection>! // MAKE IT Connection type LATER
    
    override func viewDidLoad() {
        
        
        connectionRequestList = Array<Connection>()
        
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
//        // SET UP NOTIFICATIONS
//        // ----------------------------------------------
//        // Hide notificationView (if no notifications)
//        notificationView.hidden = true
//        
//        // Set notificationViewLabel with value 0
//        notificationViewLabel.text = "0"
//        
//        // Make notificationView circular
//        notificationView.layer.cornerRadius = notificationView.frame.size.width / 2
//        
//        
//        // SET UP CONTROL BAR (FOOTER)
//        // ----------------------------------------------
//        hideAllSectionUnderlineViews()
//        
//        // Show only the bar for the home icon
//        sectionUnderlineView2.hidden = false
        
        
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        
        //*** NOTE: This is an extra check for top-notch security. It is not necessary.
        // If we're not logged in, immediately go back to beginning page.
        let authData = firebaseRootRef.authData
        
        if (authData == nil)
        {
            print("Error in FriendRequestsController. authData is somehow nil!")
            self.performSegueWithIdentifier("LogOut", sender: nil)
            
        }
        
        // Get current user from NSUserDefaults
        userName = getCurrentUser()
        
//        if (userName != nil)
//        {
//            print(userName)
//            
//            userNameLabel.text = userName
//        }
//        else
//        {
//            userNameLabel.text = "Welcome, guest!"
//        }
        
        
        //        // Add gesture recognizer programatacially (buggy if doing so through XIB)
        //        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        //        self.view.userInteractionEnabled = true
        //        self.view.addGestureRecognizer(panGestureRecognizer)
        
        
        
//        // Set up Firebase listener for listening for new friend requests
//        let firebaseReceivedRequestsRef = Firebase(url: firebaseRootRefString + "/ReceivedRequests")
//        
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
        // FOR FILLING THE TABLE:
        
        let firebaseUsersRef = Firebase(url: firebaseRootRefString + "Users/")
        let firebaseUserImagesRef = Firebase(url: firebaseRootRefString + "UserImages/")
        print (userName)
        let firebaseReceivedRequestsRef = Firebase(url: firebaseRootRefString + "ReceivedRequests/" + userName)
    
        firebaseReceivedRequestsRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            let user = Connection()

            // Store respective user info (key is the username)
            user.userName = snapshot.key

            // Retrieve user's info (except image)
            firebaseUsersRef.childByAppendingPath(user.userName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
                user.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
                
            })
            
            
            // Store the user's image
            firebaseUserImagesRef.childByAppendingPath(user.userName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
                // Get base 64 string image
                
                // If user has an image, display it in table. Else, display default image
                if (snapshot.exists())
                {
                    let userImageBase64String = snapshot.childSnapshotForPath("/profileImage").value as! String
                    user.userImage = convertBase64ToImage(userImageBase64String)
                }
                else
                {
                    user.userImage = self.defaultImage
                }
                
                self.requestsTableView.reloadData()
                
            })
            
            self.connectionRequestList.append(user)
            
            self.requestsTableView.reloadData()
            
        })

        
        firebaseReceivedRequestsRef.observeEventType(FEventType.ChildRemoved, withBlock: { (snapshot) -> Void in
            
            // Store respective user info (key is the username of connectee)
            let keyName = snapshot.key
            
            for i in 0...self.connectionRequestList.count-1
            {
                // Find the person to remove from this list
                if (self.connectionRequestList[i].userName == keyName)
                {
                    self.connectionRequestList.removeAtIndex(i)
                    break
                }
                
            }
                self.requestsTableView.reloadData()
            
        })
        
        
        
    }
    /*
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
    
    
    }
    */
    
    
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
        
//        self.searchTableView.reloadData()
        
        print("RELOADED")
        
        
        
    }
    
    @IBAction func recentConnectionsButtonClicked(sender: UIButton) {
//
//        let pageViewController = storyboard?.instantiateViewControllerWithIdentifier("MainPageViewController") as! MainPageViewController
//        
//        pageViewController.changePage()
        
    }
    
    
    // **** REQUESTS TABLE VIEW *****
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("requestsCell", forIndexPath: indexPath) as! RequestsTableViewCell
        
        let userFullName = connectionRequestList[indexPath.item].userFullName
        let userName     = connectionRequestList[indexPath.item].userName
        let userImage    = connectionRequestList[indexPath.item].userImage
        
        cell.cellName.text = userFullName
        cell.cellUserName.text = userName
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return connectionRequestList.count
        
    }
    

    

}