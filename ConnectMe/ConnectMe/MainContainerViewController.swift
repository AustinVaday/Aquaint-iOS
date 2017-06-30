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
  
  // flags for push notification handling, when the app is killed and relaunched
  let NO_NOTIFICATION = 0
  let NEW_FOLLOWER = 1
  let FOLLOW_REQUEST_ACCEPTANCE = 2
  let NEW_FOLLOW_REQUESTS = 3
  var arrivedFromPushNotification = 0
  
    // This is our child (container) view controller that holds all our pages
    var mainPageViewController: MainPageViewController!

    let deviceIdNotificationKey = "com.aquaintapp.deviceIdNotificationKey"

  
    // Hides all the section bars for the section underline view/bars under the footer icons
    func hideAllSectionUnderlineViews()
    {
        sectionUnderlineView0.isHidden = true
        sectionUnderlineView1.isHidden = true
        sectionUnderlineView2.isHidden = true
        sectionUnderlineView3.isHidden = true
        sectionUnderlineView4.isHidden = true
    }
  

    func isCustomerSubscribed() {
      // Validate receipt first
      let receiptUrl = Bundle.main.appStoreReceiptURL
      let receipt: Data = try! Data(contentsOf: receiptUrl!)
      let receiptData: NSString = receipt.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) as NSString

      print ("RECEIPTDATA IS: ", receiptData)
//      do {
//        receiptJSON = try NSJSONSerialization.JSONObjectWithData(receipt, options: .MutableLeaves) as? NSJSONSerialization
//        stringJSON = NSSTring(
//      } catch _ {
//        print ("FAILED TO PARSE RECEIPT DATA")
//      }
      let lambdaInnvoker = AWSLambdaInvoker.default()
      let parameters = ["action": "verifyAppleReceipt", "target": userName, "receipt_json": receiptData] as [String : Any]
      lambdaInnvoker.invokeFunction("mock_api", jsonObject: parameters).continue({
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
        sectionUnderlineView2.isHidden = false
        
        // Set banner hidden by default
        noInternetBanner.isHidden = true

        // Make user add profiles if they just signed up
        if arrivedFromWalkthrough {
          // Go to settings page
          let dummyButton = UIButton()
          self.goToPage4(dummyButton)
          
          // Take user to AddSocialMediaProfilesController so they can add in profiles
          let storyboard = UIStoryboard(name: "Main", bundle: nil)
          let addSocialMediaVC = storyboard.instantiateViewController(withIdentifier: "AddSocialMediaProfilesController") as! AddSocialMediaProfilesController
          
          let menuVC = mainPageViewController.childViewControllers.last as! MenuController
  
          // This is important. If we do not set delegate, user cannot add in profiles properly.
          addSocialMediaVC.delegate = menuVC
          addSocialMediaVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext

          DispatchQueue.main.async(execute: {
            self.present(addSocialMediaVC, animated: true, completion: nil)
          })
          
        }
      
      // push notification handling, when the app is killed and relaunched
      switch arrivedFromPushNotification {
      case NEW_FOLLOWER:
        goToPage4OfSection(0)
        break
        
      case FOLLOW_REQUEST_ACCEPTANCE:
        goToPage4OfSection(1)
        break
        
      case NEW_FOLLOW_REQUESTS:
        goToPage0AndShowFollowRequests()
        break
        
      default:
        print("MainContainerViewController(arrivedFromPushNotification): undefined flag.")
        break
      }
      
      askUserForPushNotificationPermission(self)
      
      // clear all badges from previous notifications on the app icon
      UIApplication.shared.applicationIconBadgeNumber = 0
      
      //
      /*
      print("Adding deviceID to dynamoDB table...");
      updateDeviceIDDynamoDB()
      
      // This is triggered by AppDelegate once we finally have user's Device ID. Then we can upload it to the server
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainContainerViewController.updateDeviceIDDynamoDB), name: deviceIdNotificationKey, object: nil)
      updateDeviceIDDynamoDB()
      */
    }
  
  override func viewDidDisappear(_ animated: Bool) {
//    NSNotificationCenter.defaultCenter().removeObserver(self)

  }
  
    override func viewDidAppear(_ animated: Bool) {
        // Set up notifications for determining whether to display the "No Internet" Banner.
        do {
          reachability = try Reachability(hostname: "www.google.com")
        }
        catch {
          print("Could not create reachability object to www.google.com")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: reachability)
        
        do {
          try reachability.startNotifier()
        }
        catch {
          print("Could not start reachability notifier...")
        }
    }
    
    func reachabilityChanged(_ note: Notification)
    {
        let reachability = note.object as! Reachability
        
        if reachability.isReachable
        {
            if reachability.isReachableViaWiFi
            {
                print ("Reachable via WIFI")
            }
            else
            {
                print ("Reachable via CELLULAR DATA")
            }
            noInternetBanner.isHidden = true
        }
        else
        {
            print ("Internet not reachable")
            noInternetBanner.isHidden = false
        }
    }

    override func viewWillDisappear(_ animated: Bool){
        // Get rid of all notifications we set for wifi connectivity
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
    // BUTTONS TO CHANGE THE PAGE
    
    @IBAction func goToPage0(_ sender: UIButton) {
                
        mainPageViewController.changePage(0)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView0.isHidden = false
    }
  
  // a special case for goToPage0 used for push notification handling
  func goToPage0AndShowFollowRequests() {
    let dummyButton = UIButton()
    
    mainPageViewController.changePageToFollowRequests()
    
    hideAllSectionUnderlineViews()
    sectionUnderlineView0.isHidden = false
  }
  
    @IBAction func goToPage1(_ sender: UIButton) {

        mainPageViewController.changePage(1)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView1.isHidden = false
    }
    
    @IBAction func goToPage2(_ sender: UIButton) {

        mainPageViewController.changePage(2)
        
        hideAllSectionUnderlineViews()
        sectionUnderlineView2.isHidden = false
    }
  
  @IBAction func goToPage3(_ sender: UIButton) {
    
    mainPageViewController.changePage(3)
    
    hideAllSectionUnderlineViews()
    sectionUnderlineView3.isHidden = false
  }

  @IBAction func goToPage4(_ sender: AnyObject) {
    
    mainPageViewController.changePage(4)
    
    hideAllSectionUnderlineViews()
    sectionUnderlineView4.isHidden = false
  }
  
  // NOTE: After adding Aqualytics, Previous page 2 is NOW PAGE 3.
  // a special case for goToPage4() used for push notification handling. Displaying Followers or Following section in MenuController
  func goToPage4OfSection(_ section: Int) {
    mainPageViewController.changePageToFollows(section)
    
    hideAllSectionUnderlineViews()
    sectionUnderlineView3.isHidden = false
  }

  
    func updateSectionUnderLineView(_ newViewNum: Int) {
        hideAllSectionUnderlineViews()
        
        print("DELEGATE showApprop.... WAS CALLED")
        
        switch newViewNum
        {
        case 0: sectionUnderlineView0.isHidden = false
        break;
        case 1: sectionUnderlineView1.isHidden = false
        break;
        case 2: sectionUnderlineView2.isHidden = false
        break;
        case 3: sectionUnderlineView3.isHidden = false
        break;
        case 4: sectionUnderlineView4.isHidden = false
        break;
        default: sectionUnderlineView2.isHidden = false
        }

    }
    
    // Prepare for segues and set up delegates so we can get information back
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "toMainPageViewController" {
        
        let controller = segue.destination as! MainPageViewController
        
        // IMPORTANT!!!! If we don't have this we can't get data back.
        controller.sectionDelegate = self
      }
    }
  
}
