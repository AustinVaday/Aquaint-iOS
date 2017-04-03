//
//  CheckoutViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/30/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import Stripe

//struct Settings {
//  let theme: STPTheme
//  let additionalPaymentMethods: STPPaymentMethodType
//  let requiredBillingAddressFields: STPBillingAddressFields
//  let requiredShippingAddressFields: PKAddressField
//  let shippingType: Int
//  let smsAutofillEnabled: Bool
//}

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {
  
//  let stripePublishableKey = "pk_test_8wtPUgWqEu9jAZRVPNDMoVMn"
  let companyName = "Aquaint, Inc."
  let paymentCurrency = "usd"
  let paymentContext: STPPaymentContext
  let theme: STPTheme
  let paymentRow: CheckoutRowView
  let shippingRow: CheckoutRowView
  let totalRow: CheckoutRowView
  let buyButton: BuyButton
  let rowHeight: CGFloat = 44
  let productImage = UILabel()
  let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
  let numberFormatter: NSNumberFormatter
  let shippingString: String
  var product = ""
  var paymentInProgress: Bool = false {
    didSet {
    
      UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseIn , animations: {
        if self.paymentInProgress {
          self.activityIndicator.startAnimating()
          self.activityIndicator.alpha = 1
          self.buyButton.alpha = 0
        }
        else {
          self.activityIndicator.stopAnimating()
          self.activityIndicator.alpha = 0
          self.buyButton.alpha = 1
        }
        }, completion: nil)
    }
  }
  let planOption: String  // Subscription Options
  
  init(product: String, price: Int, planOptionFlag: String) {
    planOption = planOptionFlag
    
//    let stripePublishableKey = self.stripePublishableKey
//    let backendBaseURL = self.backendBaseURL
    
    self.product = product
    self.productImage.text = product
//    self.theme = settings.theme
//    MyAPIClient.sharedClient.baseURLString = self.backendBaseURL
    
    // This code is included here for the sake of readability, but in your application you should set up your configuration and theme earlier, preferably in your App Delegate.
    let config = STPPaymentConfiguration.sharedConfiguration()
    
//    config.publishableKey = self.stripePublishableKey
//    config.appleMerchantIdentifier = self.appleMerchantID
    config.companyName = self.companyName
//    config.requiredBillingAddressFields = settings.requiredBillingAddressFields
//    config.requiredShippingAddressFields = settings.requiredShippingAddressFields
//    config.shippingType = settings.shippingType
//    config.additionalPaymentMethods = settings.additionalPaymentMethods
//    config.smsAutofillDisabled = !settings.smsAutofillEnabled
    
    let paymentContext = STPPaymentContext(APIAdapter: MyAPIClient.sharedClient)
    
    let userInformation = STPUserInformation()
    paymentContext.prefilledInformation = userInformation
    paymentContext.paymentAmount = price
    paymentContext.paymentCurrency = self.paymentCurrency
    self.paymentContext = paymentContext
    
    self.paymentRow = CheckoutRowView(title: "Payment", detail: "Select Payment", theme: STPTheme())
    
//    var shippingString = "Contact"
//    if config.requiredShippingAddressFields.contains(.postalAddress) {
//      shippingString = config.shippingType == .shipping ? "Shipping" : "Delivery"
//    }
//    self.shippingString = shippingString
//    self.shippingRow = CheckoutRowView(title: self.shippingString,
//                                       detail: "Enter \(self.shippingString) Info",
//                                       theme: settings.theme)
    self.totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false, theme: STPTheme())
    self.buyButton = BuyButton(enabled: true, theme: STPTheme())
    
    let currencyCode = NSLocale.currentLocale().objectForKey(NSLocaleCurrencyCode)! as! String
    var localeComponents: [String: String] = [
      currencyCode: self.paymentCurrency,
      ]
//    localeComponents[NSLocale.Key.languageCode.rawValue] = NSLocale.preferredLanguages.first
    let localeID = NSLocale.localeIdentifierFromComponents(localeComponents)
    let numberFormatter = NSNumberFormatter()
    numberFormatter.locale = NSLocale(localeIdentifier: localeID)
    numberFormatter.numberStyle = .CurrencyStyle
    numberFormatter.usesGroupingSeparator = true
    self.numberFormatter = numberFormatter
    self.theme = STPTheme()
    self.shippingRow = CheckoutRowView()
    self.shippingString = "ship ship"
    super.init(nibName: nil, bundle: nil)
    self.paymentContext.delegate = self
    paymentContext.hostViewController = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")

  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = self.theme.primaryBackgroundColor
    var red: CGFloat = 0
    self.theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
    self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .White : .Gray
    self.navigationItem.title = "Aquaint Subscription"
    
    self.productImage.font = UIFont.systemFontOfSize(20)
    self.view.addSubview(self.totalRow)
//    self.view.addSubview(self.paymentRow)
//    self.view.addSubview(self.shippingRow)
    self.view.addSubview(self.productImage)
    self.view.addSubview(self.buyButton)
    self.view.addSubview(self.activityIndicator)
    self.activityIndicator.alpha = 0
    self.buyButton.addTarget(self, action: #selector(didTapBuy), forControlEvents: .TouchUpInside)
    self.totalRow.detail = self.numberFormatter.stringFromNumber(NSNumber(float: Float(self.paymentContext.paymentAmount)/100))!
    self.paymentRow.onTap = { [weak self] _ in
      self?.paymentContext.pushPaymentMethodsViewController()
    }
    self.shippingRow.onTap = { [weak self] _ in
      self?.paymentContext.presentPaymentMethodsViewController()
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = self.view.bounds.width
    self.productImage.sizeToFit()
    self.productImage.center = CGPoint(x: width/2.0,
                                       y: self.productImage.bounds.height/2.0 + rowHeight)
    self.paymentRow.frame = CGRect(x: 0, y: self.productImage.frame.maxY + rowHeight,
                                   width: width, height: rowHeight)
    self.shippingRow.frame = CGRect(x: 0, y: self.paymentRow.frame.maxY,
                                    width: width, height: rowHeight)
    self.totalRow.frame = CGRect(x: 0, y: self.shippingRow.frame.maxY,
                                 width: width, height: rowHeight)
    self.buyButton.frame = CGRect(x: 0, y: 0, width: 88, height: 44)
    self.buyButton.center = CGPoint(x: width/2.0, y: self.totalRow.frame.maxY + rowHeight*1.5)
    self.activityIndicator.center = self.buyButton.center
  }
  
  func didTapBuy() {
    self.paymentInProgress = true
    self.paymentContext.requestPayment()
  }
  
  // MARK: STPPaymentContextDelegate
  
  func paymentContext(paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: STPErrorBlock) {
    MyAPIClient.sharedClient.completeSubscription(paymentResult, planOption: planOption, completion: completion)
  }
  
  func paymentContext(paymentContext: STPPaymentContext, didFinishWithStatus status: STPPaymentStatus, error: NSError?) {
    let title: String
    let message: String
    switch status {
    case .Error:
      title = "Error"
      message = error?.localizedDescription ?? ""
    case .Success:
      title = "Success"
      message = "You bought a subscription to \(self.product)!"
      setCurrentCachedSubscriptionStatus(true)
    case .UserCancellation:
      return
    }
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let action = UIAlertAction(title: "OK", style: .Default, handler: { (alert: UIAlertAction!) in
      self.dismissViewControllerAnimated(true, completion: nil)
    })
    alertController.addAction(action)
    dispatch_async(dispatch_get_main_queue()) {
      self.paymentInProgress = false
      self.presentViewController(alertController, animated: true, completion: nil)
    }
  }
  
  func paymentContextDidChange(paymentContext: STPPaymentContext) {
//    self.paymentRow.loading = paymentContext.loading
//    if let paymentMethod = paymentContext.selectedPaymentMethod {
//      self.paymentRow.detail = paymentMethod.label
//    }
//    else {
//      self.paymentRow.detail = "Select Payment"
//    }

    self.totalRow.detail = self.numberFormatter.stringFromNumber(NSNumber(float: Float(self.paymentContext.paymentAmount)/100))!
  }
  
  func paymentContext(paymentContext: STPPaymentContext, didFailToLoadWithError error: NSError) {
    print("paymentContext(didFailToLoadWithError): \(error)")
    
    let alertController = UIAlertController(
      title: "Error",
      message: error.localizedDescription,
      preferredStyle: .Alert
    )
    let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
      self.dismissViewControllerAnimated(true, completion: nil)
    })
    let retry = UIAlertAction(title: "Retry", style: .Default, handler: { action in
      self.paymentContext.retryLoading()
    })
    alertController.addAction(cancel)
    alertController.addAction(retry)
    
    dispatch_async(dispatch_get_main_queue()) { 
      self.presentViewController(alertController, animated: true, completion: nil)
    }
  }

}
