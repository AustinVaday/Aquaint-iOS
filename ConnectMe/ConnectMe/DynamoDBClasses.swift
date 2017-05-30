//
//  DynamoDBUser.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/4/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSDynamoDB

class User : AWSDynamoDBObjectModel
{
    
    var userId : String!
    var username : String!
    var realname : String!
    var accounts : NSMutableDictionary!
    
    
    class func dynamoDBTableName() -> String {
        
        return "aquaint-users"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "username"
    }
    
}

// Derive class to adhere to new privacy model
class UserPrivacyObjectModel : User {
  var isprivate : NSNumber!
  var isverified : NSNumber!
}

// AWS DynamoDB minimal object model to just upload privacy settings
class UserPrivacyMinimalObjectModel : AWSDynamoDBObjectModel {
  var username: String!
  var isprivate: NSNumber!
  
  class func dynamoDBTableName() -> String {
    return "aquaint-users"
  }
  
  class func hashKeyAttribute() -> String {
    return "username"
  }
  
}

// AWS DynamoDB minimal object model to just upload subscription settings
class UserPromoCodeMinimalObjectModel : AWSDynamoDBObjectModel {
  var username: String!
  var promouser: NSNumber!
  
  class func dynamoDBTableName() -> String {
    return "aquaint-users"
  }
  
  class func hashKeyAttribute() -> String {
    return "username"
  }
  
}
// AWS DynamoDB minimal object model to just get verified status (i.e. influencer)
class UserVerifiedMinimalObjectModel : AWSDynamoDBObjectModel {
  var username: String!
  var isverified: NSNumber!
  
  class func dynamoDBTableName() -> String {
    return "aquaint-users"
  }
  
  class func hashKeyAttribute() -> String {
    return "username"
  }
  
}
// AWS DynamoDB database to store FB UID of each user (for find friends using FB feature)
class UserFBObjectModel : AWSDynamoDBObjectModel
{
  var username : String!
  var fbuid : String!
  
  class func dynamoDBTableName() -> String {
    return "aquaint-users"
  }
  
  class func hashKeyAttribute() -> String {
    return "username"
  }
  
}

// AWS DynamoDB database to store device ID of each user
class Device : AWSDynamoDBObjectModel {
  var username: String!
  var deviceidlist: Array<String>!
  
  class func dynamoDBTableName() -> String {
    return "aquaint-devices"
  }
  
  class func hashKeyAttribute() -> String {
    return "username"
  }
}

// AWS DynamoDB database to store leaderboard users in the search tab, managed by Backend script
class Leaderboard: AWSDynamoDBObjectModel {
  var metric: String!
  var lastupdated: Int!
  var usernames = [String]()
  var attributes = [Int]()
  
  class func dynamoDBTableName() -> String {
    return "aquaint-leaderboards"
  }
  
  class func hashKeyAttribute() -> String {
    return "metric"
  }
}

// The below class is the actual newsfeed that will be displayed
class NewsfeedResultObjectModel : AWSDynamoDBObjectModel
{
    
    var data : NSMutableArray!
    var username : String!
    var seq : Int!
    
    class func dynamoDBTableName() -> String {
        
        return "aquaint-newsfeed"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "username"
    }
    
    class func rangeKeyAttribute() -> String {
        
        return "seq"
    }
    
}

// The below class is used to submit user events
class NewsfeedEventListObjectModel : AWSDynamoDBObjectModel
{

    var newsfeedList : NSMutableArray! // Really: Array<NSMutableDictionary>!
    var username : String!
    
    class func dynamoDBTableName() -> String {
        
        return "aquaint-user-eventlist"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "username"
    }
    
    func addNewsfeedObject(object: NSMutableDictionary)
    {
        print("adding newsfeed object: ", object)
        // Initialize if not already done so
        if newsfeedList == nil
        {
            newsfeedList = NSMutableArray()
        }
        
        let maxSize = 30 // Denotes how much data to store for one user's newsfeed


        // If we have space, add newsfeed object to end of list
        if newsfeedList.count < maxSize
        {
            // Add to end of list
            newsfeedList.addObject(object)
        }
        else
        {
            // If we do not have space, we need to get rid of one object at the beginning of the list
            newsfeedList.removeObjectAtIndex(0)
            
            // Then add the new object to the end
            newsfeedList.addObject(object)
        }
    }
    
}
