//
//  SummaryDetailViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/22.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

class SummaryDetailViewController: UIViewController {
    var summaryText:String = ""
    @IBOutlet weak var summaryTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.summaryTextView.text = summaryText
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
