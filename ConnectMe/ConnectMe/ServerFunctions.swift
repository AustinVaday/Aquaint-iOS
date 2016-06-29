////
////  ServerFunctions.swift
////  Aquaint
////
////  Created by Austin Vaday on 3/27/16.
////  Copyright © 2016 ConnectMe. All rights reserved.
////
//
//import Foundation
//import Firebase
//
//func getRecentConnectionsList() -> Array<Connection>
//{
//    
//    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
//    
//    var currentUserName : String!
//    
//    var firebaseUsersRef: FIRDatabaseReference!
//    var firebaseLinkedAccountsRef: FIRDatabaseReference!
//    var firebaseConnectionsRef: FIRDatabaseReference!
//    var connectionList : Array<Connection>!
//    
//    
//    // Fetch the user's username
//    currentUserName = getCurrentUser()
//    
//    // Firebase root, our data is stored here
//    firebaseUsersRef = firebaseRootRef.child("Users/")
//    firebaseLinkedAccountsRef = firebaseRootRef.child("LinkedSocialMediaAccounts/")
//    firebaseConnectionsRef = firebaseRootRef.child("Connections/" + currentUserName)
//    
//    connectionList = Array<Connection>()
//    
//    // Load all connections and respective information from servers
//    firebaseConnectionsRef.queryOrderedByValue().observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) -> Void in
//        
//        
//        // Get your connection's user name
//        let connectionUserName = snapshot.key
//        let connection = Connection()
//        
//        // Store server data into our local "cached" object -- connection
//        connection.userName = snapshot.key
//        connection.timestampGMT = snapshot.value as! Int
//        
//        print("firebaseConnectionsRef snapshot value is: ", snapshot.value)
//        print("conn username is:", connectionUserName)
//        print("##1")
//        
//        // Store the user's Image
//        firebaseUsersRef.child(connectionUserName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//            
//            //                connection.userImage = snapshot.value as! String
//            connection.userImage = snapshot.childSnapshotForPath("/userImage").value as! String
//            connection.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
//            
//            print("##2")
//            
//            //                self.recentConnTableView.reloadData()
//            
//        })
//        
//        // Store the user's social media accounts
//        firebaseLinkedAccountsRef.child(connectionUserName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//            
//            print("LET'S DO THIS FOR: ", connectionUserName)
//            // Store dictionary of all key-val pairs..
//            // I.e.: (facebook, [user's facebook username])
//            //       (twitter,  [user's twitter username]) ... etc
//            connection.socialMediaUserNames = snapshot.value as! NSDictionary
//            
//            print("firebasedLinkedAccountsRef snapshot value is: ", snapshot.value)
//            
//            print("##3")
//            
//            
//            // Add connection to connection list -- sorted in ascending order by time!
//            // Front of list == largest time == most recent add
//            print("INSERTING..", connection.userName)
//            
//            connectionList.append(connection)
//           
//            
//        })
//        
//        print("##4")
//        
//    })
//    
//
//        return connectionList
//    
//    
//}