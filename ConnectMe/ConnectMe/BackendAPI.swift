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
            setCurrentCachedUserProfiles(user.accounts as NSMutableDictionary)
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
    
    // Get UserPool Data too (email, phone info)
    getUserPoolData(userName) { (result, error) in
        
        if (error != nil)
        {
            print("CACHE: COULD NOT GET USER POOLS")

        }
        
        if (result != nil)
        {
            let userPoolData = result
            setCurrentCachedUserEmail(userPoolData!.email!)
            setCurrentCachedUserPhone(userPoolData!.phoneNumber!)
        
        }
        
    }


    
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


struct UserPoolData
{
    var emailVerified : Bool?
    var phoneNumberVerified : Bool?
    var email : String?
    var phoneNumber : String?
    
}

func getUserPoolData(userName: String!, completion: (result: UserPoolData?, error: NSError?)->())
{
    var userData = UserPoolData()
    // Get AWS UserPool
    let pool:AWSCognitoIdentityUserPool = getAWSCognitoIdentityUserPool()
    
    //Fetch UserPool Data
    pool.getUser(userName).getDetails().continueWithBlock { (resultTask) -> AnyObject? in
        
        if resultTask.error != nil
        {
            print("User Pool fetch data in Settings Error:", resultTask.error)
            completion(result: nil, error: resultTask.error)
        }
        else if resultTask.result == nil
        {
            print("User Pool fetch data in Settings IS NIL...")
            completion(result: nil, error: nil)

        }
        else
        {
            print("User Pool fetch data in Settings SUCCESS:", resultTask.result)
            
            let response:AWSCognitoIdentityUserGetDetailsResponse = resultTask.result as! AWSCognitoIdentityUserGetDetailsResponse
            
            print("USAH ATTRIBUTEZ", response.userAttributes)
            print("USAH ATTRIBUTEZ0", response.userAttributes![0]) // email_verified
            print("USAH ATTRIBUTEZ1", response.userAttributes![1]) // phone_number_verified
            print("USAH ATTRIBUTEZ2", response.userAttributes![2]) // phone_number
            print("USAH ATTRIBUTEZ3", response.userAttributes![3]) // email
            
            var emailVerifiedString : String!
            var phoneVerifiedString : String!
            
            for userAttribute in response.userAttributes!
            {
                
                switch userAttribute.name!
                {
                case "email_verified":
                    emailVerifiedString = userAttribute.value
                    break;
                case "phone_number_verified":
                    phoneVerifiedString = userAttribute.value
                    break;
                case "phone_number":
                    userData.phoneNumber = userAttribute.value
                    break;
                case "email":
                    userData.email = userAttribute.value
                    break;
                    
                default:
                    completion(result: nil, error: nil)

                    
                }
                
                
            }
            
            
            if (emailVerifiedString == "true")
            {
                userData.emailVerified = true
            }
            else
            {
                userData.emailVerified = false
            }
            
            if (phoneVerifiedString == "true")
            {
                userData.phoneNumberVerified = true
            }
            else
            {
                userData.phoneNumberVerified = false
            }
            
            
            
            completion(result: userData, error: nil)

            
        }
        
        return nil
    }

    
    
}


