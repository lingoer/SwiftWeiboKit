//
//  ViewController.swift
//  Example
//
//  Created by Ruoyu Fu on 14-6-14.
//  Copyright (c) 2014年 Ruoyu Fu. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    //需要将这3个参数替换为你自己在新浪申请的参数
    let client = SWKClient(clientID:"", clientSecret:"", redirectURI:"")
    var statuses:NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func login(sender : UIButton) {
        //点击登录后，首先打开授权页面，让用户授权
        client.presentAuthorizeView(fromViewController: self){
            result in
            //用户授权的回调
            if result{
                //若授权成功，就可以直接访问API了，这里是：statuses/home_timeline.json
                self.client.get("https://api.weibo.com/2/statuses/home_timeline.json"){
                    result in
                    switch result{
                    case .success(let success):
                        if let statusesArray = (success.json as? NSDictionary)?["statuses"] as? NSArray{
                            self.statuses = statusesArray
                            self.tableView.reloadData()
                        }
                    default:
                        println(result)
                    }
                }
            }
        }
    }

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int{
        if statuses{
            return statuses.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!{
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("StatusCell", forIndexPath: indexPath) as UITableViewCell
        
        cell.detailTextLabel.text = (statuses[indexPath.row] as? NSDictionary)?["text"] as? String
        cell.textLabel.text = ((statuses[indexPath.row] as? NSDictionary)?["user"] as? NSDictionary)?["name"] as? String
        cell.setNeedsLayout()
        return cell
    }
}

