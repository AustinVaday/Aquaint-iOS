//
//  UserNames.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/24/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import Foundation
import Firebase

class UserNames
{
    var facebook    : String!
    var twitter     : String!
    var instagram   : String!
    var snapchat    : String!
    var youtube     : String!
    var linkedin    : String!
}


class Connection
{
    var userName             = String()
    var userImage            = String()
    var timestampGMT         = Int()
    var socialMediaUserNames = NSDictionary()

    
    
    func computeTimeDiff() -> String
    {
        // Computes time difference to display from GMT (now) to GMTtimestamp
        
//        // Get time diff in seconds
//        var timeDiff = FirebaseServerValue.timestamp() - timestampGMT as! Int
//        
//        // Convert time diff to milliseconds
//        timeDiff = timeDiff * 1000
        
        
//        var formatedDate = NSDate(timeIntervalSinceNow: timestampGMT * 1000)
        
        return "TIME"
        
    }

}



