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
        if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
            (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
            (self.passwordtextfield.text?.lengthOfBytes(using: .utf8))! > 0{
            
            logInServer(url:self.urltextfield.text!,
                        username: self.usernametextfield.text!,
                        password: self.passwordtextfield.text!) {
                            isSuccess,result in
                            
                            if isSuccess{
                                self.dismiss(animated: true, completion: nil)
                            }else{
                                //TODO
                            }
                            
                
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
