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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let proxyAddr = UserDefaults.standard.string(forKey: "proxy")
        let proxyPort = UserDefaults.standard.string(forKey: "proxyport")
        self.proxyIPField.text = proxyAddr
        self.proxyPortField.text = proxyPort
    }
    @IBAction func applyBTNPressed(_ sender: Any) {
        if (self.proxyIPField.text?.lengthOfBytes(using: .utf8))! > 0 &&
            (self.proxyPortField.text?.lengthOfBytes(using: .utf8))! > 0{
            UserDefaults.standard.set(self.proxyIPField.text, forKey: "proxy")
            UserDefaults.standard.set(self.proxyPortField.text, forKey: "proxyport")
            UserDefaults.standard.synchronize()
            
            self.dismiss(animated: true, completion: nil)
        }else{
            UserDefaults.standard.set("", forKey: "proxy")
            UserDefaults.standard.set("", forKey: "proxyport")
            self.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func resetBTNPressed(_ sender: Any) {
        UserDefaults.standard.set("", forKey: "proxy")
        UserDefaults.standard.set("", forKey: "proxyport")
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
