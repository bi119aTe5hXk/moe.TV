//
//  TabbarViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

@available(tvOS 13.0, *)
class TabbarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    override func viewDidAppear(_ animated: Bool) {
        let loggedin = UserDefaults.standard.bool(forKey: "loggedin")
        if loggedin == false {
            print("notlogin")
            let loginVC = self.storyboard?.instantiateViewController(identifier: "LoginViewController")
            self.present(loginVC!, animated: false, completion: nil)
        }
        self.tabBarController?.tabBar.isHidden = false
        self.tabBar.isHidden = false
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
