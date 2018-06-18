//
//  DataAccess.swift
//  WeatherDemo
//
//  Created by TAPAN BISWAS on 11/28/17.
//  Copyright © 2017 TAPAN BISWAS. All rights reserved.
//
// This file contains functions to load JSON data or from DataStore

import Foundation
import Alamofire        //Install Cocoapod Alamofire before using it here. Use for Networking
import SwiftyJSON       //Install Cocoapod SwiftyJSON before using it here. Use for JSON Parsing

//Constants Defined for the app
let DarkSkyURL = "https://api.darksky.net/forecast/"

var processing : Bool = false //Flag to prevent multiple requests queuing up

//API call is in the format https://api.darksky.net/forecast/[key]/[latitude],[longitude]
//Key is stored in info.plist, latitude and longitude is obtained from CoreLocation

//For URL Request we need to send the following along with Key
struct reqParams {       //Request Parameters
    var key : String = ""        //API Key - required
    var latitude : String = ""       //Latitude  - required
    var longitude: String = ""     //Longitude - required
    
    init() {
        self.key = ""
        self.latitude = ""
        self.longitude = ""
    }
    
    init(key: String, latitude: String, longitude: String) {
        self.key = key
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct basicData : Codable {
    var apparentTemperature: Double?
    var icon: String?
    var precipType: String?
    var precipProbability: Double?
    var pressure: Double?
    var humidity: Double?
    var precipIntensity: Double?
    var windSpeed: Double?
    var summary: String?
    var uvIndex: Int?
    var ozone: Double?
    var temperature: Double?
    var dewPoint: Double?
    var windGust: Double?
    var windBearing: Double?
    var cloudCover: Double?
    var time: Date?
}

struct hourlyData : Codable {
    var summary: String?
    var icon: String?
    var data: [basicData] = []
}

struct dailyBasicData : Codable {
    var time: Date?
    var icon: String?
    var summary: String?
    var uvIndex: Int?
    var uvIndexTime: Date?
    var windGust: Double?
    var windGustTime: Date?
    var windBearing: Int?
    var precipAccumulation: Double?
    var humidity: Double?
    var temperatureMin: Double?
    var windSpeed: Double?
    var temperatureHigh: Double?
    var temperatureHighTime: Date?
    var temperatureLow: Double?
    var temperatureLowTime: Date?
    var apparentTemperatureMax: Double?
    var apparentTemperatureMaxTime: Date?
    var apparentTemperatureMin: Double?
    var apparentTemperatureMinTime: Date?
    var ozone: Double?
    var dewPoint: Double?
    var moonPhase: Double?
    var precipProbability: Double?
    var precipType: String?
    var pressure: Double?
    var temperatureMaxTime: Date?
    var temperatureMinTime: Date?
    var precipIntensity: Double?
    var precipIntensityMax: Double?
    var precipIntensityMaxTime: Date?
    var temperatureMax: Double?
    var cloudCover: Double?
    var apparentTemperatureHigh: Double?
    var apparentTemperatureHighTime: Date?
    var apparentTemperatureLow: Double?
    var apparentTemperatureLowTime: Date?
}

struct dailyData : Codable {
    var summary: String?
    var icon: String?
    var data: [dailyBasicData] = []
}

struct alertData : Codable {
    var title: String?
    var time: Date?
    var expires: Date?
    var description: String?
    var uri: String?
}

struct flagData : Codable {
    var units: String?
}

//Main JSON Structure
struct record {
    var latitude: String?
    var longitude: String?
    var timezone: String?
    var currently: basicData?
    var hourly: hourlyData?
    var daily: dailyData?
    var alerts: alertData?
    var flags: flagData?
}


func initiateDataLoadRequest(params: reqParams) {
    
    //Check if we are already processing one request
    if processing { return }
    
    //Set flag to prevent multiple requests queuing up
    processing = true

    //convert passed parameters into a string - ensure required parameters are present
    //if time permits ensure it's in correct format
    guard !(params.latitude.isEmpty) && !(params.longitude.isEmpty) else {
        processing = false
        return //later implement error messaging
    }
    
    //Construct URL from url and parameters
    let urlParams = "\(params.key)/\(params.latitude),\(params.longitude)"
    let urlString = DarkSkyURL + urlParams
    
    //Clear the dataModel before fetch data
    dataModel = nil
        
    //Use Alamofire to make the URL request. Automatically validate response 200..<300 type
    Alamofire.request(urlString).responseJSON { (response) -> Void in
        switch response.result {
        case .success:
            //debugPrint("Validation Successful")
            break
        case .failure(let error):
            processing = false
            //time permits - do better error handling and user messaging
            let errMsg = "Oops! Something went wrong with retrieving weather data. Check your internet connection and try again\n\nLoading previously saved data, if any"
            //debugPrint(error)
            showAlert(alertmsg: errMsg)
            return
        }

        processing = false
        
        //Parse JSON into our dataModel
        if let data = response.result.value {
            dataModel = parseJSON(data: data)

            //Save received JSON in User Defaults
            UserDefaults.standard.set(response.result.value, forKey: "WeatherData")

            //Notify that data has been loaded
            let nc = NotificationCenter.default
            nc.post(name:myNotification, object: nil,userInfo:["message":"Data loaded from DarkSky", "date":Date()])
        }
    }
    
    processing = false
    
    if dataModel == nil { //Nothing was fetched
        if let data = UserDefaults.standard.dictionary(forKey: "WeatherData") {
            dataModel = parseJSON(data: data)
            
            //Notify that data has been loaded
            let nc = NotificationCenter.default
            nc.post(name:myNotification, object: nil,userInfo:["message":"Data loaded from local Datastore", "date":Date()])
        }
    }
}

func parseJSON(data: Any?) -> record {
    
    var model = record()
    
    //Check if the result has the value
    if let value = data {
        //if so, convert into JSON format
        let json = JSON(value)
        
        //debugPrint(json)

        //parse json into model
        model.longitude = json["longitude"].stringValue
        model.latitude = json["latitude"].stringValue
        model.timezone = json["timezone"].stringValue
        
        let currently = json["currently"]
        let daily = json["daily"]
        let hourly = json["hourly"]
        let alerts = json["alerts"]
        let flags = json["flags"]
        
        model.currently = parseBasicData(json: currently)
        model.daily = parseDailyData(json: daily)
        model.hourly = parseHourlyData(json: hourly)
        model.alerts = parseAlertData(json: alerts)
        model.flags = parseFlagData(json: flags)
    }
    
    //return our data
//    print(model.hourly)
//    print(model.currently)
//    print(model.alerts)
//    print(model.flags)

    return model
    
}

func parseBasicData(json: JSON) -> basicData {
    var rec = basicData()
    
    //For some odd reason json.doubleValue is giving wrong value. Use Swift Double to convert from string.
    
    rec.apparentTemperature = Double(json["apparentTemperature"].stringValue)
    rec.icon = json["icon"].stringValue
    rec.precipType = json["precipType"].stringValue
    rec.precipProbability = Double(json["precipProbability"].stringValue)
    rec.pressure = Double(json["pressure"].stringValue)
    rec.humidity = Double(json["humidity"].stringValue)
    rec.precipIntensity = Double(json["precipIntensity"].stringValue)
    rec.windSpeed = Double(json["windSpeed"].stringValue)
    rec.summary = json["summary"].stringValue
    rec.uvIndex = json["uvIndex"].intValue
    rec.ozone = Double(json["ozone"].stringValue)
    rec.temperature = Double(json["temperature"].stringValue)
    rec.dewPoint = Double(json["dewPoint"].stringValue)
    rec.windGust = Double(json["windGust"].stringValue)
    rec.windBearing = Double(json["windBearing"].stringValue)
    rec.cloudCover = Double(json["cloudCover"].stringValue)
    rec.time = Date(timeIntervalSince1970: TimeInterval(json["time"].intValue))

    return rec
}

func parseBasicDailyData(json: JSON) -> dailyBasicData {
    var rec = dailyBasicData()

    //print(json)
    //For some odd reason json.doubleValue is giving wrong value. Use Swift Double to convert from string.
    
    rec.time = Date(timeIntervalSince1970: TimeInterval(json["time"].intValue))
    rec.icon = json["icon"].stringValue
    rec.summary = json["summary"].stringValue
    rec.uvIndex = json["uvIndex"].intValue
    rec.uvIndexTime = Date(timeIntervalSince1970: TimeInterval(json["uvIndexTime"].intValue))
    rec.windGust = Double(json["windGust"].stringValue)
    rec.windGustTime = Date(timeIntervalSince1970: TimeInterval(json["windGustTime"].intValue))
    rec.windBearing = json["windBearing"].intValue
    rec.precipAccumulation = Double(json["precipAccumulation"].stringValue)
    rec.humidity = Double(json["humidity"].stringValue)
    rec.windSpeed = Double(json["windSpeed"].stringValue)
    rec.temperatureHigh = Double(json["temperatureHigh"].stringValue)
    rec.temperatureHighTime = Date(timeIntervalSince1970: TimeInterval(json["temperatureHighTime"].intValue))
    rec.temperatureLow = Double(json["temperatureLow"].stringValue)
    rec.temperatureLowTime = Date(timeIntervalSince1970: TimeInterval(json["temperatureLowTime"].intValue))
    rec.apparentTemperatureMax = Double(json["apparentTemperatureMax"].stringValue)
    rec.apparentTemperatureMaxTime = Date(timeIntervalSince1970: TimeInterval(json["apparentTemperatureMaxTime"].intValue))
    rec.apparentTemperatureMin = Double(json["apparentTemperatureMin"].stringValue)
    rec.apparentTemperatureMinTime = Date(timeIntervalSince1970: TimeInterval(json["apparentTemperatureMinTime"].intValue))
    rec.ozone = Double(json["ozone"].stringValue)
    rec.dewPoint = Double(json["dewPoint"].stringValue)
    rec.moonPhase = Double(json["moonPhase"].stringValue)
    rec.precipProbability = Double(json["precipProbability"].stringValue)
    rec.precipType = json["precipType"].stringValue
    rec.pressure = Double(json["pressure"].stringValue)
    rec.temperatureMax = Double(json["temperatureMax"].stringValue)
    rec.temperatureMaxTime = Date(timeIntervalSince1970: TimeInterval(json["temperatureMaxTime"].intValue))
    rec.temperatureMin = Double(json["temperatureMin"].stringValue)
    rec.temperatureMinTime = Date(timeIntervalSince1970: TimeInterval(json["temperatureMinTime"].intValue))
    rec.precipIntensity = Double(json["precipIntensity"].stringValue)
    rec.precipIntensityMax = Double(json["precipIntensityMax"].stringValue)
    rec.precipIntensityMaxTime = Date(timeIntervalSince1970: TimeInterval(json["precipIntensityMaxTime"].intValue))
    rec.cloudCover = Double(json["cloudCover"].stringValue)
    rec.apparentTemperatureHigh = Double(json["apparentTemperatureHigh"].stringValue)
    rec.apparentTemperatureHighTime = Date(timeIntervalSince1970: TimeInterval(json["apparentTemperatureHighTime"].intValue))
    rec.apparentTemperatureLow = Double(json["apparentTemperatureLow"].stringValue)
    rec.apparentTemperatureLowTime = Date(timeIntervalSince1970: TimeInterval(json["apparentTemperatureLowTime"].intValue))

    return rec
}

func parseHourlyData(json: JSON) -> hourlyData {
    var hourlyRec = hourlyData()
    
    hourlyRec.summary = json["summary"].stringValue
    hourlyRec.icon = json["icon"].stringValue
    
    let data = json["data"].arrayValue
    for rec in data {
        let basicRec = parseBasicData(json: rec)
        hourlyRec.data.append(basicRec)
    }
    return hourlyRec
}

func parseDailyData(json: JSON) -> dailyData {
    var dailyRec = dailyData()
    
    dailyRec.summary = json["summary"].stringValue
    dailyRec.icon = json["icon"].stringValue
    
    let data = json["data"].arrayValue
    for rec in data {
        let basicDailyRec = parseBasicDailyData(json: rec)
        dailyRec.data.append(basicDailyRec)
    }
    return dailyRec
}


func parseAlertData(json: JSON) -> alertData {
    var rec = alertData()
    
    rec.time = Date(timeIntervalSince1970: TimeInterval(json["time"].intValue))
    rec.description = json["description"].stringValue
    rec.expires = Date(timeIntervalSince1970: TimeInterval(json["expires"].intValue))
    rec.title = json["title"].stringValue
    rec.uri = json["uri"].stringValue
    
    return rec
}

func parseFlagData(json: JSON) -> flagData {
    var rec = flagData()
    
    rec.units = json["units"].stringValue
    
    return rec
}



