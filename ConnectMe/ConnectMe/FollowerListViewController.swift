//
//  FollowerListViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/1/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda
import FRHyperLabel

protocol FollowerListSetUserAndActionDelegate {
  func dataForUser() -> String
  func lambdaActionForUser() -> String
}

class FollowerListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var userTableView: UITableView!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  var dataDelegate : FollowerListSetUserAndActionDelegate?
  
  var currentUserName : String!
  var myUserName : String!
  var lambdaAction : String!
  var socialMediaImageDictionary: Dictionary<String, UIImage>!
  var refreshControl : CustomRefreshControl!
  var connectionList : Array<Connection>!
  var defaultImage : UIImage!
  var isNewDataLoading = false
  var currentBegin = 0
  var currentEnd = 10
  let offset = 10
  
  var status : String!
  override func viewDidLoad() {
    
    // Get user to display in table
    currentUserName = dataDelegate?.dataForUser()
    
    myUserName = getCurrentCachedUser()
    
    // Get lambda action to perform (getFollowers) or (getFollowees)
    lambdaAction = dataDelegate?.lambdaActionForUser()
    
//    if currentUserName == nil {
//    }
//    
//    if lambdaAction == nil {
//    }
    
    connectionList = Array<Connection>()
    
    defaultImage = UIImage(imageLiteralResourceName: "Person Icon Black")
    
    
    // Fill the dictionary of all social media names (key) with an image (val).
    // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
    socialMediaImageDictionary = getAllPossibleSocialMediaImages()
    
    
    // Set up refresh control for when user drags for a refresh.
    refreshControl = CustomRefreshControl()
    
    // When user pulls, this function will be called
    refreshControl.addTarget(self, action: #selector(RecentConnections.refreshTable(_:)), for: UIControlEvents.valueChanged)
    userTableView.addSubview(refreshControl)
    
    // Call all lambda functions and AWS-needed stuff
    generateData(true, start: currentBegin, end: currentEnd)
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    //        generateData(false)
    awsMobileAnalyticsRecordPageVisitEventTrigger("FollowerListViewController", forKey: "page_name")
  }
  
  // Function that is called when user drags/pulls table with intention of refreshing it
  func refreshTable(_ sender:AnyObject)
  {
    self.refreshControl.beginRefreshing()
    
    // Regenerate data
    currentBegin = 0
    currentEnd = offset
    isNewDataLoading = false
    generateData(false, start: currentBegin, end: currentEnd)
    
    // Need to end refreshing
    delay(1)
    {
      self.refreshControl.endRefreshing()
    }
  }
  
  
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == self.userTableView
    {
      let location = scrollView.contentOffset.y + scrollView.frame.size.height
      
      if location >= scrollView.contentSize.height
      {
        // Load data only if more data is not loading.
        if !isNewDataLoading
        {
          isNewDataLoading = true
          addTableViewFooterSpinner()
          
          currentBegin = currentBegin + offset
          currentEnd = currentEnd + offset
          generateData(false, start: currentBegin, end: currentEnd)
        }
      }
      
    }
  }
  
  func changeUser(_ newUserName: String) {
    self.currentUserName = newUserName
    
    // Regenerate data
    currentBegin = 0
    currentEnd = offset
    isNewDataLoading = false
    generateData(false, start: currentBegin, end: currentEnd)
  }
  
  func changeLambdaAction(_ newLambdaAction: String) {
    self.lambdaAction = newLambdaAction
    
    // Regenerate data
    currentBegin = 0
    currentEnd = offset
    isNewDataLoading = false
    generateData(false, start: currentBegin, end: currentEnd)
  }
  
  
  
  // TABLE VIEW
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    // TODO: If more than one user,
    // Display up to 30 users immediately
    // Display 20 more if user keeps sliding down
    
    return connectionList.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    //        print("DDD*********************************************************")
    //        print(" Size of connectionList is: ", connectionList.count)
    //        print(" Number of rowsi n table is: ", tableView.numberOfRowsInSection(0))
    //        print(" Indexpath is: ", indexPath.row)
    //        print("*********************************************************")
    
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsTableViewCell
    
    if connectionList.count == 0
    {
      return cell
    }
    
    // Ensure that internal cellImage is circular
    cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
    
    let connectedUser = connectionList[indexPath.row]
    let handler = {
      (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
      showPopupForUser(connectedUser.userName, me: self.myUserName)
    }
    
    cell.cellName.clearActionDictionary()
    cell.cellName.text = connectedUser.userFullName
    cell.cellName.setLinkForSubstring(connectedUser.userFullName, withLinkHandler: handler)
    cell.cellUserName.text = connectedUser.userName
    cell.cellImage.image = connectedUser.userImage
    cell.cellTimeConnected.text = connectedUser.computeTimeDiff()
    
    return cell
    
  }
  
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if !tableView.isDragging && !tableView.isTracking
    {
      let connectedUser = connectionList[indexPath.row]
      showPopupForUser(connectedUser.userName, me: self.myUserName)
      
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  fileprivate func generateData(_ showSpinner: Bool, start: Int, end: Int)
  {
    // If we don't store our data into a temporary object -- we'll be modifying the table data source while it may still
    // be used in the tableView methods! This prevents a crash.
    var newConnectionList = Array<Connection>()
    
    // Only show the middle spinner if user did not refresh table or if init (or else there would be two spinners!)
    if showSpinner && start == 0
    {
      spinner.isHidden = false
      spinner.startAnimating()
    }
    
    if start != 0
    {
      addTableViewFooterSpinner()
    }
    
    // Get array of connections from Lambda -- RDS
    let lambdaInvoker = AWSLambdaInvoker.default()
    let parameters = ["action": lambdaAction, "target": currentUserName, "start": start, "end": end] as [String : Any]
    
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
      if resultTask.error != nil
      {
        print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
      }
      else if resultTask.result != nil
      {
        
        print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
        
        let connectionsFetchedList = resultTask.result! as! NSArray
        
        print("Connections FETCHED LIST IS: ", connectionsFetchedList)
        
        // If empty list, then no users to display (refresh table)
        // Update UI on main thread
        if connectionsFetchedList.count == 0 && start == 0
        {
          DispatchQueue.main.async(execute: {
            self.spinner.isHidden = true
            self.spinner.stopAnimating()
            self.connectionList = Array<Connection>()
            self.userTableView.reloadData()
            print("RELOADED 0 COUNT DATA")
          })
          
          return nil
        }
        else if connectionsFetchedList.count == 0 && start != 0
        {
          DispatchQueue.main.async(execute: {
            self.removeTableViewFooterSpinner()
            
          })
          
        }
        
        // Propogate local data structure -- helps us prevent needing to
        // fetch more data and prevents race conditions later too
        for userData in connectionsFetchedList
        {
          let con = Connection()
          con.userName = (userData as AnyObject).object(at: 0) as! String
          con.timestampGMT = (userData as AnyObject).object(at: 1) as! Int
          
          newConnectionList.append(con)
        }
        
        var runningRequests = 0
        // If lists are not equal, we need to fetch data from the servers
        // and re-propagate the list
        for userConnection in newConnectionList
        {
          runningRequests = runningRequests + 1
          getUserDynamoData(userConnection.userName, completion: { (result, error) in
            if error == nil && result != nil
            {
              let resultUser = result! as User
              userConnection.userFullName = resultUser.realname
              
              if resultUser.accounts != nil
              {
                userConnection.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(resultUser.accounts)
              }
              else
              {
                userConnection.keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
              }
              
              getUserS3Image(userConnection.userName, extraPath: nil, completion: { (result, error) in
                if error == nil && result != nil
                {
                  userConnection.userImage = result! as UIImage
                }
                else
                {
                  userConnection.userImage = self.defaultImage
                }
                
                
                runningRequests = runningRequests - 1
                
                if runningRequests == 0
                {
                  // Update UI when no more running requests! (last async call finished)
                  // Update UI on main thread
                  DispatchQueue.main.async(execute: {
                    
                    // If initial fetch, just store entire array
                    if start == 0
                    {
                      self.connectionList = newConnectionList
                      self.spinner.isHidden = true
                      self.spinner.stopAnimating()
                    }
                    else
                    {
                      self.removeTableViewFooterSpinner()
                      self.isNewDataLoading = false
                      self.connectionList.append(contentsOf: newConnectionList)
                    }
                    
                    self.userTableView.reloadData()
                    self.userTableView.layoutIfNeeded()
                    
                  })
                  
                }
              })
            }
          })
        }
        
      }
      else
      {
        print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
        
      }
      
      return nil
      
    }
    
  }
  
  fileprivate func addTableViewFooterSpinner() {
    let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    footerSpinner.startAnimating()
    footerSpinner.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
    self.userTableView.tableFooterView = footerSpinner
  }
  
  fileprivate func removeTableViewFooterSpinner() {
    self.userTableView.tableFooterView = nil
  }
  
  
  // EXPECTED TO BE IN ORDER.
  fileprivate func areListsEqual(_ array1: Array<Connection>, array2: Array<Connection>) -> Bool
  {
    if array1.count != array2.count
    {
      return false
    }
    
    let size = array1.count
    for i in 0...size - 1
    {
      if array1[i] != array2[i]
      {
        return false
      }
    }
    return true
  }
  
  
}



