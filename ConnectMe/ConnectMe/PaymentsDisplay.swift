//
//  PaymentsDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import StoreKit


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
  
  override func viewDidLoad() {
    // TODO: Fetch list of apple IDs programmatically in future.
    productIDs.append("Aquaint_Subscription_1_mo")
    
    requestProductInfo()
    
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
  }

  @IBAction func onClickBuyBottom(sender: AnyObject) {
    if transactionInProgress {
      return
    }
    
    let payment = SKPayment(product: self.productsArray[self.selectedProductIndex] as SKProduct)
    SKPaymentQueue.defaultQueue().addPayment(payment)
    self.transactionInProgress = true
    
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
