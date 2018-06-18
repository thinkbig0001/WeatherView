//
//  Utility.swift
//  WeatherDemo
//
//  Created by TAPAN BISWAS on 11/28/17.
//  Copyright © 2017 TAPAN BISWAS. All rights reserved.
//

import Foundation
import UIKit

func showAlert(alertmsg: String) {
    //Get topmost presentation controller and present the alert
    let alert = UIAlertController(title: "Alert", message:alertmsg, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        // topController should now be the topmost view controller
        topController.present(alert, animated: true, completion: nil)
    }
}
