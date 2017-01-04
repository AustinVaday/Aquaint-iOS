//
//  MenuButtonTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/27/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSDynamoDB

class MenuButtonTableViewCell: UITableViewCell {
  enum ToggleType: Int {
    case PRIVATE_PROFILE
  }

  @IBOutlet weak var menuButtonLabel: UITextField!
  @IBOutlet weak var menuToggleSwitch: UISwitch!
  var toggleType : ToggleType!
  
  @IBAction func toggleButtonToggled(sender: AnyObject) {
    if toggleType == ToggleType.PRIVATE_PROFILE {
      print ("toggle for private profile initiated")
      
      // Upload user DATA to DynamoDB
      let dynamoDBUser = UserPrivacyMinimalObjectModel()
      
      dynamoDBUser.username = getCurrentCachedUser()
      
      if menuToggleSwitch.on
      {
        // Privacy settings initiated
        dynamoDBUser.isprivate = 1
        setCurrentCachedPrivacyStatus("private")

      } else {
        // Default public settings
        dynamoDBUser.isprivate = 0
        setCurrentCachedPrivacyStatus("public")

      }
      
      let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
      dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
        
        if (resultTask.error != nil)
        {
          print ("DYNAMODB UPDATE PROFILE ERROR: ", resultTask.error)
        }
        
        if (resultTask.result == nil)
        {
          print ("DYNAMODB UPDATE PROFILE result is nil....: ")
          
        }
          // If successful save
        else if (resultTask.error == nil)
        {
          print ("DYNAMODB UPDATE PROFILE SUCCESS: ", resultTask.result)
        }
      
        return nil
      })

      
      
    }
  }
}
