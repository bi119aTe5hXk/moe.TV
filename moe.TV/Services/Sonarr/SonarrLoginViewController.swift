//
//  SonarrLoginViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2020/03/15.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import UIKit

class SonarrLoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var connectiontypeselect: UISegmentedControl!
    @IBOutlet var urltextfield: UITextField!

    @IBOutlet var webdavporttextfield: UITextField!
    @IBOutlet var apikeytextfield: UITextField!

    @IBOutlet var usernametextfield: UITextField!
    @IBOutlet var passwordtextfield: UITextField!
    @IBOutlet var loginbutton: UIButton!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        apikeytextfield.delegate = self
        webdavporttextfield.delegate = self

        urltextfield.delegate = self
        usernametextfield.delegate = self
        passwordtextfield.delegate = self

        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()

        connectiontypeselect.selectedSegmentIndex = 0


        urltextfield.placeholder = "Server Address:8989"
        usernametextfield.placeholder = "Username (Optional)"
        passwordtextfield.placeholder = "Password (Optional)"
        apikeytextfield.isHidden = false
        webdavporttextfield.isHidden = false

        // api key is too long for input eveytime you logouted
        apikeytextfield.text = UserDefaults(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_APIKEY)

        // load host url if it was saved
        if let host = UserDefaults(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR) {
            urltextfield.text = host
        }
    }

    @IBAction func connectionTypeChanged(_ sender: Any) {
        switch (sender as AnyObject).selectedSegmentIndex {
        case 0:
            UserDefaults(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_USING_HTTPS)
        case 1:
            UserDefaults(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_USING_HTTPS)
        default:
            break
        }
        UserDefaults(suiteName: UD_SUITE_NAME)?.synchronize()
    }

    @IBAction func loginBTNPressed(_ sender: Any) {
        let urltext = self.urltextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = self.usernametextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = self.passwordtextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let apikey = self.apikeytextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let webdavport = self.webdavporttextfield.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        if (urltext.lengthOfBytes(using: .utf8)) > 0 &&
            (apikey.lengthOfBytes(using: .utf8)) > 0 &&
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
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        if (self.urltextfield.text?.lengthOfBytes(using: .utf8))! > 0 &&
        (self.apikeytextfield.text?.lengthOfBytes(using: .utf8))! > 0 {
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
