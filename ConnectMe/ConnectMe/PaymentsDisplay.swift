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
class PaymentsDisplay: ViewControllerPannable, SKProductsRequestDelegate, SKPaymentTransactionObserver {
  
  var productIDs: Array<String?> = []
  var productsArray: Array<SKProduct?> = []
  var transactionInProgress = false
  let selectedProductIndex = 0
  var paidDelegate : PaymentsDisplayDelegate?
  
  // Make sure Apple's server has responded with IAP product information before proceding to purchase
  var productsRequestDidReceiveResponse = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // TODO: Fetch list of apple IDs programmatically in future.
    self.productIDs.append("Aquaint_Subscription_1_mo")
    self.requestProductInfo()
    
  }

  override func viewWillAppear(_ animated: Bool) {
    if SKPaymentQueue.canMakePayments() {
      SKPaymentQueue.default().add(self)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    if SKPaymentQueue.canMakePayments() {
      SKPaymentQueue.default().remove(self)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    awsMobileAnalyticsRecordPageVisitEventTrigger("PaymentsDisplay", forKey: "page_name")
  }

  @IBAction func onPromoCodeButtonClicked(_ sender: AnyObject) {
     //Prompt user to enter in confirmation code.
      DispatchQueue.main.async(execute: {
          self.showPromoCodePopup({ (result) in
              if result != nil
              {
                if result! == "SOCIAL27" {
                  print("SUCCESS")
                  self.uploadPromoCodeStatus(true)
                  if self.paidDelegate != nil {
                    self.paidDelegate!.didPayForProduct()
                    
                    DispatchQueue.main.async(execute: { 
                      self.dismiss(animated: true, completion: nil)
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
  
  
  @IBAction func onClickBuyBottom(_ sender: AnyObject) {
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
    
    if authenticationContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
      // Check the fingerprint
      authenticationContext.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
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
    
    let payment = SKPayment(product: self.productsArray[self.selectedProductIndex] as! SKProduct)
    SKPaymentQueue.default().add(payment)
    self.transactionInProgress = true
    
    // Record event trigger
    awsMobileAnalyticsRecordButtonClickEventTrigger("PaymentsDisplay - Buy", forKey: "button_name")
    
  }
  
  @IBAction func backButtonClicked(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)
  }
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
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
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case SKPaymentTransactionState.purchased:
        print("Transaction completed successfully.")
        SKPaymentQueue.default().finishTransaction(transaction)
        setCurrentCachedSubscriptionStatus(true)
        transactionInProgress = false
        
        if paidDelegate != nil {
          self.paidDelegate!.didPayForProduct()
          DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: nil)
          })
        }

        
      case SKPaymentTransactionState.failed:
        print("Transaction Failed");
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionInProgress = false
        
      case SKPaymentTransactionState.restored:
        SKPaymentQueue.default().restoreCompletedTransactions()
        transactionInProgress = false
        setCurrentCachedSubscriptionStatus(true)
       
        if paidDelegate != nil {
          self.paidDelegate!.didPayForProduct()
          DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: nil)
          })
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
  
  fileprivate func showPromoCodePopup(_ completion: @escaping (_ result:String?)->())
  {
    var alertViewResponder: SCLAlertViewResponder!
    let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 70))
    let x = (subview.frame.width - 180) / 2
    let colorDarkBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
    
    // Add text field for username
    let textField = UITextField(frame: CGRect(x: x,y: 10,width: 180,height: 25))
    
    //            textField.layer.borderColor = colorLightBlue.CGColor
    //            textField.layer.borderWidth = 1.5
    //            textField.layer.cornerRadius = 5
    textField.font = UIFont(name: "Avenir Roman", size: 14.0)
    textField.textColor = colorDarkBlue
    textField.placeholder = "Enter Promo Code"
    textField.textAlignment = NSTextAlignment.center
    
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
  
  
  func uploadPromoCodeStatus(_ isPromoUser: Bool) {
    // Upload user DATA to DynamoDB
    let dynamoDBUser = UserPromoCodeMinimalObjectModel()
    
    dynamoDBUser?.username = getCurrentCachedUser()
    
    if isPromoUser
    {
      dynamoDBUser?.promouser = 1
      setCurrentCachedPromoUserStatus(true)
      
    } else {
      dynamoDBUser?.promouser = 0
      setCurrentCachedPromoUserStatus(false)
      
    }
    
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    dynamoDBObjectMapper.save(dynamoDBUser!).continue({ (resultTask) -> AnyObject? in
      
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
