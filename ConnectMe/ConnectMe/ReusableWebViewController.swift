//
//  ReusableWebViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/11/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class ReusableWebViewController: UIViewController {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var webView: UIWebView!
  var webURL: String!
  var webTitle: String!
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override func viewWillAppear(animated: Bool) {
    
    let url = NSURL(string: webURL)
    let urlRequest = NSURLRequest(URL: url!)
    webView.loadRequest(urlRequest)
    titleLabel.text = webTitle
  }
  
  override func viewDidAppear(animated: Bool) {
    
    if webTitle != nil {
      awsMobileAnalyticsRecordPageVisitEventTrigger("ReusableWebViewController - " + webTitle, forKey: "page_name")
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func backButtonClicked(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
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
