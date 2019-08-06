//
//  AlamofireManager.swift
//  FruitSalad
//
//  Created by 黄山锋 on 2019/8/2.
//  Copyright © 2019 Caleb Stultz. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

enum MethodType {
    case get
    case post
    case put
    case delete
}

class PDHttp: SessionManager {
    
    static var instance : PDHttp? = nil
    
    class func shareManager() -> PDHttp{
        
        var header : HTTPHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        header["Authorization"] = ""
        header.updateValue("application/json", forKey: "Accept")
        let configration = URLSessionConfiguration.default
        configration.httpAdditionalHeaders = header
        
        instance = PDHttp(configuration: configration)
        
        return instance!
    }
    
    func requestData(_ type : MethodType, urlString : String, parameters : [String : AnyObject]?, success : @escaping (_ responseObject : [String : AnyObject]) -> (), failure : @escaping (_ error : NSError) -> ()) -> (){
        let method : HTTPMethod
        
        switch type {
        case .get:
            method = .get
            break
        case .post:
            method = .post
            break
        case .put:
            method = .put
            break
        default:
            method = .get
        }
        
        self.request(urlString, method: method, parameters: parameters).responseJSON { (response) in
            switch response.result{
            case .success:
                if let value = response.result.value as? [String : AnyObject]{
                    success(value)
                }
            case .failure(let error):
                failure(error as NSError)
            }
        }
        
    }
}


