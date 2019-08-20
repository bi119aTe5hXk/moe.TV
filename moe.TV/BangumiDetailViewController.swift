//
//  BangumiDetailViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class BangumiDetailViewController: UIViewController {
    var bangumiUUID:String = ""
    var bgmDic = ["":""] as Dictionary<String,Any>
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if bangumiUUID.lengthOfBytes(using: .utf8) > 0 {
            getBangumiDetail(id: bangumiUUID) { (isSuccess, result) in
                if isSuccess {
                    self.bgmDic = result as! [String : Any]
                    
                    
                }else{
                    //TODO - show error
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
