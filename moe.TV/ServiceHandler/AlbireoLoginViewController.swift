//
//  LoginViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class AlbireoLoginViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var servicetypeselect: UISegmentedControl!
    @IBOutlet weak var connectiontypeselect: UISegmentedControl!
    @IBOutlet weak var urltextfield: UITextField!
    @IBOutlet weak var webdavporttextfield: UITextField!
    @IBOutlet weak var usernametextfield: UITextField!
    @IBOutlet weak var passwordtextfield: UITextField!
    @IBOutlet weak var apikeytextfield: UITextField!
    @IBOutlet weak var loginbutton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var serviceType = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.urltextfield.delegate = self
        self.usernametextfield.delegate = self
        self.passwordtextfield.delegate = self
        self.apikeytextfield.delegate = self
        self.webdavporttextfield.delegate = self
        
        self.loadingIndicator.isHidden = true
        self.loadingIndicator.stopAnimating()
        
        //set default service
        UserDefaults.init(suiteName: UD_SUITE_NAME)?.set("albireo", forKey: UD_SERVICE_TYPE)
        self.servicetypeselect.selectedSegmentIndex = 0
        self.connectiontypeselect.selectedSegmentIndex = 0
        
        self.urltextfield.placeholder = "Server Address"
        self.usernametextfield.placeholder = "Username"
        self.passwordtextfield.placeholder = "Password"
        self.apikeytextfield.isHidden = true
        self.webdavporttextfield.isHidden = true
        
        
        // load host url if it was saved
        if let host = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR){
            self.urltextfield.text = host
        }
        
        //api key is too long for input eveytime you logouted
        self.apikeytextfield.text = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_APIKEY)
        
        
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
    
    @IBAction func serviceTypeChanged(_ sender: Any) {
        switch (sender as AnyObject).selectedSegmentIndex {
        case 0:
            //Albireo
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set("albireo", forKey: UD_SERVICE_TYPE)
            //set UI as albireo
            self.urltextfield.placeholder = "Server Address"
            self.usernametextfield.placeholder = "Username"
            self.passwordtextfield.placeholder = "Password"
            self.apikeytextfield.isHidden = true
            self.webdavporttextfield.isHidden = true
            break
        case 1:
            //Sonarr
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set("sonarr", forKey: UD_SERVICE_TYPE)
            //set UI as sonarr
            self.urltextfield.placeholder = "Server Address:8989"
            self.usernametextfield.placeholder = "Username (Optional)"
            self.passwordtextfield.placeholder = "Password (Optional)"
            self.apikeytextfield.isHidden = false
            self.webdavporttextfield.isHidden = false
            
            break
        default:
            print("null selected")
            break
        }
        UserDefaults.init(suiteName: UD_SUITE_NAME)?.synchronize()
        self.serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)!
    }
    
    @IBAction func loginBTNPressed(_ sender: Any) {
        let urltext = self.urltextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = self.usernametextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = self.passwordtextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let apikey = self.apikeytextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let webdavport = self.webdavporttextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        //Albireo
        if self.serviceType == "albireo" {
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
            
            //Sonarr
        }else if self.serviceType == "sonarr"{
            if (urltext.lengthOfBytes(using: .utf8)) > 0 &&
                (username.lengthOfBytes(using: .utf8)) > 0 &&
                (webdavport.lengthOfBytes(using: .utf8)) > 0
            {
                
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
                self.loginbutton.isEnabled = false
                
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(urltext, forKey: UD_SERVER_ADDR)
                SonarrGetSystemStatus(username: username,
                                      password: password,
                                      apikey: apikey){
                    isSucceeded,result in
                    
                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()
                    self.loginbutton.isEnabled = true
                    
                    if isSucceeded{
                        let r = result as! Dictionary<String,Any>
                        if let ver = r["version"] {
                            print(ver)
                            
                            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
                            
                            //save the api key
                            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(apikey, forKey: UD_SONARR_APIKEY)
                            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(webdavport, forKey: UD_SONARR_WEBDAV_PORT)
                            
                            //save auth info if not empty
                            if (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0 ||
                                (self.passwordtextfield.text?.lengthOfBytes(using: .utf8))! > 0{
                                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_SONARR_USINGBASICAUTH)
                                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(username, forKey: UD_SONARR_USERNAME)
                                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(password, forKey: UD_SONARR_PASSWORD)
                            }
                            
                            UserDefaults.init(suiteName: UD_SUITE_NAME)?.synchronize()
                            self.dismiss(animated: true, completion: nil)
                            return
                        }
                    }
                    print(result as Any)
                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
                    let err = result as! Dictionary<String,String>
                    let alert = UIAlertController(title: "Error", message: err["error"] as! String, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                        //self.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
                
            }
        }else{
            print("LoginVC loginBTNPressed Error: Service type unknown.")
            return
        }
        
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)!
        if self.serviceType == "albireo"{
            
            if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
            (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
            (self.passwordtextfield.text?.lengthOfBytes(using: .utf8))! > 0{
                self.loginbutton.isEnabled = true
            }else{
                self.loginbutton.isEnabled = false
            }
            
        }else if self.serviceType == "sonarr" {
            if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
            (self.usernametextfield.text?.lengthOfBytes(using: .utf8))! > 0 {
                self.loginbutton.isEnabled = true
            }else{
                self.loginbutton.isEnabled = false
            }
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
