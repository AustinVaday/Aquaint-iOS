//
//  AnalyticsDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda
import Graphs
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// Will have the real displays and data
class AnalyticsDisplay: UIViewController, UITableViewDelegate, UITableViewDataSource, PaymentsDisplayDelegate {
  
  enum AnalyticsDataEnum: Int {
    case view_BREAKDOWN
    case engagement_BREAKDOWN
//    case GENDER
    case location
//    case DEVICE_TYPE
  }

  struct SectionTitleAndCountPair
  {
    var sectionTitle : String!
    var sectionCount : Int!
  }


  @IBOutlet weak var analyticsTableView: UITableView!
  @IBOutlet weak var unlockDataButton: UIButton!
  
  var currentUserName : String!
  let footerHeight = CGFloat(65)
  let defaultTableViewCellHeight = CGFloat(55)
  let noDataToDisplayCellHeight = CGFloat(25)
  let graphTableViewCellHeight = CGFloat(200)
  var tableViewSectionsList : Array<String>!
  var refreshControl : CustomRefreshControl!
  var engagementBreakdownRowCount = 0
  var locationRowCount = 1
  var socialProviderToEngagementCountList = Array<Array<String>>()
  var locationToCountList = NSArray()
  var graphViewForViews : GraphView<String, Int>!
  var graphViewForGender : GraphView<String, Int>!
  var graphViewForDevices : GraphView<String, Int>!
  var isGeneratingEngagementAnalytics = false
  var isGeneratingViewBreakdownAnalytics = false
  var viewBreakdownList = Array<Array<Int>>()
  var alreadyInitializedSection = [false, false, false] // NOTE: MODIFY TO SIZE OF AnalyticsDataEnum
  var paymentsStoryboard: UIStoryboard?
  var paymentsDisplayVC : PaymentsDisplay!
  var subscribed = false
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    // Get current username
    currentUserName = getCurrentCachedUser()
    
    subscribed = getCurrentCachedSubscriptionStatus()

    
    // Set up the data for the table views section.
    tableViewSectionsList = Array<String>()
    tableViewSectionsList.append("PROFILE VIEWS PER DAY (LAST 10 DAYS)")
    tableViewSectionsList.append("ENGAGEMENT BREAKDOWN")
    //    tableViewSectionsList.append("VIEWER GENDER BREAKDOWN")
    tableViewSectionsList.append("LOCATION OF VIEWERS")
    //    tableViewSectionsList.append("VIEWER DEVICE BREAKDOWN")
    
    
    // Call this function to generate all analytics data for this page!
    generateAnalyticsData()
    
    fetchAndSetCurrentCachedSubscriptionStatus(self.currentUserName, completion: {(result, error) in
       // Nothing
    })
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
      // Set up refresh control for when user drags for a refresh.
      refreshControl = CustomRefreshControl()
      
      // When user pulls, this function will be called
      refreshControl.addTarget(self, action: #selector(MenuController.refreshTable(_:)), for: UIControlEvents.valueChanged)
    
      analyticsTableView.addSubview(refreshControl)

      paymentsStoryboard = UIStoryboard(name: "PaymentsDisplay", bundle: nil)
      paymentsDisplayVC = paymentsStoryboard!.instantiateViewController(withIdentifier: "PaymentsDisplay") as! PaymentsDisplay
      paymentsDisplayVC.paidDelegate = self
      paymentsDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext

    
      if getCurrentCachedPromoUserStatus() == true || getCurrentCachedSubscriptionStatus() == true {
        self.didPayForProduct()
      } else {
        self.lockAndHideProduct()
      }
    
    fetchAndSetCurrentCachedSubscriptionStatus(self.currentUserName, completion: {(result, error) in
      DispatchQueue.main.async(execute: {
        if result! {
          self.didPayForProduct()
        } else {
          self.lockAndHideProduct()
        }
      })
      
    })


   }
  
  override func viewWillAppear(_ animated: Bool) {

  }
  
  override func viewDidAppear(_ animated: Bool) {
    // Call this function to generate all analytics data for this page!
//    generateAnalyticsData()
    awsMobileAnalyticsRecordPageVisitEventTrigger("AnalyticsDisplay", forKey: "page_name")
   
    // Since we preload data in init, sometimes data will appear stale. This will fix that.
    self.analyticsTableView.reloadData()
    
    // Call this function to generate all analytics data for this page!
//    generateAnalyticsData()
  }
  
  @IBAction func unlockMoreDataButtonClicked(_ sender: AnyObject) {
    self.present(paymentsDisplayVC, animated: true, completion: nil)
  }
  
  
  @IBAction func unlockButtonClicked(_ sender: AnyObject) {
    self.present(paymentsDisplayVC, animated: true, completion: nil)
  }
  
  func didPayForProduct() {
    // REMOVE ALL LOCKS
    if !getCurrentCachedPromoUserStatus() {
      setCurrentCachedSubscriptionStatus(true)
    }
    
    subscribed = true
    self.unlockDataButton.isHidden = true
    self.analyticsTableView.reloadData()
  }
  
  func lockAndHideProduct() {
    subscribed = false
    self.unlockDataButton.isHidden = false
    self.analyticsTableView.reloadData()
  }

  
  /**************************************************************************
   *    TABLE VIEW PROTOCOL
   **************************************************************************/
  // Specify number of sections in our table
  func numberOfSections(in tableView: UITableView) -> Int {
    
    // Return number of sections
    return tableViewSectionsList.count
  }
  
  // Specify height of header
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 30
  }
  
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return tableViewSectionsList[section]
  }
  
  // Specify height of table view cells
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
    var returnHeight : CGFloat!
    
    switch indexPath.section
    {
    case AnalyticsDataEnum.view_BREAKDOWN.rawValue:
      if viewBreakdownList.isEmpty || allZeroDisplayValues(viewBreakdownList) {
        returnHeight = noDataToDisplayCellHeight
      } else {
        returnHeight = graphTableViewCellHeight
      }
      break;
    case AnalyticsDataEnum.engagement_BREAKDOWN.rawValue:
      if socialProviderToEngagementCountList.isEmpty {
        returnHeight = noDataToDisplayCellHeight
      } else {
        returnHeight = defaultTableViewCellHeight
      }
      
      break;
//    case AnalyticsDataEnum.GENDER.rawValue:
//      returnHeight = graphTableViewCellHeight
//      break;
    case AnalyticsDataEnum.location.rawValue:
      if locationToCountList.count == 0 {
        returnHeight = noDataToDisplayCellHeight
      } else {
        returnHeight = defaultTableViewCellHeight
      }
      break;
//    case AnalyticsDataEnum.DEVICE_TYPE.rawValue:
//      returnHeight = graphTableViewCellHeight
//      break;
    default:
      returnHeight = defaultTableViewCellHeight
    }
    
    return returnHeight
  }
  
  // Return the number of rows in each given section
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var numRows = 0
    switch tableViewSectionsList[section]
    {
    case "PROFILE VIEWS PER DAY (LAST 10 DAYS)":
      numRows = 1
    case "ENGAGEMENT BREAKDOWN":
      if socialProviderToEngagementCountList.isEmpty {
        numRows = 1 // Display no data cell
      } else {
        numRows = self.socialProviderToEngagementCountList.count
      }
      break;
//    case "VIEWER GENDER BREAKDOWN":
//      numRows = 1
//      break;
    case "LOCATION OF VIEWERS":
      if locationToCountList.count == 0 {
        numRows = 1 // Display no data cell
      } else {
        numRows = self.locationToCountList.count
      }
      break;
//    case "VIEWER DEVICE BREAKDOWN":
//      numRows = 1
//      break;
    default:
      numRows = 0
    }
    return numRows
  }
  
  // Configure which cell to display
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "analyticsContentCell") as! AnalyticsContentTableViewCell!
    switch indexPath.section
    {
      
    case AnalyticsDataEnum.view_BREAKDOWN.rawValue:
      if viewBreakdownList.isEmpty || allZeroDisplayValues(viewBreakdownList) {
        return tableView.dequeueReusableCell(withIdentifier: "noDataToDisplayCell")!
      }
      // Configure cell for graph
      let graphCell = tableView.dequeueReusableCell(withIdentifier: "freeViewCell") as! AnalyticsFreeViewTableViewCell!
      
      if graphViewForViews != nil {
        graphViewForViews.removeFromSuperview()
      }
      
      self.viewBreakdownList.sort(by: { (obj1, obj2) -> Bool in
        return Int(obj1[0]) > Int(obj2[0])
      })
      
      let barGraphData = extractDataArray(viewBreakdownList) as Array<Int>
//    let barGraphData = [10000000, 10000000, 9000000, 20000, 95000,20000,20000,20000, 10, 2000 ]
//      graphViewForViews = barGraphData.barGraph().view(graphCell.viewDisplay.bounds).barGraphConfiguration({ BarGraphViewConfig(barColor: UIColor(hex: "#ff6699"), contentInsets: UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)) })

//      graphViewForViews = [8, 12, 13, 10, 7, 11, 9, 14, 12, 6].lineGraph(GraphRange(min: 5, max: 14)).view(graphCell.viewDisplay.bounds).lineGraphConfiguration({ LineGraphViewConfig(lineColor: UIColor(hex: "#ff6699"), lineWidth: 2.0, dotDiameter: 10.0) })

      
      var graphFont = UIFont(name: "avenir", size: CGFloat(10))
      
      // Decrease size in font to display millions of digits
      barGraphData.forEach({ (val) in
        if val > 99000 {
          graphFont = UIFont(name: "avenir", size: CGFloat(6.5))
        }
      })
      // Test to see how it looks with large numbers --> not bad.
      graphViewForViews = barGraphData.barGraph().view((graphCell?.viewDisplay.bounds)!).barGraphConfiguration({ BarGraphViewConfig(barColor: UIColor(hex: "#ff6699"), textFont: graphFont, contentInsets: UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)) })
      
      
      
      graphCell?.viewDisplay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      graphCell?.viewDisplay.addSubview(graphViewForViews)
      return graphCell!
    case AnalyticsDataEnum.engagement_BREAKDOWN.rawValue:
      if (socialProviderToEngagementCountList.count == 0) {
        return tableView.dequeueReusableCell(withIdentifier: "noDataToDisplayCell")!
      }
      
      let engagementArray = socialProviderToEngagementCountList[indexPath.item] as NSArray
      cell?.numericalValueLabel.text = String(describing: engagementArray[1])
      cell?.numericalTypeLabel.text = "CLICKS"
      cell?.socialProviderLabel.text = String(describing: engagementArray[0])
      
      if (subscribed) {
        cell?.numericalValueLabel.isHidden = false
        cell?.numericalValueLockImage.isHidden = true
      } else {
        cell?.numericalValueLabel.isHidden = true
        cell?.numericalValueLockImage.isHidden = false
      }

      
      // Add blur to freemium users
//      let lockIconImage = UIImage(named: "Password Icon Black")
//      let lockIconView = UIImageView(image: lockIconImage)
//
////      lockIconView.frame = cell.numericalValueLabel.bounds
//      lockIconView.frame = CGRect(x: cell.numericalValueLabel.bounds.width - 20, y: 2, width: 20 , height: 20)
//      
//      // Ensure lock icon is not stretched
//      
//      let blur = UIBlurEffect(style: .ExtraLight)
//      let blurView = UIVisualEffectView(effect: blur)
//      
//      let whiteView = UIView()
//      whiteView.backgroundColor = UIColor.whiteColor()
////      blurView.alpha = 0.5
//      blurView.frame = cell.numericalValueLabel.bounds
////      cell.numericalValueLabel.addSubview(blurView)
//      cell.numericalValueLabel.addSubview(whiteView)
//      cell.numericalValueLabel.addSubview(lockIconView)
      
      break;
      
//    case AnalyticsDataEnum.GENDER.rawValue:
//      // Configure cell for graph
//      let graphCell = tableView.dequeueReusableCellWithIdentifier("freeViewCell") as! AnalyticsFreeViewTableViewCell!
//      
//      if graphViewForGender != nil {
//        graphViewForGender.removeFromSuperview()
//      }
//      
//      
////      (u, t) -> String? in String(format: "%.0f%%", (Float(u.value) / Float(t)))
//      
//      graphViewForGender = [900,500,20].pieGraph().view(graphCell.viewDisplay.bounds).pieGraphConfiguration({ PieGraphViewConfig(textFont: UIFont(name: "Avenir-Next", size: 14.0), isDounut: true, contentInsets: UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)) })
//      
////      graphViewForGender = [8.5, 20.0].pieGraph(){ }.
//      
//      graphCell.viewDisplay.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//      graphCell.viewDisplay.addSubview(graphViewForGender)
//      return graphCell
//      break;
    case AnalyticsDataEnum.location.rawValue:
      if (locationToCountList.count == 0){
        return tableView.dequeueReusableCell(withIdentifier: "noDataToDisplayCell")!
      }
      
      let locationTemp = locationToCountList[indexPath.item] as! NSArray
      cell?.numericalValueLabel.text = String(describing: locationTemp[1])
      cell?.numericalTypeLabel.text = "VIEWS"
      
      // Add blur to freemium users
//      let blur = UIBlurEffect(style: .ExtraLight)
//      let blurView = UIVisualEffectView(effect: blur)
////      blurView.alpha = 0.5
//      blurView.frame = cell.numericalValueLabel.bounds
//      cell.numericalValueLabel.addSubview(blurView)
      if (subscribed) {
        cell?.numericalValueLabel.isHidden = false
        cell?.numericalValueLockImage.isHidden = true
      } else {
        cell?.numericalValueLabel.isHidden = true
        cell?.numericalValueLockImage.isHidden = false
      }
      
      var city = locationTemp[0] as! String
      
      // Enhance readability
      if city == "(not set)" {
        city = "Unknown"
      }
      
      cell?.socialProviderLabel.text = city

      break;
//    case AnalyticsDataEnum.DEVICE_TYPE.rawValue:
//      // Configure cell for graph
//      let graphCell = tableView.dequeueReusableCellWithIdentifier("freeViewCell") as! AnalyticsFreeViewTableViewCell!
//      
//      if graphViewForDevices != nil {
//        graphViewForDevices.removeFromSuperview()
//      }
//      
//      graphViewForDevices = [100, 200, 10].pieGraph().view(graphCell.viewDisplay.bounds).pieGraphConfiguration({ PieGraphViewConfig(textFont: UIFont(name: "DINCondensed-Bold", size: 14.0), isDounut: true, contentInsets: UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)) })
//      
//      graphCell.viewDisplay.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//      graphCell.viewDisplay.addSubview(graphViewForDevices)
//      return graphCell
//
//      break;
    default:
      break;
      
    }

    return cell!
  }
  
  // Configure/customize each table header view
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    let sectionTitle = tableViewSectionsList[section]
    let cell = tableView.dequeueReusableCell(withIdentifier: "analyticsHeaderCell") as! AnalyticsHeaderTableViewCell!
    cell?.title.text = sectionTitle
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  }
  
  // Helper functions
  //---------------------------------------------------------------------------------------------------
  // Function that is called when user drags/pulls table with intention of refreshing it
  func refreshTable(_ sender:AnyObject)
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
    var userSocialPlatforms = Array<String>()
    if userProfiles != nil {
      userSocialPlatforms = userProfiles?.allKeys as! Array<String>
    }
    let lambdaInvoker = AWSLambdaInvoker.default()
    var parameters = NSDictionary()
    
    if !isGeneratingViewBreakdownAnalytics {
      isGeneratingViewBreakdownAnalytics = true
      
      var newViewBreakdownList = Array<Array<Int>>()
//      self.viewBreakdownList = Array<Array<Int>>()
      
      for daysAgo in stride(from: 10, through: 1, by: -1) {
        print("Fetching data for ", daysAgo, " days ago...")
        // Get engagement info
        parameters = ["action":"getUserSinglePayViewsForDay", "target": currentUserName, "days_ago": daysAgo]
        lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
          if resultTask.error == nil && resultTask.result != nil
          {
            print("Result task for getUserSinglePayViewsForDay is: ", resultTask.result!)
 
            DispatchQueue.main.async(execute: {
              let number = resultTask.result as? Int
              
              var tuple = Array<Int>()
              tuple.append(daysAgo)
              tuple.append(number!)
              
              newViewBreakdownList.append(tuple)
              
              if (daysAgo == 1)
              {
                // If all zero values, don't display data
                if self.allZeroDisplayValues(newViewBreakdownList)
                {
                  newViewBreakdownList = Array<Array<Int>>()
                }

              }
              
//              // Regenerate data in more aesthetic ways (i.e. only display choppy animation on first load, not subsequent ones
//              if (daysAgo == 1 && !self.alreadyInitializedSection[AnalyticsDataEnum.VIEW_BREAKDOWN.rawValue]){
//                self.viewBreakdownList = newViewBreakdownList
//                self.analyticsTableView.reloadData()
//                self.alreadyInitializedSection[AnalyticsDataEnum.VIEW_BREAKDOWN.rawValue] = true
//              } else if (daysAgo == 1 && self.alreadyInitializedSection[AnalyticsDataEnum.VIEW_BREAKDOWN.rawValue]) {
//                self.viewBreakdownList = newViewBreakdownList
//                self.analyticsTableView.reloadData()
//              } else if !self.alreadyInitializedSection[AnalyticsDataEnum.VIEW_BREAKDOWN.rawValue] {
//                self.viewBreakdownList = newViewBreakdownList
//                self.analyticsTableView.reloadData()
//              }
              
              self.viewBreakdownList = newViewBreakdownList
              
              if self.analyticsTableView != nil {
                self.analyticsTableView.reloadData()
              }
            
            })
          }
//          else if resultTask.error != nil || resultTask.result == nil {
//            print("ERROR result task for getUserSinglePayViewsForDay DAYS_GO = ", daysAgo, " and error is: ", resultTask.result!)
//
//          }
          
          self.isGeneratingViewBreakdownAnalytics = false
          return nil
        }
      }
    }

    
      //self.socialProviderToEngagementCountList = Array<Array<String>>()
      var newSocialProviderToEngagementCountList = Array<Array<String>>()
    
      if !isGeneratingEngagementAnalytics {
        isGeneratingEngagementAnalytics = true
        
        var runningRequests = 0
        for platform in userSocialPlatforms {
          runningRequests = runningRequests + 1
          // Get engagement info
          parameters = ["action":"getUserSingleEngagements", "target": currentUserName, "social_platform": platform]
          lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil
            {
              print("Result task for getUserSingleEngagements is: ", resultTask.result!)
              
              let number = resultTask.result as? Int
              var tuple = Array<String>()
              tuple.append(platform)
              tuple.append(String(number!))
              newSocialProviderToEngagementCountList.append(tuple)
              newSocialProviderToEngagementCountList.sort(by: { (obj1, obj2) -> Bool in
                return Int(obj1[1]) > Int(obj2[1])
              })
              
              print ("SORTED ARRAY socialProviderToEngagementCountList IS: ", newSocialProviderToEngagementCountList)
              
              runningRequests = runningRequests - 1
              
              // Load data differently for first and subsequent requests
              if runningRequests == 0 && !self.alreadyInitializedSection[AnalyticsDataEnum.engagement_BREAKDOWN.rawValue] {
                DispatchQueue.main.async(execute: {
                  self.socialProviderToEngagementCountList = newSocialProviderToEngagementCountList
                  
                  if self.analyticsTableView != nil {
                    self.analyticsTableView.reloadData()
                  }
                  self.alreadyInitializedSection[AnalyticsDataEnum.engagement_BREAKDOWN.rawValue] = true
                })
              } else if runningRequests == 0 && self.alreadyInitializedSection[AnalyticsDataEnum.engagement_BREAKDOWN.rawValue] {
                DispatchQueue.main.async(execute: {
                  self.socialProviderToEngagementCountList = newSocialProviderToEngagementCountList
                  if self.analyticsTableView != nil {
                    self.analyticsTableView.reloadData()
                  }
                })
              }
              else if !self.alreadyInitializedSection[AnalyticsDataEnum.engagement_BREAKDOWN.rawValue]{
                DispatchQueue.main.async(execute: {
                  self.socialProviderToEngagementCountList = newSocialProviderToEngagementCountList
                  if self.analyticsTableView != nil {
                    self.analyticsTableView.reloadData()
                  }
                })
              }
            }
    
            self.isGeneratingEngagementAnalytics = false
            return nil
          }
        }
      }

    // Get location info
    parameters = ["action":"getUserPageViewsLocations", "target": currentUserName, "max_results": 15]
    
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getUserPageViewsLocations is: ", resultTask.result!)
        
        self.locationToCountList = resultTask.result as! NSArray
        
        DispatchQueue.main.async(execute: {
          if self.analyticsTableView != nil {
            self.analyticsTableView.reloadData()
          }
        })
      }
      
      return nil
    }
    
    
  }
  
  func extractDataArray(_ listOfLists: Array<Array<Int>>) -> Array<Int>
  {
    var firstElementsArray = Array<Int>()
    
    for tuple in listOfLists {
      firstElementsArray.append(tuple[1])
    }
    
    return firstElementsArray
  }
  
  
  func allZeroDisplayValues(_ listOfLists: Array<Array<Int>>) -> Bool
  {
    var sum = 0
    for tuple in listOfLists {
      sum += tuple[1]
    }
    
    if sum == 0 {
      return true
    } else {
      return false
    }
  }

}
