//
//  ProfileViewController.swift
//  PeoplePortal
//
//  Created by Anastasis Germanidis on 10/18/15.
//  Copyright © 2015 Anastasis Germanidis. All rights reserved.
//

import UIKit
import Async

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileBackgroundView: UIImageView!
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarHidden = true
//        UIApplication.sharedApplication().statusBarStyle = .LightContent
        navigationController?.navigationBarHidden = true
    }
    
    @IBAction func followingButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("UserListSegue", sender: sender)
    }
    
    @IBAction func followersButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("UserListSegue", sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "UserListSegue" {
            let dest = segue.destinationViewController as! UserTableViewController
            if sender?.tag == Constants.FOLLOWING_BUTTON_TAG {
                dest.source = Session.shared.shadowedUser!.following.items
                dest.viewTitle = "Following"
            } else {
                dest.source = Session.shared.shadowedUser!.followers.items
                dest.viewTitle = "Followers"
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        Async.main {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "TweetCellView", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "TweetCell")
        
        let shadowedUser = Session.shared.shadowedUser!
        let user = shadowedUser.user
        
        Async.main {
            shadowedUser.start()
        }
        
        if user.profileBannerUrl != nil {
           profileBackgroundView.sd_setImageWithURL(NSURL(string: user.profileBannerUrl!))
        }
        profileBackgroundView.backgroundColor = user.userColor
        
        if user.profileImageUrl != nil {
            profileImageView.sd_setImageWithURL(NSURL(string: user.profileImageUrlBigger!))
        }
        
        nameLabel.text = user.name!
        screenNameLabel.text = "@\(user.screenName!)"
        followingButton.setTitle("\(Utils.formatNumber(user.friendCount!)) FOLLOWING", forState: .Normal)
        followersButton.setTitle("\(Utils.formatNumber(user.followerCount!)) FOLLOWERS", forState: .Normal)
        
        nameLabel.sizeToFit()
        screenNameLabel.sizeToFit()
        followingButton.sizeToFit()
        followersButton.sizeToFit()
        
        profileImageView.backgroundColor = UIColor.clearColor()
        profileImageView.layer.cornerRadius = 5
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        profileImageView.layer.masksToBounds = true
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)

        self.navigationController?.navigationBar.setBackgroundImage(imageLayerForGradientBackground(), forBarMetrics: UIBarMetrics.Default)
        adaptNavTextColor()
        self.navigationItem.title = "@\(user.screenName!)"

        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
        adaptNavTextColor()
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
    
    func refresh() {
        Session.shared.shadowedUser?.waitForWorkers([ProfileWorker.self]) {
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    var tweets: [Tweet] {
        get {
            return Session.shared.shadowedUser!.userTimeline.items
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TweetCell", forIndexPath: indexPath) as! TweetTableViewCell
        let tweet = tweets[indexPath.row]
        cell.loadWithTweet(tweet)
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let tweet = tweets[indexPath.row]
        let textHeight = tweet.calculateCellHeight(UIFont.systemFontOfSize(15), width: tableView.frame.size.width-100.0)
        return textHeight + 92
        
    }

    @IBAction func switchButtonPressed(sender: AnyObject) {
        let shadowedUser = Session.shared.shadowedUser!
        let hoursSinceSwitch = shadowedUser.hoursSinceSwitch()
        if hoursSinceSwitch < 0 {
            let alertController = UIAlertController(title: "Unable to Switch", message:
                "Sorry, you cannot become someone else so quickly. Please wait \(Constants.SWITCH_HOURS_MINIMUM-hoursSinceSwitch) more hours.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("SelectionView")
        self.modalTransitionStyle = .FlipHorizontal
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(vc, animated: true, completion: {
            
        })
    }
    
    func adaptNavTextColor() {
        if Session.shared.shadowedUser!.user.userColor!.shouldUseWhiteForeground() {
            UIApplication.sharedApplication().statusBarStyle = .LightContent
            navigationController!.navigationBar.tintColor = UIColor.whiteColor()
            navigationController!.navigationBar.titleTextAttributes = [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 20)!
                ] as Dictionary<String, AnyObject>
            
        } else {
            UIApplication.sharedApplication().statusBarStyle = .Default
            navigationController!.navigationBar.tintColor = UIColor.blackColor()
            navigationController!.navigationBar.titleTextAttributes = [
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 20)!
            ]
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        print("scroll offset: \(tableView.contentOffset)")
        if tableView.contentOffset.y > 250.0 {
            UIApplication.sharedApplication().statusBarHidden = false
            navigationController?.navigationBarHidden = false
            
        } else {
            UIApplication.sharedApplication().statusBarHidden = true
            navigationController?.navigationBarHidden = true
        }
    }

}