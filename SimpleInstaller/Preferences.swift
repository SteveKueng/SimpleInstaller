//
//  Preferences.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 23.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Foundation

class Preferences {
    
    // Default Configuration Variables
    internal let bundle_id = "com.github.stevekueng.simpleinstaller"
    internal let defaultpreferences = [
        "serverurl":"http://127.0.0.1/install/config.plist",
        "reporturl":"",
        ] as [String : Any]
    
    // Pull configuration settings from managed preferences or set defaults
    func get_config_settings(preference_key: String) -> Any {
        let bundle_plist = UserDefaults.init(suiteName: bundle_id)
        var preference_value = bundle_plist?.value(forKey: preference_key)
        if preference_value == nil {
            preference_value = defaultpreferences[preference_key]
            return(preference_value)!
        }
        return(preference_value)!
    }
    
    
    // load config from server
    func loadPlist(url: String) -> (Dictionary<String, Any>?, String?, String?) {
        var data: Data?
        var error: Error?
        var response: URLResponse?
        var errorMessage: String?
        var errorDetail: String?
        
        if let url = URL(string: url) {
            let semaphore = DispatchSemaphore(value: 0)
            let dataTask = URLSession.shared.dataTask(with: url) {
                data = $0
                response = $1
                error = $2
                
                semaphore.signal()
            }
            dataTask.resume()
            _ = semaphore.wait(timeout: .distantFuture)
            
            if error == nil {
                do {
                    if data != nil {
                        let dictionary = try PropertyListSerialization.propertyList(from: data!, options: [], format: nil) as! [String:Any]
                        return (dictionary, errorMessage, errorDetail)
                    } else {
                       errorMessage = "no plist found!"
                    }
                } catch {
                    errorMessage = "content could not be loaded!"
                    errorDetail = "\(error.localizedDescription)"
                }
            } else {
                errorMessage = "connection error!"
                errorDetail = "\(error!.localizedDescription)"
            }
        } else {
            errorMessage = "url format error"
        }
        return (nil, errorMessage, errorDetail)
    }
}
