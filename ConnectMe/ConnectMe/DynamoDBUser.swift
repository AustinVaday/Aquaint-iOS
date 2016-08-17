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


class NewsfeedObject
{
    var username : String!
    var event : String!
    var otherUser : String!
    var timestamp : String!
}


class NewsfeedObjectModel : AWSDynamoDBObjectModel
{

    var newsfeedList : Array<NewsfeedObject>!
    let maxSize = 10 // Denotes how much data to store for one user's newsfeed
    
    override init()
    {
        super.init()
        
        newsfeedList = Array<NewsfeedObject>()
        
    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        
        return "aquaint-newsfeed"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "username"
    }
    
    func addNewsfeedObject(object: NewsfeedObject)
    {
        
    }
    
}
