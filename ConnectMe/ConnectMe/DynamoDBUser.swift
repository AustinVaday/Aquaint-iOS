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
//    var timestamp : NSNumber!
    var accounts : NSDictionary!
    
    
    class func dynamoDBTableName() -> String {
        
        return "aquaint-users"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "username"
    }
    
}
