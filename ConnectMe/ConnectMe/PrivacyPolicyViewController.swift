//
//  SignUpFetchMoreDataController.swift
//
//
//  Created by Austin Vaday on 7/3/16.
//
//

import UIKit


class PrivacyPolicyViewController: UIViewController {
    
    var isKeyboardShown = false
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up webview to link to privacy policy
        
        let url = NSURL(string: "http://www.aquaint.us/static/privacy-policy")
        let urlRequest = NSURLRequest(URL: url!)
        
        webView.loadRequest(urlRequest)
    }
    
    
    /*=======================================================
     * BEGIN : Keyboard/Button Animations
     =======================================================*/
    
    // Add and Remove NSNotifications!
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
                
        // Set up pan gesture recognizer for when the user wants to swipe left/right
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .Left
        view.addGestureRecognizer(edgePan)
        
    }
    
    
    func screenEdgeSwiped(recognizer: UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == .Ended
        {
            print("Screen swiped!")
            dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
    }
    
    
    
}
