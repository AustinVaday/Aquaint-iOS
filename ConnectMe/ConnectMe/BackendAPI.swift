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
import AWSLambda
import FBSDKCoreKit
import FBSDKLoginKit

class FacebookProvider: NSObject, AWSIdentityProviderManager {
  func logins() -> AWSTask {
    let token = FBSDKAccessToken.currentAccessToken()
    if token != nil {
      return AWSTask(result: [AWSIdentityProviderFacebook:token])
    }
    return AWSTask(error:NSError(domain: "Facebook Login", code: -1 , userInfo: ["Facebook" : "No current Facebook access token"]))
  }
}

// Set up AWS service config (default log-in/sign-up)
func getAWSCognitoIdentityUserPool() -> AWSCognitoIdentityUserPool
{
//    let serviceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: nil)
//    let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "41v7gese46ar214saeurloufe7", clientSecret: "1lr1abieg6g8fpq06hngo9edqg4qtf63n3cql1rgsvomc11jvs9b", poolId: "us-east-1_yyImSiaeD")
//    AWSCognitoIdentityUserPool.registerCognitoIdentityUserPoolWithConfiguration(serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
//  
//    return AWSCognitoIdentityUserPool(forKey: "UserPool")
  
  return userPool
}

func setCachedUserFromAWS(userName: String!)
{
    /*******************************************
    * username, accounts, full name from DYNAMODB
    ********************************************/
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    
    dynamoDBObjectMapper.load(UserPrivacyObjectModel.self, hashKey: userName, rangeKey: nil).continueWithBlock { (resultTask) -> AnyObject? in
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
            let user = resultTask.result as! UserPrivacyObjectModel
            
            setCurrentCachedUserName(userName)
            setCurrentCachedFullName(user.realname)
            if (user.isprivate != nil && user.isprivate == 1) {
              setCurrentCachedPrivacyStatus("private")
            }
            else {
              setCurrentCachedPrivacyStatus("public")
            }
          
            if user.accounts != nil
            {
                setCurrentCachedUserProfiles(user.accounts as NSMutableDictionary)
            }
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
            print("CACHE: COULD NOT GET USER POOLS \(error)")

        }
        
        if (result != nil)
        {
            let userPoolData = result
            setCurrentCachedUserEmail(userPoolData!.email!)
            setCurrentCachedUserPhone(userPoolData!.phoneNumber!)
        
        }
        
    }


    
}

func getUserDynamoData(userName: String!, completion: (result: UserPrivacyObjectModel?, error: NSError?)->())
{
    
    /*******************************************
     * username, accounts, full name from DYNAMODB
     ********************************************/
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    
    dynamoDBObjectMapper.load(UserPrivacyObjectModel.self, hashKey: userName, rangeKey: nil).continueWithBlock { (resultTask) -> AnyObject? in
        if (resultTask.error != nil)
        {
            print("Error getting user from dynamoDB: ", resultTask.error)
            completion(result: nil, error: resultTask.error)

        }
        else if (resultTask.exception != nil)
        {
            print("Exception getting user from dynamoDB: ", resultTask.exception)
            completion(result: nil, error: nil)

        }
        else if (resultTask.result == nil)
        {
            print("Error getting user from dynamoDB: nil result")
            completion(result: nil, error: nil)

        }
        else
        {
            let user = resultTask.result as! UserPrivacyObjectModel
            
            completion(result: user, error: nil)
        }
        
        return nil
    }

}

func getUserS3Image(userName: String!, completion: (result: UIImage?, error: NSError?)->())
{
    
    /*******************************************
     * user image from S3
     ********************************************/
    // AWS TRANSFER REQUEST
    let randomNum = 1000 + rand() % 999999
    let downloadingFilePath = NSTemporaryDirectory().stringByAppendingString(String(randomNum))

    print("DOWNLOADING FILEPATH FOR ", userName, " IS: ", downloadingFilePath)
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
            
            
            try! NSFileManager.defaultManager().removeItemAtPath(downloadingFilePath)
            completion(result: image, error: nil)
            
        }
        else // If fail file transfer
        {
            print("fetch s3 user image: ERROR FILE DOWNLOAD: ", resultTask.error)
            
//            try! NSFileManager.defaultManager().removeItemAtPath(downloadingFilePath)
            completion(result: nil, error: resultTask.error)
        }
        
        return nil
        
    })
    
}

func setUserS3Image(userName: String!, userImage: UIImage!, completion: (error: NSError?)->())
{
    
    // Resize photo for cheaper storage
    let targetSize = CGSize(width: 150, height: 150)
    let newImage = RBResizeImage(userImage, targetSize: targetSize)
    
    // Create temp file location for image (hint: may be useful later if we have users taking photos themselves and not wanting to store it)
    let imageFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingString("temp"))
    
    // Force PNG format
    let data = UIImagePNGRepresentation(newImage)
    try! data?.writeToURL(imageFileURL, options: NSDataWritingOptions.AtomicWrite)
    
    // AWS TRANSFER REQUEST
    let transferRequest = AWSS3TransferManagerUploadRequest()
    transferRequest.bucket = "aquaint-userfiles-mobilehub-146546989"
    transferRequest.key = "public/" + userName
    transferRequest.body = imageFileURL
    let transferManager = AWSS3TransferManager.defaultS3TransferManager()
    
    transferManager.upload(transferRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock:
        { (resultTask) -> AnyObject? in
            
            // if sucessful file transfer
            if resultTask.error == nil
            {
                // Also cache it.. only if file successfully uploadsd
                setCurrentCachedUserImage(userImage)
                completion(error: nil)
                
            }
            else // If fail file transfer
            {
                completion(error: resultTask.error)
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
            print("User Pool fetch data Error:", resultTask.error)
            completion(result: nil, error: resultTask.error)
        }
        else if resultTask.result == nil
        {
            print("User Pool fetch data IS NIL...")
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

func updateCurrentUserProfilesDynamoDB(currentUserProfiles: NSMutableDictionary!, socialMediaType:String, socialMediaName:String, isAdding:Bool, completion: (result: User?, error: NSError?)->())
{
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    let currentUser = getCurrentCachedUser()
    let currentRealName = getCurrentCachedFullName()
    var currentAccounts = currentUserProfiles
    
    if (isAdding && currentAccounts == nil)
    {
        currentAccounts = NSMutableDictionary()
        currentAccounts.setValue([ socialMediaName ], forKey: socialMediaType)

    }
    else if (isAdding && currentAccounts.valueForKey(socialMediaType) == nil)
    {
        currentAccounts.setValue([ socialMediaName ], forKey: socialMediaType)
        
    } // If it already exists, append value to end of list
    else
    {
        
        var list = currentAccounts.valueForKey(socialMediaType) as! Array<String>
        
        if isAdding
        {
            list.append(socialMediaName)
        }
        else
        {
            // Get list without this socialMediaName (i.e. remove it...)
            list.removeAtIndex(list.indexOf(socialMediaName)!)
        }
    
        // If nothing in list, we need to delete the key
        if list.count == 0
        {
            currentAccounts.removeObjectForKey(socialMediaType)
        }
        else
        {
            currentAccounts.setValue(list, forKey: socialMediaType)
        }
    }
    
    // Upload user DATA to DynamoDB
    let dynamoDBUser = User()
    
    dynamoDBUser.username = currentUser
    dynamoDBUser.realname = currentRealName
    
    // Only add this object if there is data to consider. If we give an empty dictionary,
    // dynamo will throw an error.
    if currentAccounts.count != 0
    {
        dynamoDBUser.accounts = currentAccounts
    }

    print(currentUser, " BEEP ", currentRealName, " BEEP ", currentAccounts)
    
    dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
        
        if (resultTask.error != nil)
        {
            print ("DYNAMODB MODIFY PROFILE ERROR: ", resultTask.error)
            completion(result: nil, error: resultTask.error)
        }
        
        if (resultTask.result == nil)
        {
            print ("DYNAMODB MODIFY PROFILE result is nil....: ")
            completion(result: nil, error: nil)
            
        }
        // If successful save
        else if (resultTask.error == nil)
        {
            print ("DYNAMODB MODIFY PROFILE SUCCESS: ", resultTask.result)
            completion(result: dynamoDBUser, error: nil)
        }
        
        
        return nil
    })
    
}

func uploadUserFBUIDToDynamo(userName: String, fbUID: String)
{
  let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
  
  // Upload user DATA to DynamoDB
  let dynamoDBUser = UserFBObjectModel()
  
  dynamoDBUser.username = userName
  dynamoDBUser.fbuid = fbUID
  
  dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock(
    { (resultTask) -> AnyObject? in
      if (resultTask.error != nil) {
        print ("DYNAMODB ADD PROFILE ERROR: ", resultTask.error)
      }
      
      if (resultTask.exception != nil) {
        print ("DYNAMODB ADD PROFILE EXCEPTION: ", resultTask.exception)
      }
      
      if (resultTask.result == nil) {
        print ("DYNAMODB ADD PROFILE result is nil....: ")
      } else if (resultTask.error == nil) {
        // If successful save
        print ("DYNAMODB ADD PROFILE SUCCESS: ", resultTask.result)
      }
      return nil
    }
  )
  
}

func warmUpLambda()
{
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    let parameters = ["action":"doIFollow", "target": "", "me": ""]
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
        return nil
    }
}


