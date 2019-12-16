//
//  LoginViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var servicetypeselect: UISegmentedControl!
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
        
        

        // Do any additional setup after loading the view.
        if let host = UserDefaults.standard.string(forKey: UD_SERVER_ADDR){
            self.urltextfield.text = host
        }
        
    }

    @IBAction func serviceTypeChanged(_ sender: Any) {
        switch (sender as AnyObject).selectedSegmentIndex {
        case 0:
            //Albireo
            UserDefaults.standard.set("albireo", forKey: UD_SERVICE_TYPE)
            //set UI as albireo
            self.usernametextfield.placeholder = "Username"
            self.passwordtextfield.isEnabled = true
            self.passwordtextfield.isHidden = false
            
            break
        case 1:
            //Sonarr
            UserDefaults.standard.set("sonarr", forKey: UD_SERVICE_TYPE)
            //set UI as sonarr
            self.usernametextfield.placeholder = "API key"
            self.passwordtextfield.isEnabled = false
            self.passwordtextfield.isHidden = true
            
            
            break
        default:
            print("null selected")
            break
        }
        UserDefaults.standard.synchronize()
    }
    @IBAction func loginBTNPressed(_ sender: Any) {
        if UserDefaults.standard.string(forKey: UD_SERVICE_TYPE) == "albireo" {
            if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
                (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
                (self.passwordtextfield.text?.lengthOfBytes(using: .utf8))! > 0{
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
                self.loginbutton.isEnabled = false
                logInServer(url:self.urltextfield.text!,
                            username: self.usernametextfield.text!,
                            password: self.passwordtextfield.text!) {
                                isSuccess,result in
                                
                                self.loadingIndicator.isHidden = true
                                self.loadingIndicator.stopAnimating()
                                self.loginbutton.isEnabled = true
                                if isSuccess{
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
        }else if UserDefaults.standard.string(forKey: UD_SERVICE_TYPE) == "sonarr"{
            if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
                (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0{
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
                self.loginbutton.isEnabled = false
                logInServer(url:self.urltextfield.text!,
                            username: self.usernametextfield.text!,
                            password: self.passwordtextfield.text!) {
                                isSuccess,result in
                                
                                self.loadingIndicator.isHidden = true
                                self.loadingIndicator.stopAnimating()
                                self.loginbutton.isEnabled = true
                                if isSuccess{
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
        }else{
            print("Error: Service type unknown.")
            return
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
