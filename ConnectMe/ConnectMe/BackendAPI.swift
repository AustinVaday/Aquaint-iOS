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

// Set up AWS service config (default log-in/sign-up)
func getAWSCognitoIdentityUserPool() -> AWSCognitoIdentityUserPool
{
    let serviceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: nil)
    let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: "41v7gese46ar214saeurloufe7", clientSecret: "1lr1abieg6g8fpq06hngo9edqg4qtf63n3cql1rgsvomc11jvs9b", poolId: "us-east-1_yyImSiaeD")
    AWSCognitoIdentityUserPool.registerCognitoIdentityUserPoolWithConfiguration(serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
    return AWSCognitoIdentityUserPool(forKey: "UserPool")
}

//func getAWSTransferManagerUploadRequest -> AWSS3TransferManagerUploadRequest
//{
//
//    
//}

