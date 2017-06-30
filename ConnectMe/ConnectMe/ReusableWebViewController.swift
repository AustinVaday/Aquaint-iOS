//
//  ReusableWebViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/11/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class ReusableWebViewController: ViewControllerPannable {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var webView: UIWebView!
  @IBOutlet weak var copyLinkButton: UIButton!
  
  var webURL: String!
  var webTitle: String!
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override func viewWillAppear(_ animated: Bool) {
    
    let url = URL(string: webURL)
    let urlRequest = URLRequest(url: url!)
    webView.loadRequest(urlRequest)
    titleLabel.text = webTitle
  }
  
  override func viewDidAppear(_ animated: Bool) {
    
    if webTitle != nil {
      awsMobileAnalyticsRecordPageVisitEventTrigger("ReusableWebViewController - " + webTitle, forKey: "page_name")
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func backButtonClicked(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func copyLinkButtonClicked(_ sender: AnyObject) {
    // Copy link to clipboard!
    UIPasteboard.general.string = self.webURL
    
    showAlert("Done!", message: "You've copied " + self.webURL + " to your clipboard!", buttonTitle: "Ok", sender: self)
  }
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
}
