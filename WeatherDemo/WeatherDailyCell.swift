//
//  WeatherDailyCell.swift
//  WeatherDemo
//
//  Created by TAPAN BISWAS on 11/28/17.
//  Copyright © 2017 TAPAN BISWAS. All rights reserved.
//

import UIKit

class DescribedCell: UITableViewCell {

    @IBOutlet weak var dailyDescribed: UILabel!
    
}

class ForecastCell: UITableViewCell {
    
    @IBOutlet weak var dayofweek: UILabel!
    @IBOutlet weak var dayicon: UIImageView!
    @IBOutlet weak var dayHigh: UILabel!
    @IBOutlet weak var dayLow: UILabel!
    
}

class DetailsCell: UITableViewCell {
    
    @IBOutlet weak var param1Label: UILabel!
    @IBOutlet weak var param1Value: UILabel!
    @IBOutlet weak var param2Label: UILabel!
    @IBOutlet weak var param2Value: UILabel!
    
}
