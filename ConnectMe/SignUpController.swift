//
//  SignUpController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/13/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit

class SignUpController: UIViewController {
    
    // UI variable data types
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // EditingDidEnd functionality will be used for error checking user input
    @IBAction func nameEditingDidEnd(sender: UITextField) {
        print(userName.text)
        
    }
    
    @IBAction func emailEditingDidEnd(sender: AnyObject) {
        print(userEmail.text)
    }
    
    @IBAction func passwordEditingDidEnd(sender: AnyObject) {
        print(userPassword.text)
    }
    
    // Actions to perform when "Sign Up" is clicked
    @IBAction func signUpButtonClicked(sender: AnyObject) {
        print("Do something here")
    }
    
}
