//
//  SinaWeiboAuthView.swift
//  testSwift
//
//  Created by Ruoyu Fu on 14-6-13.
//  Copyright (c) 2014年 Ruoyu Fu. All rights reserved.
//

import Foundation
import UIKit
import Social
import WebKit

enum SWKHTTPResponse:LogicValue{

    struct SuccessResp:Printable{
        let content : NSData
        let statusCode : Int
        let headers : NSDictionary
        let MIMEType : String
        let encoding : String
        var json : AnyObject!{
            return NSJSONSerialization.JSONObjectWithData(content, options: NSJSONReadingOptions.AllowFragments, error: nil)
        }
        var string : String{
            return NSString(data:content,encoding:NSUTF8StringEncoding)
        }
        var description: String {
            return self.string
        }
    }

    struct FailedResp:Printable{
        let error : NSError!
        let message : String!
        var description: String {
            if message{
                return message!
            }
            if error{
                return error!.description
            }
            return "No Detail Description For This Error"
        }

    }

    case success(SuccessResp)
    case failure(FailedResp)

    init(data:NSData!, response:NSURLResponse!, error:NSError!) {
        if let httpResponse = response as? NSHTTPURLResponse {
            switch httpResponse.statusCode {
            case 200..299:
                let resp = SuccessResp(
                            content : data,
                            statusCode : httpResponse.statusCode,
                            headers : httpResponse.allHeaderFields,
                            MIMEType : httpResponse.MIMEType,
                            encoding : httpResponse.textEncodingName)
                self = .success(resp)
            default:
                var message:String! = nil
                if data{
                    message = NSString(data:data,encoding:NSUTF8StringEncoding)
                }
                let resp = FailedResp(error:error,message:message)
                self = .failure(resp)
            }

        }else{
            var message:String! = nil
            if data{
                message = NSString(data:data,encoding:NSUTF8StringEncoding)
            }
            let resp = FailedResp(error:error,message:message)
            self = .failure(resp)
        }
    }

    func getLogicValue() -> Bool{
        switch self{
        case .success:
            return true
        default:
            return false
        }
    }

}


struct SWKAccount{
    var accessToken:String
    var expireDate:NSDate
    var uid:String
}

enum SWKAuthorizationResult{
    case Granted(SWKAccount)
    case Rejected
    case Failed
}


class SWKClient{
    
    let clientID:String
    let clientSecret:String
    let redirectURI:String
    var account:SWKAccount?

    init(clientID:String,clientSecret:String,redirectURI:String){
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }
    
    func presentAuthorizeView(fromViewController viewController:UIViewController, authorizeHandler:(Bool)->()){
        let authController = SWKAuthController(clientID:self.clientID,clientSecret:self.clientSecret,redirectURI:self.redirectURI){
            (result : SWKAuthorizationResult) in
            switch result{
            case .Granted(let account):
                self.account = account
                authorizeHandler(true)
                dispatch_async(dispatch_get_main_queue()){
                    viewController.dismissViewControllerAnimated(true, completion: nil)
                }
            default:
                authorizeHandler(false)
                }
        }
        dispatch_async(dispatch_get_main_queue()){
            viewController.presentViewController(authController, animated: true){}
        }
    }

    func get(url:String, parameters:Dictionary<String,String>! = nil, completion:((SWKHTTPResponse)->())! = nil){
        self.sendRequest(url, parameters: parameters, httpMethod: SLRequestMethod.GET, completion: completion)
    }
    
    func post(url:String, parameters:Dictionary<String,String>! = nil, completion:((SWKHTTPResponse)->())! = nil){
        self.sendRequest(url, parameters: parameters, httpMethod: SLRequestMethod.POST, completion: completion)
    }
    
    func sendRequest(url:String, parameters:Dictionary<String,String>! = nil,httpMethod:SLRequestMethod , completion:((SWKHTTPResponse)->())! = nil){
        var payload : Dictionary<String,String> = [:]
        if let account=self.account{
            payload["access_token"]=account.accessToken
        }
        if parameters{
            for (key,value) in parameters{
                payload[key]=value
            }
        }
        
        let sinaRequest = SLRequest(forServiceType : SLServiceTypeSinaWeibo, requestMethod : httpMethod, URL : NSURL(string:url), parameters: payload)
        sinaRequest.performRequestWithHandler{
            (data : NSData!, httpResponse : NSHTTPURLResponse!, error : NSError!) in
            let response = SWKHTTPResponse(data: data,response: httpResponse,error: error)
            completion(response)
        }
    }
}

class SWKAuthController: UIViewController,UIWebViewDelegate {
    
    let clientID:String
    let clientSecret:String
    let redirectURI:String
    let authorizeCallBack:(SWKAuthorizationResult)->()

    init(clientID:String,clientSecret:String,redirectURI:String,callBack:(SWKAuthorizationResult)->()){
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.authorizeCallBack = callBack
        
        super.init(nibName:nil,bundle:nil)
        
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let frame = self.view?.bounds{
//            let wv = 
            let authView = UIWebView(frame: frame)
            authView.delegate = self
            self.view?.addSubview(authView)
            let request = NSURLRequest(URL: NSURL(string:"https://api.weibo.com/oauth2/authorize?client_id=3128324185&redirect_uri=http://127.0.0.1/&display=mobile"))
            authView.loadRequest(request)
        }
    }
    
    func webView(webView: UIWebView!, shouldStartLoadWithRequest request: NSURLRequest!, navigationType: UIWebViewNavigationType) -> Bool{
        if request.URL.absoluteString.hasPrefix(self.redirectURI){
            if let array = request?.URL?.query?.componentsSeparatedByString("&"){
                for kvPairString in array {
                    let kvArray = kvPairString.componentsSeparatedByString("=")
                    if kvArray.count == 2{
                        if kvArray[0] == "code"{
                            let code = kvArray[1]
                            self.requestAccessToken(code)
                        }
                    }
                }
            }
        }
        return true;
    }
    
    func requestAccessToken(code:String){
        let url = NSURL(string:"https://api.weibo.com/oauth2/access_token")
        let payload = [
                "client_id":clientID,
                "client_secret":clientSecret,
                "grant_type":"authorization_code",
                "code":code,
                "redirect_uri":redirectURI]
        let sinaRequest = SLRequest(forServiceType : SLServiceTypeSinaWeibo, requestMethod : SLRequestMethod.POST, URL : url, parameters: payload)
        
        sinaRequest.performRequestWithHandler{
            (data : NSData!, urlResponse : NSURLResponse!, error : NSError!) in
            if error{
                self.authorizeCallBack(SWKAuthorizationResult.Failed)
                return
            }
            if let json = (NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary) {
                let expire = json["expires_in"] as? NSNumber
                let uid = json["uid"] as? NSString
                let token = json["access_token"] as? NSString
                if expire&&uid&&token{
                    self.authorizeCallBack(SWKAuthorizationResult.Granted(SWKAccount(accessToken:token!
                        ,expireDate:NSDate(timeIntervalSince1970:expire!.doubleValue),
                        uid:uid!)))
                    return

                }else{
                    self.authorizeCallBack(SWKAuthorizationResult.Failed)
                    return
                }
            }else{
                self.authorizeCallBack(SWKAuthorizationResult.Failed)
                return
            }
        }
    }
}