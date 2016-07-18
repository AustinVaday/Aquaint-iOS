//
//  BackendAPI.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/3/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider
import AWSS3
import AWSDynamoDB

// Set up AWS service config (default log-in/sign-up)
func getAWSCognitoIdentityUserPool() -> AWSCognitoIdentityUserPool
{
    let serviceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: nil)
    let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "41v7gese46ar214saeurloufe7", clientSecret: "1lr1abieg6g8fpq06hngo9edqg4qtf63n3cql1rgsvomc11jvs9b", poolId: "us-east-1_yyImSiaeD")
    AWSCognitoIdentityUserPool.registerCognitoIdentityUserPoolWithConfiguration(serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
    return AWSCognitoIdentityUserPool(forKey: "UserPool")
}

func setCachedUserFromAWS(userName: String!)
{
    /*******************************************
    * username, accounts, full name from DYNAMODB
    ********************************************/
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    
    dynamoDBObjectMapper.load(User.self, hashKey: userName, rangeKey: nil).continueWithBlock { (resultTask) -> AnyObject? in
        if (resultTask.error != nil)
        {
            print("Error caching user from dynamoDB: ", resultTask.error)
        }
        else if (resultTask.exception != nil)
        {
            print("Exception caching user from dynamoDB: ", resultTask.exception)
        }
        else if (resultTask.result == nil)
        {
            print("Error caching user from dynamoDB: nil result")
        }
        else
        {
            let user = resultTask.result as! User
            
            setCurrentCachedUserName(userName)
            setCurrentCachedFullName(user.realname)
            setCurrentCachedUserProfiles(user.accounts as! NSMutableDictionary)
        }
        
        return nil
    }
    
    /*******************************************
     * user image from S3
     ********************************************/
    // AWS TRANSFER REQUEST
    let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString("temp")
    let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
    let downloadRequest = AWSS3TransferManagerDownloadRequest()
    downloadRequest.bucket = "aquaint-userfiles-mobilehub-146546989"
    downloadRequest.key = "public/" + userName
    downloadRequest.downloadingFileURL = downloadingFileURL
    
    let transferManager = AWSS3TransferManager.defaultS3TransferManager()
    
    transferManager.download(downloadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (resultTask) -> AnyObject? in
        
        // if sucessful file transfer
        if resultTask.error == nil && resultTask.exception == nil && resultTask.result != nil
        {
            print("CACHE: SUCCESS FILE DOWNLOAD")
            
            let data = NSData(contentsOfURL: downloadingFileURL)
            setCurrentCachedUserImage(UIImage(data: data!)!)
            
        }
        else // If fail file transfer
        {
            
            print("CACHE: ERROR FILE DOWNLOAD: ", resultTask.error)
        }
        
        return nil
        
    })

    
}


func getUserS3Image(userName: String!, completion: (result: UIImage?, error: NSError?)->())
{
    
    /*******************************************
     * user image from S3
     ********************************************/
    // AWS TRANSFER REQUEST
    let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString("temp")
    let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
    let downloadRequest = AWSS3TransferManagerDownloadRequest()
    downloadRequest.bucket = "aquaint-userfiles-mobilehub-146546989"
    downloadRequest.key = "public/" + userName
    downloadRequest.downloadingFileURL = downloadingFileURL
    
    let transferManager = AWSS3TransferManager.defaultS3TransferManager()
    
    transferManager.download(downloadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (resultTask) -> AnyObject? in
        
        // if sucessful file transfer
        if resultTask.error == nil && resultTask.exception == nil && resultTask.result != nil
        {
            print("fetch s3 user image: SUCCESS FILE DOWNLOAD")
            
            let data = NSData(contentsOfURL: downloadingFileURL)
            let image = UIImage(data: data!)!
            
            completion(result: image, error: nil)
            
        }
        else // If fail file transfer
        {
            
            print("fetch s3 user image: ERROR FILE DOWNLOAD: ", resultTask.error)
            
            completion(result: nil, error: resultTask.error)
        }
        
        return nil
        
    })

    
    
    
    
}

