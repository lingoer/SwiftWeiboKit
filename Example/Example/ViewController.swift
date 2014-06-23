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
    let client = SWKClient(clientID:"1818152344", clientSecret:"dbeb5f4cfada69f679c1e39e8785df8d", redirectURI:"http://127.0.0.1/")
    var statuses:JSONValue = JSONValue.JInvalid
    
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
                    self.statuses = result.json
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int{
        if statuses["statuses"].array{
            return statuses["statuses"].array!.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!{
        var cell:UITableViewCell
        if let dequeuedCell = tableView.dequeueReusableCellWithIdentifier("StatusCell", forIndexPath: indexPath) as? UITableViewCell{
            cell = dequeuedCell
        }else{
            cell = UITableViewCell()
        }
        
        cell.detailTextLabel.text = statuses["statuses"][indexPath.row]["text"].string
        cell.textLabel.text = statuses["statuses"][indexPath.row]["user"]["name"].string
        cell.setNeedsLayout()
        return cell
    }
}

