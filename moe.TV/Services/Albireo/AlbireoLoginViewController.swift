//
//  LoginViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class AlbireoLoginViewController: UIViewController,UITextFieldDelegate {
//    @IBOutlet weak var servicetypeselect: UISegmentedControl!
    //    var serviceType = ""
    
    
    @IBOutlet weak var connectiontypeselect: UISegmentedControl!
    @IBOutlet weak var urltextfield: UITextField!

    @IBOutlet weak var usernametextfield: UITextField!
    @IBOutlet weak var passwordtextfield: UITextField!
    @IBOutlet weak var loginbutton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.urltextfield.delegate = self
        self.usernametextfield.delegate = self
        self.passwordtextfield.delegate = self
        
        
        self.loadingIndicator.isHidden = true
        self.loadingIndicator.stopAnimating()
        
        //set default service
//        UserDefaults.init(suiteName: UD_SUITE_NAME)?.set("albireo", forKey: UD_SERVICE_TYPE)
//        self.servicetypeselect.selectedSegmentIndex = 0
        self.connectiontypeselect.selectedSegmentIndex = 0
        
        self.urltextfield.placeholder = "Server Address"
        self.usernametextfield.placeholder = "Username"
        self.passwordtextfield.placeholder = "Password"
        
        
        
        // load host url if it was saved
        if let host = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR){
            self.urltextfield.text = host
        }
        
    }
    @IBAction func connectionTypeChanged(_ sender: Any) {
        switch (sender as AnyObject).selectedSegmentIndex {
        case 0:
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_USING_HTTPS)
        case 1:
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_USING_HTTPS)
        default:
            break
        }
        UserDefaults.init(suiteName: UD_SUITE_NAME)?.synchronize()
    }
    
    
    @IBAction func loginBTNPressed(_ sender: Any) {
        let urltext = self.urltextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = self.usernametextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = self.passwordtextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (urltext.lengthOfBytes(using: .utf8)) > 0 &&
            (username.lengthOfBytes(using: .utf8)) > 0 &&
            (password.lengthOfBytes(using: .utf8)) > 0{
            
            self.loadingIndicator.isHidden = false
            self.loadingIndicator.startAnimating()
            self.loginbutton.isEnabled = false
            
            
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(urltext, forKey: UD_SERVER_ADDR)
            AlbireoLogInAlbireoServer(username: username,
                                      password: password) {
                            isSucceeded,result in
                            
                            self.loadingIndicator.isHidden = true
                            self.loadingIndicator.stopAnimating()
                            self.loginbutton.isEnabled = true
                            if isSucceeded{
                                self.dismiss(animated: true, completion: nil)
                            }else{
                                print(result as Any)
                                let err = result
                                let alert = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                                    //self.dismiss(animated: true, completion: nil)
                                }))
                                self.present(alert, animated: true, completion: nil)
                            }
            }
        }
        
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
        (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
        (self.passwordtextfield.text?.lengthOfBytes(using: .utf8))! > 0{
            self.loginbutton.isEnabled = true
        }else{
            self.loginbutton.isEnabled = false
        }
        
    }
    func  textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.passwordtextfield{
            //textField.resignFirstResponder()
            self.loginBTNPressed(self)
            return false
        }
        return true
    }


}
