//
//  MainViewController.swift
//  PeoplePortal
//
//  Created by Anastasis Germanidis on 10/25/15.
//  Copyright © 2015 Anastasis Germanidis. All rights reserved.
//

import UIKit
import Async

class MainViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Session.shared.shadowedUser?.onNotificationsChanged({
            self.updateBadge()
        })
        Async.main {
            self.updateBadge()
        }
        
        // Do any additional setup after loading the view.
    }
    
    func updateBadge() {
        let n = Session.shared.shadowedUser!.numberOfUnseenNotifications
        self.viewControllers![1].tabBarItem.badgeValue = Utils.badgeText(n)
        UIApplication.sharedApplication().applicationIconBadgeNumber = n
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}