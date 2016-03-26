//
//  UserNames.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/24/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import Foundation
import Firebase

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
    var userImage            = String()
    var userFullName         = String()
    var timestampGMT         = Int()
    var socialMediaUserNames = NSDictionary()

    
    // Computes time difference to display from GMT (now) to timestampGMT
    func computeTimeDiff() -> String
    {
        
        // Don't know how to cast this to an int..
//        let currentTime = FirebaseServerValue.timestamp()
        
        
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
            let calcTime = Int(timeDiffSec / 60 / 24)
            return String(calcTime) + " h"
        }
        // If it's better to use weeks
        else if (timeDiffSec < (60 * 60 * 24 * 7))
        {
            let calcTime = Int(timeDiffSec / 60 / 24 / 7)
            return String(calcTime) + " w"
        }
        // If it's better to use months
        else if (timeDiffSec < (60 * 60 * 24 * 7 * 4))
        {
            let calcTime = Int(timeDiffSec / 60 / 24 / 7 / 4)
            return String(calcTime) + " mo"
        }
        else
        {
            let calcTime = Int(timeDiffSec / 60 / 24 / 365)
            return String(calcTime) + " y"
        }
        
    }

}



