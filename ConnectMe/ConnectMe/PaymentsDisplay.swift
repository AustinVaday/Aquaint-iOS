//
//  PaymentsDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import StoreKit
import LocalAuthentication
import SCLAlertView
import AWSDynamoDB


protocol PaymentsDisplayDelegate {
  func didPayForProduct()
}
// Will have the real displays and data
class PaymentsDisplay: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
  
  var productIDs: Array<String!> = []
  var productsArray: Array<SKProduct!> = []
  var transactionInProgress = false
  let selectedProductIndex = 0
  var paidDelegate : PaymentsDisplayDelegate?
  
  // Make sure Apple's server has responded with IAP product information before proceding to purchase
  var productsRequestDidReceiveResponse = false
  
  override func viewDidLoad() {
    // TODO: Fetch list of apple IDs programmatically in future.
    self.productIDs.append("Aquaint_Subscription_1_mo")
    self.requestProductInfo()
    
  }

  override func viewWillAppear(animated: Bool) {
    if SKPaymentQueue.canMakePayments() {
      SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
  }
  
  override func viewWillDisappear(animated: Bool) {
    if SKPaymentQueue.canMakePayments() {
      SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
  }

  override func viewDidAppear(animated: Bool) {
    awsMobileAnalyticsRecordPageVisitEventTrigger("PaymentsDisplay", forKey: "page_name")
  }

  @IBAction func onPromoCodeButtonClicked(sender: AnyObject) {
     //Prompt user to enter in confirmation code.
      dispatch_async(dispatch_get_main_queue(), {
          self.showPromoCodePopup({ (result) in
              if result != nil
              {
                if result! == "SOCIAL27" {
                  print("SUCCESS")
                  self.uploadPromoCodeStatus(true)
                  if self.paidDelegate != nil {
                    self.paidDelegate!.didPayForProduct()
                    
                    dispatch_async(dispatch_get_main_queue(), { 
                      self.dismissViewControllerAnimated(true, completion: nil)
                    })
                  }
                } else {
                  self.uploadPromoCodeStatus(false)
                }
              }
              else
              {
                  // Invalid entry or request, revert back to previous phone number
                  print("INVALID REQUESTO")
              }
          })

      })

  }
  
  
  @IBAction func onClickBuyBottom(sender: AnyObject) {
    if transactionInProgress {
      return
    }
    
    if (productsRequestDidReceiveResponse == false) || (selectedProductIndex >= productsArray.count) {
      let alertMsg = "No subscription product information has been retrieved. Please check Internet connection, or wait a few seconds and try again. "
      showAlert("Subscription Error", message: alertMsg, buttonTitle: "OK", sender: self)
      return
    }
    
    // Touch ID LocalAuthentication
    let authenticationContext = LAContext()
    
    if authenticationContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
      // Check the fingerprint
      authenticationContext.evaluatePolicy(
        .DeviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Aquaint Subscription - Authentication is needed to proceed with purchase.",
        reply: { [unowned self] (success, error) -> Void in
          if(success) {
            // Fingerprint recognized
          } else {
            // Check if there is an error
            if let error = error {
              // TODO: Handle this
            }
          }
        })
      
    }
    
    let payment = SKPayment(product: self.productsArray[self.selectedProductIndex] as SKProduct)
    SKPaymentQueue.defaultQueue().addPayment(payment)
    self.transactionInProgress = true
    
    // Record event trigger
    awsMobileAnalyticsRecordButtonClickEventTrigger("PaymentsDisplay - Buy", forKey: "button_name")
    
  }
  
  @IBAction func backButtonClicked(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
    if response.products.count != 0 {
      for product in response.products {
        productsArray.append(product)
      }
    }
    else {
      print("There are no products.")
    }
    
    if response.invalidProductIdentifiers.count != 0 {
      print(response.invalidProductIdentifiers.description)
    }
    
    productsRequestDidReceiveResponse = true
  }
  
  func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case SKPaymentTransactionState.Purchased:
        print("Transaction completed successfully.")
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        setCurrentCachedSubscriptionStatus(true)
        transactionInProgress = false
        
        if paidDelegate != nil {
          self.paidDelegate!.didPayForProduct()
        }

        
      case SKPaymentTransactionState.Failed:
        print("Transaction Failed");
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        transactionInProgress = false
        
      case SKPaymentTransactionState.Restored:
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        transactionInProgress = false
        setCurrentCachedSubscriptionStatus(true)
       
        if paidDelegate != nil {
          self.paidDelegate!.didPayForProduct()
        }
        
      default:
        print(transaction.transactionState.rawValue)
      }
    }
  }
  
  
  
  func requestProductInfo() {
    if SKPaymentQueue.canMakePayments() {
      let productIdentifiers = NSSet(array: productIDs) as! Set<String>
      let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
      
      productRequest.delegate = self
      productRequest.start()
    }
    else {
      print("Cannot perform In App Purchases.")
    }
  }
  
  private func showPromoCodePopup(completion: (result:String?)->())
  {
    var alertViewResponder: SCLAlertViewResponder!
    let subview = UIView(frame: CGRectMake(0,0,216,70))
    let x = (subview.frame.width - 180) / 2
    let colorDarkBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
    
    // Add text field for username
    let textField = UITextField(frame: CGRectMake(x,10,180,25))
    
    //            textField.layer.borderColor = colorLightBlue.CGColor
    //            textField.layer.borderWidth = 1.5
    //            textField.layer.cornerRadius = 5
    textField.font = UIFont(name: "Avenir Roman", size: 14.0)
    textField.textColor = colorDarkBlue
    textField.placeholder = "Enter Promo Code"
    textField.textAlignment = NSTextAlignment.Center
    
    // Add target to text field to validate/fix user input of a proper input
    //        textField.addTarget(self, action: #selector(usernameTextFieldDidChange), forControlEvents: UIControlEvents.EditingChanged)
    subview.addSubview(textField)
    //
    let alertAppearance = SCLAlertView.SCLAppearance(
      showCircularIcon: true,
      kCircleIconHeight: 40,
      kCircleHeight: 55,
      shouldAutoDismiss: false,
      hideWhenBackgroundViewIsTapped: true
      
    )
    
    let alertView = SCLAlertView(appearance: alertAppearance)
    
    alertView.customSubview = subview
    alertView.addButton("Submit", action: {
      print("Submit button clicked for textField data:", textField.text)
      
      if alertViewResponder == nil
      {
        print("Something went wrong...")
        completion(result: nil)
      }
      
      let code = textField.text!
      
      if code.isEmpty
      {
        //TODO: Nothing?
      }
      else
      {
        print("SUCCESS RESULT:", code)
        alertViewResponder.close()
        completion(result: code)
        // Update userpools with verification
      }
      
      
    })
    
    let alertViewIcon = UIImage(named: "Emblem White")
    
    alertViewResponder = alertView.showTitle("Promo Code",
                                             subTitle: "",
                                             duration:0.0,
                                             completeText: "Cancel",
                                             style: .Success,
                                             colorStyle: 0x0F7A9D,
                                             colorTextButton: 0xFFFFFF,
                                             circleIconImage: alertViewIcon,
                                             animationStyle: .BottomToTop
    )
    
  }
  
  
  func uploadPromoCodeStatus(isPromoUser: Bool) {
    // Upload user DATA to DynamoDB
    let dynamoDBUser = UserPromoCodeMinimalObjectModel()
    
    dynamoDBUser.username = getCurrentCachedUser()
    
    if isPromoUser
    {
      dynamoDBUser.promouser = 1
      setCurrentCachedPromoUserStatus(true)
      
    } else {
      dynamoDBUser.promouser = 0
      setCurrentCachedPromoUserStatus(false)
      
    }
    
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
    dynamoDBObjectMapper.save(dynamoDBUser).continueWithBlock({ (resultTask) -> AnyObject? in
      
      if (resultTask.error != nil)
      {
        print ("DYNAMODB UPDATE PROFILE ERROR: ", resultTask.error)
      }
      
      if (resultTask.result == nil)
      {
        print ("DYNAMODB UPDATE PROFILE result is nil....: ")
        
      }
        // If successful save
      else if (resultTask.error == nil)
      {
        print ("DYNAMODB UPDATE PROFILE SUCCESS: ", resultTask.result)
      }
      
      return nil
    })

  }

}
