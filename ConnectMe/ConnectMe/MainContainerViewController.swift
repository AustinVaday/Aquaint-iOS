//
//  MainContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/7/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Firebase
import ReachabilitySwift
import AWSDynamoDB

class MainContainerViewController: UIViewController, UIPageViewControllerDelegate, MainPageSectionUnderLineViewDelegate {
    
    @IBOutlet weak var sectionUnderlineView0: UIView!
    @IBOutlet weak var sectionUnderlineView1: UIView!
    @IBOutlet weak var sectionUnderlineView2: UIView!
    @IBOutlet weak var sectionUnderlineView3: UIView!
    

    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var connectionsButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    
    @IBOutlet weak var notificationView: UIView!
    @IBOutlet weak var notificationViewLabel: UILabel!
    @IBOutlet weak var noInternetBanner: UIView!
    
    var connectionRequestList : Array<String>! // MAKE IT Connection type LATER
    var firebaseRootRef : FIRDatabaseReference!
    var userName : String!
    var reachability: Reachability!

    // This is our child (container) view controller that holds all our pages
    var mainPageViewController: MainPageViewController!

    let deviceIdNotificationKey = "com.aquaintapp.deviceIdNotificationKey"

  
    // Hides all the section bars for the section underline view/bars under the footer icons
    func hideAllSectionUnderlineViews()
    {
        sectionUnderlineView0.hidden = true
        sectionUnderlineView1.hidden = true
        sectionUnderlineView2.hidden = true
        sectionUnderlineView3.hidden = true
    }
  
  
  // upload current user's device ID to dynamoDB database
  func updateDeviceIDDynamoDB() {
    print("TRIGGERED")
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    let currentUser = getCurrentCachedUser()
    let currentDeviceID = getCurrentCachedDeviceID()
    
    let dynamoDBDevice = Device()
    dynamoDBDevice.username = currentUser
    debugPrint("updateDeviceIDDynamoDB: dynamoDBDevice.username = ", currentUser)
    dynamoDBDevice.deviceid = currentDeviceID
    debugPrint("updateDeviceIDDynamoDB: dynamoDBDevice.deviceid = ", currentDeviceID)
    
    dynamoDBObjectMapper.save(dynamoDBDevice).continueWithBlock(
      { (resultTask) -> AnyObject? in
        if (resultTask.error != nil) {
          print ("DYNAMODB ADD PROFILE ERROR: ", resultTask.error)
        }
        
        if (resultTask.exception != nil) {
          print ("DYNAMODB ADD PROFILE EXCEPTION: ", resultTask.exception)
        }
        
        if (resultTask.result == nil) {
          print ("DYNAMODB ADD PROFILE result is nil....: ")
        } else if (resultTask.error == nil) {
          // If successful save
          print ("DynamoDB add profile success. ", resultTask.result)
          
          // Refresh something...
        }
        return nil
    })
  }
      
    override func viewDidLoad() {

        // Get the mainPageViewController, this holds all our pages!
        mainPageViewController = self.childViewControllers.last as! MainPageViewController

        
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
        sectionUnderlineView0.hidden = false
        
        // Set banner hidden by default
        noInternetBanner.hidden = true
      
//        debugPrint("Adding deviceID to dynamoDB table...");
//        updateDeviceIDDynamoDB()
      
      // This is triggered by AppDelegate once we finally have user's Device ID. Then we can upload it to the server
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainContainerViewController.updateDeviceIDDynamoDB), name: deviceIdNotificationKey, object: nil)
        
    }
  
  override func viewDidDisappear(animated: Bool) {
    NSNotificationCenter.defaultCenter().removeObserver(self)

  }
  
    override func viewDidAppear(animated: Bool) {
        // Set up notifications for determining whether to display the "No Internet" Banner.
        do {
          reachability = try Reachability(hostname: "www.google.com")
        }
        catch {
          print("Could not create reachability object to www.google.com")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: reachability)
        
        do {
          try reachability.startNotifier()
        }
        catch {
          print("Could not start reachability notifier...")
        }
    }
    
    func reachabilityChanged(note: NSNotification)
    {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable()
        {
            if reachability.isReachableViaWiFi()
            {
                print ("Reachable via WIFI")
            }
            else
            {
                print ("Reachable via CELLULAR DATA")
            }
            noInternetBanner.hidden = true
        }
        else
        {
            print ("Internet not reachable")
            noInternetBanner.hidden = false
        }
    }

    override func viewWillDisappear(animated: Bool){
        // Get rid of all notifications we set for wifi connectivity
        reachability.stopNotifier()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
    // BUTTONS TO CHANGE THE PAGE
    
    @IBAction func goToPage0(sender: UIButton) {
                
        mainPageViewController.changePage(0)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView0.hidden = false
    }
    
    @IBAction func goToPage1(sender: UIButton) {

        mainPageViewController.changePage(1)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView1.hidden = false
    }
    
    @IBAction func goToPage2(sender: UIButton) {

        mainPageViewController.changePage(2)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView2.hidden = false
    }
    
    @IBAction func goToPage3(sender: UIButton) {
    
        mainPageViewController.changePage(3)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView3.hidden = false
    }
    
    func updateSectionUnderLineView(newViewNum: Int) {
        hideAllSectionUnderlineViews()
        
        print("DELEGATE showApprop.... WAS CALLED")
        
        switch newViewNum
        {
        case 0: sectionUnderlineView0.hidden = false
        break;
        case 1: sectionUnderlineView1.hidden = false
        break;
        case 2: sectionUnderlineView2.hidden = false
        break;
        case 3: sectionUnderlineView3.hidden = false
        break;
        default: sectionUnderlineView0.hidden = false
        }

    }
    
    // Prepare for segues and set up delegates so we can get information back
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let controller = segue.destinationViewController as! MainPageViewController
        
        // IMPORTANT!!!! If we don't have this we can't get data back.
        controller.sectionDelegate = self

    }
    
}
