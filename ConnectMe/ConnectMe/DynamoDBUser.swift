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


// The below class is the acctual newsfeed that will be displayed
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
        
        print("SUCCESS SORT KEY DETECTION")
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
        // Initialize if not already done so
        if newsfeedList == nil
        {
            newsfeedList = NSMutableArray()
        }
        
        let numParameters = 3
        let maxSize = 25 // Denotes how much data to store for one user's newsfeed
//        let listOfParameters = ["username", "event", "other", "timestamp"]
        
        // Reject if attempts to add dictionary with insufficient data
        if object.count != numParameters
        {
            print("Not adding newsfeed object because bad parameters!")
            return
        }
        
        //TODO: Reject if invalid keys
//        if listOfParameters != object.allKeys
//        {
//            
//        }

        // If we have space, add newsfeed object to beginning list
        if newsfeedList.count < maxSize
        {
            // Add to front of list
            newsfeedList.insertObject(object, atIndex: 0)
        }
        else
        {
            // If we do not have space, we need to get rid of one object at the end of the list
            newsfeedList.removeLastObject()
            
            // Then add the new object to the front
            newsfeedList.insertObject(object, atIndex: 0)
        }
    }
    
}
