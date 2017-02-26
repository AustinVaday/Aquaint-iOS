//
//  ViewController.swift
//  ProjectAutomata
//
//  Created by Austin Vaday on 2/25/17.
//  Copyright © 2017 AquaintInc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var urlTextField: UITextField!
  @IBOutlet weak var webView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func onGoButtonClicked(sender: AnyObject) {
    
    var urlStr = urlTextField.text! as String
    
    if urlStr.characters.count == 0 {
      urlStr = "https://www.facebook.com/profile.php?id=100003172599969"
    }
 
    print("URL: ", urlStr)
    let url = NSURL(string: urlStr)
    let requestObj = NSURLRequest(URL: url!)
    
    dispatch_async(dispatch_get_main_queue(), { 
      self.webView.loadRequest(requestObj)
    })
    
      
    
    
  }

}

