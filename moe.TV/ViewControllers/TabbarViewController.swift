//
//  TabbarViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit


class TabbarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    override func viewDidAppear(_ animated: Bool) {
        let loggedin = UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_LOGEDIN)
        if loggedin == false {
            print("notlogin")
            var loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController")
            if #available(tvOS 13.0, *) {
                loginVC = self.storyboard?.instantiateViewController(identifier: "LoginViewController")
            }
            self.present(loginVC!, animated: false, completion: nil)
        }else{
//            self.tabBarController?.tabBar.isHidden = false
//            self.tabBar.isHidden = false
            
        }
        NotificationCenter.default.addObserver(self, selector: #selector(getTopShelf), name: NSNotification.Name(rawValue: "topshelf"), object: nil)
        
        
        
    }

    
    @objc func getTopShelf(notification:Notification) {
        let dic = notification.userInfo
        let url = dic!["url"] as! URL
        
        let host = url.host
        let bangumiUUID = url.pathComponents[1] // 0 is '/' ╮(╯▽╰)╭
        if host == "detail" {
            let detailvc = self.storyboard?.instantiateViewController(withIdentifier: "BangumiDetailViewController") as! BangumiDetailViewController
            detailvc.bangumiUUID = bangumiUUID
            self.present(detailvc, animated: true)
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
