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
}
