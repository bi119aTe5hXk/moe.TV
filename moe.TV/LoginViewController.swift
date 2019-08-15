//
//  LoginViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var urltextfield: UITextField!
    @IBOutlet weak var usernametextfield: UITextField!
    @IBOutlet weak var passwordtextfield: UITextField!
    @IBOutlet weak var loginbutton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func loginBTNPressed(_ sender: Any) {
        if urltextfield.text?.lengthOfBytes(using: .utf8) != 0 &&
            usernametextfield.text?.lengthOfBytes(using: .utf8) != 0 &&
            passwordtextfield.text?.lengthOfBytes(using: .utf8) != 0{
            logInServer(username: usernametextfield.text!, password: passwordtextfield.text!) { result in
                
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
