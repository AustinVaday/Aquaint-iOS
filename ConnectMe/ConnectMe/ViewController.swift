//
//  ViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 11/21/15.
//  Copyright © 2015 Aquaint. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import Parse

import FBSDKCoreKit
import FBSDKLoginKit
import AWSLambda
import AWSDynamoDB
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
// [Swift 3 Migration]
import AWSFacebookSignIn

class ViewController: UIViewController {

  override func viewDidLoad() {
      super.viewDidLoad()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  @IBAction func loginWithFacebookButtonClicked(_ sender: AnyObject) {
//    let login = FBSDKLoginManager.init()
//    login.logOut()
//    
//    // Open in app instead of web browser!
//    login.loginBehavior = FBSDKLoginBehavior.Native
    
    //    // Request basic profile permissions just to get user ID
//    login.logInWithReadPermissions(["public_profile", "user_friends", "email"], fromViewController: self) { (result, error) in

    // [Swift 3 Migration] TODO
    /*
    AWSIdentityManager.default().loginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance()) { (result, error) in

      // If no error, store facebook user ID
      if (error == nil && result != nil) {
        if (FBSDKAccessToken.current() != nil) {
          print("Current access user id: ", FBSDKAccessToken.current().userID)
          print("RESULTOO: ", result)

//          let fbUID = FBSDKAccessToken.currentAccessToken().userID
          
//          let token = FBSDKAccessToken.currentAccessToken().tokenString
         
          let provider = FacebookProvider()
          
          credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AWSRegionType.USEast1,
            identityPoolId: "us-east-1:ca5605a3-8ba9-4e60-a0ca-eae561e7c74e",
            identityProviderManager: provider)
          
          let configuration = AWSServiceConfiguration(
            region: AWSRegionType.USEast1,
            credentialsProvider: credentialsProvider
          )
          
          AWSServiceManager.default().defaultServiceConfiguration = configuration
          
          credentialsProvider!.getIdentityId().continueWith(block: { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil {
              let id = resultTask.result
              print("Cred Prov. ID is: \(id)")

            }
            else {
              print ("Error: \(error)")
            }
            return nil
          })
          
          userPool.getUser().getDetails().continueWith(block: { (resultTask) -> AnyObject? in
            if resultTask.error == nil && resultTask.result != nil {
              print ("lala:", resultTask.result)
            }
            return nil
          })
          

          
          delay(2) {
          // Get user-specific data including name, email, and ID.
          let request = FBSDKGraphRequest(graphPath: "/me?locale=en_US&fields=name,email", parameters: nil)
          request?.start { (connection, result, error) in
            if error == nil {
              print("Result is FB!!: ", result)
              let resultMap = result as! Dictionary<String, String>

              let userFullName = resultMap["name"]
              let userEmail = resultMap["email"]
              let fbUID = resultMap["id"]

              
              // Check our databases to see if we have a user with the same fbUID
              // If we have multiple users ->
              // If we don't have a user -> create one
              let dynamoDB = AWSDynamoDB.default()
              let scanInput = AWSDynamoDBScanInput()
              scanInput?.tableName = "aquaint-users"
              scanInput?.limit = 100
              scanInput?.exclusiveStartKey = nil
              
              let UIDValue = AWSDynamoDBAttributeValue()
              UIDValue?.s = fbUID
              
              scanInput?.expressionAttributeValues = [":val" : UIDValue!]
              scanInput?.filterExpression = "fbuid = :val"
              
              dynamoDB.scan(scanInput!).continueWith { (resultTask) -> AnyObject? in
                if resultTask.result != nil && resultTask.error == nil
                {
                  print("DB QUERY SUCCESS:", resultTask.result)
                  let results = resultTask.result as! AWSDynamoDBScanOutput
                  
                  if results.items!.count > 1 {
                    print("FB login attempt where more than 1 user has same FB ID")
                    DispatchQueue.main.async(execute: {
                      showAlert("Sorry", message: "Could not log you in via facebook at this time.", buttonTitle: "Try again", sender: self)
                    })
                    
                    return nil
                  }
                  
                  for result in results.items! {
                    print("RESULT IS: ", result)
                    
                    let username = (result["username"]?.s)! as String
                    
                    setCurrentCachedUserName(username)
                    setCachedUserFromAWS(username)
                    
                    DispatchQueue.main.async(execute: {
                      self.performSegue(withIdentifier: "toMainContainerViewController", sender: nil)
                    })
                  }
                }
                else
                {
                  print("DB QUERY FAILURE:", resultTask.error)
                }
                return nil
              }

              
              
            } else {
              print("Error getting **FB friends", error)
            }
          }
          
          // Attempt to find user
          
          
//          let currentUserName = getCurrentCachedUser()
//          uploadUserFBUIDToDynamo(currentUserName, fbUID: fbUID)
        }
      } else if (result == nil && error != nil) {
        print ("ERROR IS: ", error)
      } else {
        print("FAIL LOG IN")
      }
      }
    }
    */
  }
  
  
//    AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile"])

    
//    AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance()) { (result, error) in
//      
//    
//    }
  
  }




