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
import AWSLambda

class MainContainerViewController: UIViewController, UIPageViewControllerDelegate, MainPageSectionUnderLineViewDelegate {
    
    @IBOutlet weak var sectionUnderlineView0: UIView!
    @IBOutlet weak var sectionUnderlineView1: UIView!
    @IBOutlet weak var sectionUnderlineView2: UIView!
    @IBOutlet weak var sectionUnderlineView3: UIView!
    @IBOutlet weak var sectionUnderlineView4: UIView!

  

    @IBOutlet weak var newsfeedButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var connectionsButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    
//    @IBOutlet weak var notificationView: UIView!
//    @IBOutlet weak var notificationViewLabel: UILabel!
    @IBOutlet weak var noInternetBanner: UIView!
    
    var connectionRequestList : Array<String>! // MAKE IT Connection type LATER
    var firebaseRootRef : FIRDatabaseReference!
    var userName : String!
    var reachability: Reachability!
    var arrivedFromWalkthrough = false
  
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
        sectionUnderlineView4.hidden = true
    }
  
    // prompt the user if he wants to enable app push notification. If yes, register system-level remote notification
    func askUserForPushNotificationPermission() {
      if UIApplication.sharedApplication().isRegisteredForRemoteNotifications() == false {
        let alertTitle = "Enable Push Notification"
        let alertMessage = "Aquaint will notify you when you have new followers, new follow requests or your follow requests to others get accepted! "
        let notificationAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) {
          UIAlertAction in
          
          print("askUserForPushNotificationPermission: user chooses to enable push notification. ")
          registerToReceivePushNotifications()
        }
        
        let noAction = UIAlertAction(title: "Not Now", style: UIAlertActionStyle.Default) {
          UIAlertAction in
          
          print("askUserForPushNotificationPermission: user chooses NOT to enable push notification. ")
        }
        
        notificationAlert.addAction(noAction)
        notificationAlert.addAction(yesAction)
        
        dispatch_async(dispatch_get_main_queue()) {
          self.presentViewController(notificationAlert, animated: true, completion: nil)
        }
        
      } else {
        // app has registered system-level push notification service before.
        // register with APN server every time the app launches, to check any update on deviceToken
        registerToReceivePushNotifications()
      }
      
    }
  

    func isCustomerSubscribed() {
      // Validate receipt first
      let receiptUrl = NSBundle.mainBundle().appStoreReceiptURL
      let receipt: NSData = NSData(contentsOfURL: receiptUrl!)!
      let receiptData: NSString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

      print ("RECEIPTDATA IS: ", receiptData)
//      do {
//        receiptJSON = try NSJSONSerialization.JSONObjectWithData(receipt, options: .MutableLeaves) as? NSJSONSerialization
//        stringJSON = NSSTring(
//      } catch _ {
//        print ("FAILED TO PARSE RECEIPT DATA")
//      }
      let lambdaInnvoker = AWSLambdaInvoker.defaultLambdaInvoker()
      let parameters = ["action": "verifyAppleReceipt", "target": userName, "receipt_json": receiptData]
      lambdaInnvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock({
        (resultTask) -> AnyObject? in
        if resultTask.error == nil && resultTask.result != nil {
          print("Result task for verifyAppleReceipt is: ", resultTask.result!)
        } else {
          print("Result error for verifyAppleReceipt is:")
          print(resultTask.error)
        }
        return nil
      })

      
//      let lambdaInnvoker = AWSLambdaInvoker.defaultLambdaInvoker()
//      let parameters = ["action": "countSubscriptionOfCustomer", "target": userName]
//      lambdaInnvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock({
//        (resultTask) -> AnyObject? in
//        if resultTask.error == nil && resultTask.result != nil {
//          print("Result task for countSubscriptionOfCustomer is: ", resultTask.result!)
//          let numOfPlans = resultTask.result as! Int
//          if (numOfPlans == 0) {
//            setCurrentCachedSubscriptionStatus(false)
//          } else {  // number of subscribed plans can only be 1
//            setCurrentCachedSubscriptionStatus(true)
//          }
//        } else {
//          print(resultTask.error)
//        }
//        return nil
//      })
    }
  
    override func viewDidLoad() {
        // Warm up lambda so that user has better experience. Lambda servers removed from "cache" every 5 min.
        warmUpLambda()
      
        // check if the user is subscribed to paid feature of Aqualytics
        userName = getCurrentCachedUser()
//        isCustomerSubscribed()
      
      
        // Get the mainPageViewController, this holds all our pages!
        mainPageViewController = self.childViewControllers.last as! MainPageViewController

        
        // SET UP NUM NOTIFICATIONS
        // ----------------------------------------------
//        // Hide notificationView (if no notifications)
//        notificationView.hidden = true
//        
//        // Set notificationViewLabel with value 0
//        notificationViewLabel.text = "0"
//        
//        // Make notificationView circular
//        notificationView.layer.cornerRadius = notificationView.frame.size.width / 2
      
        
        // SET UP CONTROL BAR (FOOTER)
        // ----------------------------------------------
        hideAllSectionUnderlineViews()
        
        // Show only the bar for the home icon
        sectionUnderlineView2.hidden = false
        
        // Set banner hidden by default
        noInternetBanner.hidden = true

        // Make user add profiles if they just signed up
        if arrivedFromWalkthrough {
          // Go to settings page
          let dummyButton = UIButton()
          self.goToPage4(dummyButton)
          
          // Take user to AddSocialMediaProfilesController so they can add in profiles
          let storyboard = UIStoryboard(name: "Main", bundle: nil)
          let addSocialMediaVC = storyboard.instantiateViewControllerWithIdentifier("AddSocialMediaProfilesController") as! AddSocialMediaProfilesController
          
          let menuVC = mainPageViewController.childViewControllers.last as! MenuController
  
          // This is important. If we do not set delegate, user cannot add in profiles properly.
          addSocialMediaVC.delegate = menuVC

          dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(addSocialMediaVC, animated: true, completion: nil)
          })
          
        }
      
        askUserForPushNotificationPermission()
      /*
      print("Adding deviceID to dynamoDB table...");
      updateDeviceIDDynamoDB()
      
      // This is triggered by AppDelegate once we finally have user's Device ID. Then we can upload it to the server
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainContainerViewController.updateDeviceIDDynamoDB), name: deviceIdNotificationKey, object: nil)
      updateDeviceIDDynamoDB()
      */
    }
  
  override func viewDidDisappear(animated: Bool) {
//    NSNotificationCenter.defaultCenter().removeObserver(self)

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

  @IBAction func goToPage4(sender: AnyObject) {
    
    mainPageViewController.changePage(4)
    
    hideAllSectionUnderlineViews()
    sectionUnderlineView4.hidden = false
  }
  
    // NOTE: Previous page 2 is NOW PAGE 3.
    // a special case for goToPage3() used for push notification handling. Displaying Followers or Following section in AquaintsContainerViewController
//    func goToPage3OfSection(section: Int) {
//      mainPageViewController.changePageToFollows(section)
//      
//      hideAllSectionUnderlineViews()
//      sectionUnderlineView3.hidden = false
//    }
  
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
        case 4: sectionUnderlineView4.hidden = false
        break;
        default: sectionUnderlineView2.hidden = false
        }

    }
    
    // Prepare for segues and set up delegates so we can get information back
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if segue.identifier == "toMainPageViewController" {
        
        let controller = segue.destinationViewController as! MainPageViewController
        
        // IMPORTANT!!!! If we don't have this we can't get data back.
        controller.sectionDelegate = self
      }
    }
  
}
