//
//  NotificationsViewController.swift
//  PeoplePortal
//
//  Created by Anastasis Germanidis on 10/23/15.
//  Copyright © 2015 Anastasis Germanidis. All rights reserved.
//

import UIKit
import Async

class NotificationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var footerMessage: String {
        get {
            if notifications.count > 0 {
                return ""
            } else {
                return "No notifications to display"
            }
        }
    }
    
    var notifications: [Notification] {
        get {
            let items = Array(Session.shared.shadowedUser!.notifications.items.reverse())
            return Array(items[0..<min(items.count, 20)])
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarHidden = false
        navigationController?.navigationBarHidden = false
        adaptNavTextColor()
    }
    
    func adaptNavTextColor() {
        if Session.shared.shadowedUser!.user.userColor!.shouldUseWhiteForeground() {
            UIApplication.sharedApplication().statusBarStyle = .LightContent
            navigationController!.navigationBar.titleTextAttributes = [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 20)!
                ] as Dictionary<String, AnyObject>
            
        } else {
            UIApplication.sharedApplication().statusBarStyle = .Default
            navigationController!.navigationBar.titleTextAttributes = [
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 20)!
            ]
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController!.tabBarItem.badgeValue = Utils.badgeText(0)
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        self.tableView.reloadData()
    }
    
    private func imageLayerForGradientBackground() -> UIImage {
        var updatedFrame = self.navigationController!.navigationBar.frame
        // take into account the status bar
        updatedFrame.size.height += 20
        let userColor = Session.shared.shadowedUser!.user.userColor!
        let color1 = userColor.darkenColor(0.1).CGColor
        let color2 = userColor.CGColor
        let layer = CAGradientLayer.gradientLayerForBounds(updatedFrame, colors: [color1, color2])
        UIGraphicsBeginImageContext(layer.bounds.size)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tweetCellViewNib = UINib(nibName: "TweetCellView", bundle: nil)
        tableView.registerNib(tweetCellViewNib, forCellReuseIdentifier: "TweetCell")
        
//        messageLabel.text = footerMessage
        tableView.dataSource = self
        tableView.delegate = self
        tableView.scrollsToTop = true
        
        self.navigationController?.navigationBar.setBackgroundImage(imageLayerForGradientBackground(), forBarMetrics: UIBarMetrics.Default)
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let notification = notifications[indexPath.row]

        if notification.isFollow() {
            let cell = tableView.dequeueReusableCellWithIdentifier("FollowCell", forIndexPath: indexPath) as! FollowNotificationTableViewCell
            cell.loadWithNotification(notification)
            if !notification.seen {
                cell.backgroundColor = Constants.UNSEEN_NOTIFICATION_BACKGROUND
                notification.seen = true
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        } else if notification.isMention() {
            let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell", forIndexPath: indexPath) as! TweetTableViewCell
            cell.loadWithTweet(notification.tweet!)
            if !notification.seen {
                cell.backgroundColor = Constants.UNSEEN_NOTIFICATION_BACKGROUND
                notification.seen = true
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("RetweetCell", forIndexPath: indexPath) as! RetweetNotificationTableViewCell
            cell.loadWithNotification(notification)
            if !notification.seen {
                cell.backgroundColor = Constants.UNSEEN_NOTIFICATION_BACKGROUND
                notification.seen = true
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let notification = notifications[indexPath.row]
        if notification.isFollow() {
            return FollowNotificationTableViewCell.calculateCellHeight(notification)
            
        } else if notification.isMention() {
            let textHeight = notification.tweet!.calculateCellHeight(UIFont.systemFontOfSize(16), width: tableView.frame.size.width-75)
            return textHeight + 80
        
        } else {
            return RetweetNotificationTableViewCell.calculateCellHeight(notification)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    @IBOutlet weak var footerView: UIView!
    
    func update() {
        self.navigationController!.tabBarItem.badgeValue = Utils.badgeText(0)
        self.refreshControl?.endRefreshing()
        self.tableView.reloadData()
    }

    func refresh() {
        Session.shared.shadowedUser?.waitForWorkers([MentionsWorker.self]) {
            Async.main {
                self.update()
            }
        }
    }
}
