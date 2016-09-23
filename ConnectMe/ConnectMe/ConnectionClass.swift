//
//  UserNames.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/24/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import Foundation
import UIKit
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


class Connection : Equatable
{
    var userName             = String()
    var userImage            = UIImage()
    var userFullName         = String()
    var timestampGMT         = Int()
    var socialMediaUserNames = NSDictionary()
    var keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
    
    // Computes time difference to display from GMT (now) to timestampGMT
    // Used in recentconnections tableview to indicate how long ago you connected with your friends
    func computeTimeDiff() -> String
    {
      return computeTimeDiffFromNow(timestampGMT)
    }
}

// Note: This is a very, very soft check.
// Intended to check whether two connections have 
// the same username
func ==(lhs: Connection, rhs: Connection) -> Bool
{
    if lhs.userName == rhs.userName &&
        lhs.timestampGMT == rhs.timestampGMT
    {
        return true
    }
    else
    {
        return false
    }
}



