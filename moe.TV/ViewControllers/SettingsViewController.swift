//
//  SettingsViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/22.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func logoutBTNPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Warning", message: "Do you really want to signout your account?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            logOutServer { (isSuccess, result) in
                
            }
            
            UserDefaults.standard.set(false, forKey: "loggedin")
            
            //cleanup bgmlist
            let mybgmvc = self.storyboard?.instantiateViewController(withIdentifier: "MyBangumiListViewController") as! MyBangumiListViewController
            mybgmvc.bgmList = []
            let onairvc = self.storyboard?.instantiateViewController(withIdentifier: "OnAirListViewController") as! OnAirListViewController
            onairvc.bgmList = []
            
            var loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController")
            if #available(tvOS 13.0, *) {
                loginVC = self.storyboard?.instantiateViewController(identifier: "LoginViewController")
            }
            self.present(loginVC!, animated: false, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: {(action) in
            //self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
        
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
