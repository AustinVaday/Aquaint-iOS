//
//  UserNames.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/24/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import Foundation
//import Firebase

//class UserNames
//{
//    var facebook    : String!
//    var twitter     : String!
//    var instagram   : String!
//    var snapchat    : String!
//    var youtube     : String!
//    var linkedin    : String!
//}


class Connection
{
    var userName             = String()
    var userImage            = UIImage()
    var userFullName         = String()
    var timestampGMT         = Int()
    var socialMediaUserNames = NSDictionary()

    
    // Computes time difference to display from GMT (now) to timestampGMT
    // Used in recentconnections tableview to indicate how long ago you connected with your friends
    func computeTimeDiff() -> String
    {
        
        // Don't know how to cast this to an int..
//        let currentTime = FirebaseServerValue.timestamp()
        
        
        // 55234
        
        let currentTime = getTimestampAsInt()
        
        // Get time diff in seconds
        print ("currentTime is:", currentTime)
        print ("timestampGMT is:", timestampGMT)
        let timeDiffSec = (currentTime - timestampGMT)

        // If we're in seconds, return seconds
        if (timeDiffSec < 60)
        {
            return String(Int(timeDiffSec)) + " sec"
        }
        // If it's better to use minutes
        else if (timeDiffSec < (60 * 60))
        {
            let calcTime = Int(timeDiffSec / 60)
            return String(calcTime) + " min"
        }
        // If it's better to use hours
        else if (timeDiffSec < (60 * 60 * 24))
        {
            let calcTime = Int(timeDiffSec / 60 / 60)
            return String(calcTime) + " h"
        }
        // If it's better to use days
        else if (timeDiffSec < (60 * 60 * 24 * 30))
        {
            let calcTime = Int(timeDiffSec / 60 / 60 / 24 )
            return String(calcTime) + " d"
        }
        // If it's better to use months
        else if (timeDiffSec < (60 * 60 * 24 * 30 * 12))
        {
            let calcTime = Int(timeDiffSec / 60 / 60 / 24 / 30)
            return String(calcTime) + " mo"
        }
        else
        {
            let calcTime = Int(timeDiffSec / 60 / 60 / 24 / 365)
            return String(calcTime) + " y"
        }
        
    }

}



