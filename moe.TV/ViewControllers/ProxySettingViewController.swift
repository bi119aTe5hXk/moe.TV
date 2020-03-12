//
//  ProxySettingViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/22.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class ProxySettingViewController: UIViewController {
    @IBOutlet weak var proxyIPField: UITextField!
    @IBOutlet weak var proxyPortField: UITextField!
    @IBOutlet weak var proxySwitch: UISegmentedControl!
    let ud = UserDefaults.init(suiteName: UD_SUITE_NAME)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let proxySwitch = self.ud.bool(forKey: UD_PROXY_ENABLED)
        if proxySwitch {
            self.proxySwitch.selectedSegmentIndex = 1
        }else{
            self.proxySwitch.selectedSegmentIndex = 0
        }
        self.proxyIPField.text = self.ud.string(forKey: UD_PROXY_SERVER)
        self.proxyPortField.text = self.ud.string(forKey: UD_PROXY_PORT)
    }
    @IBAction func applyBTNPressed(_ sender: Any) {
        let proxyip = self.proxyIPField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let proxyport = self.proxyPortField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if proxyip!.lengthOfBytes(using: .utf8) > 0 &&
           proxyport!.lengthOfBytes(using: .utf8) > 0{
            
            self.ud.set(true, forKey: UD_PROXY_ENABLED)
            self.ud.set(self.proxyIPField.text, forKey: UD_PROXY_SERVER)
            self.ud.set(self.proxyPortField.text, forKey: UD_PROXY_PORT)
            self.ud.synchronize()
            
            self.dismiss(animated: true, completion: nil)
        }else{
            self.ud.set(false, forKey: UD_PROXY_ENABLED)
//            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set("", forKey: UD_PROXY_SERVER)
//            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set("", forKey: UD_PROXY_PORT)
            self.ud.synchronize()
            self.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func proxySwitchChanged(_ sender: Any) {
        switch (sender as AnyObject).selectedSegmentIndex {
        case 0:
            self.ud.set(false, forKey: UD_PROXY_ENABLED)
        case 1:
            self.ud.set(true, forKey: UD_PROXY_ENABLED)
        default:
            break
        }
        self.ud.synchronize()
    }
    @IBAction func resetBTNPressed(_ sender: Any) {
        self.proxyIPField.text = ""
        self.proxyPortField.text = ""
        self.proxySwitch.selectedSegmentIndex = 0
        self.ud.set(false, forKey: UD_PROXY_ENABLED)
        self.ud.set("", forKey: UD_PROXY_SERVER)
        self.ud.set("", forKey: UD_PROXY_PORT)
        self.dismiss(animated: true, completion: nil)
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

