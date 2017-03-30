//
//  AnalyticsDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda

// Will have the real displays and data
class AnalyticsDisplay: UIViewController, UITableViewDelegate, UITableViewDataSource {

  enum AnalyticsDataEnum: Int {
    case ENGAGEMENT_BREAKDOWN
    case LOCATION
  }

  struct SectionTitleAndCountPair
  {
    var sectionTitle : String!
    var sectionCount : Int!
  }

  @IBOutlet weak var analyticsTableView: UITableView!
  var currentUserName : String!
  let footerHeight = CGFloat(65)
  let defaultTableViewCellHeight = CGFloat(55)
  var tableViewSectionsList : Array<String>!
  var refreshControl : CustomRefreshControl!
  var engagementBreakdownRowCount = 0
  var locationRowCount = 0
  var socialProviderToEngagementCountList = NSMutableArray()
  var locationToCountList = NSArray()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Get current username
    currentUserName = getCurrentCachedUser()
    
    // Set up the data for the table views section.
    tableViewSectionsList = Array<String>()
    tableViewSectionsList.append("ENGAGEMENT BREAKDOWN")
    tableViewSectionsList.append("LOCATION OF VIEWERS")
    
    // Call this function to generate dummy data (before data actually loads)
    generateDummyAnalyticsData()
    
    // Call this function to generate all analytics data for this page!
    generateAnalyticsData()
    
    // Set up refresh control for when user drags for a refresh.
    refreshControl = CustomRefreshControl()
    
    // When user pulls, this function will be called
    refreshControl.addTarget(self, action: #selector(MenuController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
    analyticsTableView.addSubview(refreshControl)
  }
  
  override func viewDidAppear(animated: Bool) {
    // Call this function to generate all analytics data for this page!
    generateAnalyticsData()
  }
  
  /**************************************************************************
   *    TABLE VIEW PROTOCOL
   **************************************************************************/
  // Specify number of sections in our table
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    
    // Return number of sections
    return tableViewSectionsList.count
  }
  
  // Specify height of header
  func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 30
  }
  
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return tableViewSectionsList[section]
  }
  
  // Specify height of table view cells
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    
    var returnHeight : CGFloat!
    
    switch indexPath.section
    {
    case AnalyticsDataEnum.ENGAGEMENT_BREAKDOWN.rawValue:
      returnHeight = defaultTableViewCellHeight
      break;
    case AnalyticsDataEnum.LOCATION.rawValue:
      returnHeight = defaultTableViewCellHeight
    default:
      returnHeight = defaultTableViewCellHeight
    }
    
    return returnHeight
  }
  
  // Return the number of rows in each given section
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var numRows = 0
    switch tableViewSectionsList[section]
    {
    case "ENGAGEMENT BREAKDOWN":
      numRows = engagementBreakdownRowCount
      break;
    case "LOCATION OF VIEWERS":
      numRows = locationRowCount
    default:
      numRows = 0
    }
    return numRows
  }
  
  // Configure which cell to display
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("analyticsContentCell") as! AnalyticsContentTableViewCell!
    switch indexPath.section
    {
    case AnalyticsDataEnum.ENGAGEMENT_BREAKDOWN.rawValue:
      if (socialProviderToEngagementCountList.count == 0) {
        return cell
      }
      cell.numericalValueLabel.text = String(socialProviderToEngagementCountList[indexPath.item][1])
      cell.numericalTypeLabel.text = "CLICKS"
      cell.socialProviderLabel.text = String(socialProviderToEngagementCountList[indexPath.item][0])
      break;
    case AnalyticsDataEnum.LOCATION.rawValue:
      if (locationToCountList.count == 0){
        return cell
      }
      cell.numericalValueLabel.text = String(locationToCountList[indexPath.item][1])
      cell.numericalTypeLabel.text = "VIEWS"
      cell.socialProviderLabel.text = String(locationToCountList[indexPath.item][0])
      break;
    default:
      break;
      
    }

    return cell
  }
  
  // Configure/customize each table header view
  func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    let sectionTitle = tableViewSectionsList[section]
    let cell = tableView.dequeueReusableCellWithIdentifier("analyticsHeaderCell") as! AnalyticsHeaderTableViewCell!
    cell.title.text = sectionTitle
    
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  // Helper functions
  //---------------------------------------------------------------------------------------------------
  // Function that is called when user drags/pulls table with intention of refreshing it
  func refreshTable(sender:AnyObject)
  {
    self.refreshControl.beginRefreshing()
    generateAnalyticsData()
    
    // Need to end refreshing
    delay(0.5)
    {
      self.refreshControl.endRefreshing()
      print("REFRESH CONTROL!")
      
    }
    
    
  }
  
  func generateAnalyticsData() {
    
    // Get list of all social media platforms the user currently supports
    let userProfiles = getCurrentCachedUserProfiles() as NSDictionary!
    let userSocialPlatforms = userProfiles.allKeys as! Array<String>
    
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    var parameters = ["action":"getUserTotalEngagementsBreakdown", "target": currentUserName, "social_list": userSocialPlatforms]
    
//    var parameters = NSDictionary()
//    self.socialProviderToEngagementCountList = NSMutableArray()
//    self.engagementBreakdownRowCount = 0
//    
//    for platform in userSocialPlatforms {
//      // Get engagement info
//      parameters = ["action":"getUserSingleEngagements", "target": currentUserName, "social_platform": platform]
//      lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
//        if resultTask.error == nil && resultTask.result != nil
//        {
//          print("Result task for getUserSingleEngagements is: ", resultTask.result!)
//          
//          let number = resultTask.result as? Int
//          var tuple = Array<String>()
//          tuple.append(platform)
//          tuple.append(String(number!))
//          self.socialProviderToEngagementCountList.addObject(tuple)
//          self.engagementBreakdownRowCount = self.engagementBreakdownRowCount + 1
//          
//          dispatch_async(dispatch_get_main_queue(), {
//            self.analyticsTableView.reloadData()
//          })
//        }
//        
//        return nil
//      }
//
//    }
    
    // Get engagement info
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getUserTotalEngagementsBreakdown is: ", resultTask.result!)
        
        self.socialProviderToEngagementCountList = resultTask.result as! NSMutableArray
        self.engagementBreakdownRowCount = self.socialProviderToEngagementCountList.count
        
        dispatch_async(dispatch_get_main_queue(), {
          self.analyticsTableView.reloadData()
        })
      }
      
      return nil
    }

    // Get location info
    parameters = ["action":"getUserPageViewsLocations", "target": currentUserName, "max_results": 15]
    
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getUserPageViewsLocations is: ", resultTask.result!)
        
        self.locationToCountList = resultTask.result as! NSArray
        self.locationRowCount = self.locationToCountList.count
        
        dispatch_async(dispatch_get_main_queue(), {
          self.analyticsTableView.reloadData()
        })
      }
      
      return nil
    }
    
    
  }
  
  func generateDummyAnalyticsData() {
    // Get list of all social media platforms the user currently supports
    let userProfiles = getCurrentCachedUserProfiles() as NSDictionary!
    let userSocialPlatforms = userProfiles.allKeys as! Array<String>
    
    engagementBreakdownRowCount = userSocialPlatforms.count
    self.socialProviderToEngagementCountList = NSMutableArray()
    analyticsTableView.reloadData()
    
    for platform in userSocialPlatforms {
      var tuple = Array<String>()
      tuple.append(platform)
      tuple.append("...")
      self.socialProviderToEngagementCountList.addObject(tuple)
      
      dispatch_async(dispatch_get_main_queue(), { 
        self.analyticsTableView.reloadData()
      })
    }
    
  }


}
