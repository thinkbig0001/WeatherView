//
//  MainViewController.swift
//  WeatherDemo
//
//  Created by TAPAN BISWAS on 11/28/17.
//  Copyright © 2017 TAPAN BISWAS. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase

//MARK: Golbal parameters and constants
var dataModel: record?

let myNotification = Notification.Name(rawValue:"DataLoaded")

class MainViewController: UIViewController {

    //MARK: Outlets and Actions
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblCurrently: UILabel!
    @IBOutlet weak var lblCurrentTemp: UILabel!
    @IBOutlet weak var lblWeekday: UILabel!
    @IBOutlet weak var lblMaxTemp: UILabel!
    @IBOutlet weak var lblMinTemp: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnCorF: UIButton!
    @IBOutlet weak var lblMessage: UILabel!
    
    @IBAction func toggleCorF(_ sender: UIButton) {
        
    }
    
    @IBOutlet weak var hourDataCollection: UICollectionView!
    
    @IBAction func refresh(_ sender: UIButton) {
        RefreshData()
    }
    
    //MARK: Additional Properties
    var location: CLLocationCoordinate2D?       //To save user's current GPS location
    var locationManager = CLLocationManager()    //Use LocationManager class to get location

    //MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Firebase Analytics
        Analytics.setScreenName("MainScreen", screenClass: "MainViewController")
        Analytics.logEvent("startup", parameters: ["WeatherDemo" : "init"])
        
        //Initialize UI Controls
        initializeUI()
        
        //Retrieve API Key
        
        //Add Notification Observer to handle data loading completion
        let nc = NotificationCenter.default
        nc.addObserver(forName:myNotification, object:nil, queue:nil, using:dataLoaded)

        //Set delegates for tableView
        tableView.delegate = self
        tableView.dataSource = self

        //Set delegate for collectionView
        hourDataCollection.dataSource = self
        hourDataCollection.delegate = self
        
        //Set delegate for LocationManager
        locationManager.delegate = self
        
        //Request User Permission and get user's location
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        //If granted permission and service is enabled
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }

    }

    //MARK: Private functions
    private func initializeUI() {
        
        //Set necessary properties on field, labels and controls.
        btnCorF?.titleLabel?.text = "C/F"
        btnCorF?.isHidden = true
        
        lblMessage?.text = ""
        lblLocation?.text = ""
        lblCurrently?.text = ""
        lblCurrentTemp?.text = ""
        lblWeekday?.text = ""
        lblMaxTemp?.text = ""
        lblMinTemp?.text = ""
        
        hourDataCollection.layer.borderWidth = 2.0
        hourDataCollection.layer.borderColor = UIColor.blue.cgColor
        hourDataCollection.isHidden = true
    }

    @objc private func RefreshData() {
        
        //Check if Location manager has populated the current location else retrive previously saved date
        if let longitude = location?.longitude, let latitude = location?.latitude {
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumFractionDigits = 2
            numberFormatter.maximumFractionDigits = 2
            
            let latStr = numberFormatter.string(for: latitude)
            let longStr = numberFormatter.string(for: longitude)
            let key = getAPIKey()

            //Update Location on the screen
            lblLocation?.text = "Latitude:\(latStr!) : Longitude:\(longStr!)"
            
            //Setup parameters for GET Request
            let param = reqParams(key: key, latitude: latStr!, longitude: longStr!)
            
            //Initiate data load request. Refresh table when notification arrives.
            initiateDataLoadRequest(params: param)
            
            Analytics.logEvent("LoadData", parameters: ["latitude" : latStr!, "longitude" : longStr!])
        } else {
            //Load data from datastore
            return
        }
        
    }

    private func dataLoaded(notification: Notification) {
        guard let _ = notification.userInfo else {
            debugPrint("No userInfo found in notification")
            return
        }
        
        //verify this the correct notification, before taking action
        if notification.name == myNotification && dataModel != nil {
            
            let numberFormatter = NumberFormatter()
            let dateFormatter = DateFormatter()

            //Populate view with data received
            lblCurrently?.text = dataModel?.currently?.precipType
            
            numberFormatter.maximumFractionDigits = 0
            numberFormatter.minimumFractionDigits = 0
            let tempStr = numberFormatter.string(for: dataModel?.currently?.temperature ?? 32)
            lblCurrentTemp?.text = tempStr! + " F"
            
            dateFormatter.dateFormat = "EEEE"
            lblWeekday?.text = dateFormatter.string(from: (dataModel?.daily?.data[0].time)!) + "  Today"
            
            lblMaxTemp?.text = numberFormatter.string(for: dataModel?.daily?.data[0].temperatureMax!)
            lblMinTemp?.text = numberFormatter.string(for: dataModel?.daily?.data[0].temperatureMin!)
            
            //Load the tableView now that we have dataModel filled with data
            tableView.reloadData()
            
            //Load the collectionView with Hourly data
            hourDataCollection.reloadData()
            hourDataCollection.isHidden = false
            
            //set message appropriately
            lblMessage?.text = notification.userInfo?["message"] as! String
        }
        
    }
    
    private func getAPIKey() -> String {
        let apiKey = Bundle.main.infoDictionary!["DarkSkyAPIKey"] as! String
        return apiKey
    }

}

//MARK: Extension to handle LocationManager delegate functions
extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //save the value in MainViewController property
        if let loc = manager.location?.coordinate {
            self.location = loc
            
            //Update location value to show current location
            lblLocation.isHidden = false
            
            lblLocation?.text = "Press the Refresh button to load data"
            lblMessage?.text = "Press the button here ==>"
            lblMessage?.isHidden = false
        } else {
            lblLocation.isHidden = true
        }
        
    }
}
//MARK: Extension to handle tableView delegate/datasource functions
extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    //Necessary functions for basic functionality
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3    //We just have 1 section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0: //Summary Section
            if let _ = dataModel?.daily?.data.count {
                return 1
            } else {
                return 0
            }
            
        case 1: //Forcast Section
            if let dailyRecs = dataModel?.daily?.data.count {
                return dailyRecs
            } else {
                return 0
            }
        case 2: //Detail Section - we want to show 3 rows of data
            if let _ = dataModel?.daily?.data.count {
                return 3
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        ////print(indexPath.section, indexPath.row)
        
        let dateFormatter = DateFormatter()

        let numberFormatter = NumberFormatter()

        switch (indexPath.section) {
        case 0: //Daily Summary
            let cell = tableView.dequeueReusableCell(withIdentifier: "described", for: indexPath) as! DescribedCell
            cell.dailyDescribed?.text = "Forecast: " + (dataModel?.daily?.summary)!
            return cell

        case 1: //Forecast
            let cell = tableView.dequeueReusableCell(withIdentifier: "forecast", for: indexPath) as! ForecastCell
            let dailyRec = dataModel?.daily?.data[indexPath.row]
            
            dateFormatter.dateFormat = "MM/dd EEEE"
            let dateStr = dateFormatter.string(from: (dailyRec?.time)!)
            cell.dayofweek?.text = dateStr
 
            numberFormatter.maximumFractionDigits = 0
            numberFormatter.minimumFractionDigits = 0
            
            let highTemp = numberFormatter.string(for: dailyRec?.temperatureMax!)
            let lowTemp = numberFormatter.string(for: dailyRec?.temperatureMin!)
            
            cell.dayHigh?.text = highTemp
            cell.dayLow?.text = lowTemp
            
            return cell
        case 2: //Details
            let cell = tableView.dequeueReusableCell(withIdentifier: "details", for: indexPath) as! DetailsCell
            switch indexPath.row {
            case 0:
                cell.param1Label?.text = "UV INDEX"
                cell.param2Label?.text = "OZONE"
                
                numberFormatter.maximumFractionDigits = 2
                numberFormatter.minimumFractionDigits = 0
                cell.param1Value?.text = numberFormatter.string(for: (dataModel?.daily?.data[0].uvIndex)!)
                cell.param2Value?.text = numberFormatter.string(for: (dataModel?.daily?.data[0].ozone)!)
                return cell
            case 1:
                cell.param1Label?.text = "HUMIDITY"
                cell.param2Label?.text = "PRESSURE"
                
                numberFormatter.maximumFractionDigits = 0
                numberFormatter.minimumFractionDigits = 0
                cell.param1Value?.text = numberFormatter.string(for: (dataModel?.daily?.data[0].humidity!)! * 100.0)! + " %"
                cell.param2Value?.text = numberFormatter.string(for: dataModel?.daily?.data[0].pressure!)! + " Hg"
                return cell
            case 2:
                cell.param1Label?.text = "WIND SPEED"
                cell.param2Label?.text = "DEW POINT"
                
                numberFormatter.maximumFractionDigits = 0
                numberFormatter.minimumFractionDigits = 0
                cell.param1Value?.text = numberFormatter.string(for: dataModel?.daily?.data[0].windSpeed!)! + " MPH"
                cell.param2Value?.text = numberFormatter.string(for: dataModel?.daily?.data[0].dewPoint!)! + " F"
                return cell
            default:
                return UITableViewCell()
            }
       default:
            return UITableViewCell()
       }
    }
}

//MARK: Extension for CollectionView datasource and delegate
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let _ = dataModel?.hourly?.data.count {
            return 24 //Just show first 24 hours data
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cvcell", for: indexPath) as! HourlyCell
        
        //Display Hours in HR AM/PM format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h a"
        
        let hourStr = dateFormatter.string(from: (dataModel?.hourly?.data[indexPath.row].time)!)
        
        cell.hour?.text = hourStr
        
        //Show weather condition during the hour in condition field.
        cell.condition?.text = dataModel?.hourly?.data[indexPath.row].icon!
        
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.minimumFractionDigits = 0
        
        //Show current temp in hiLowStr for now
        let hilowStr = numberFormatter.string(for: dataModel?.hourly?.data[indexPath.row].temperature!)
        
        cell.hilow?.text = hilowStr
        
        return cell
    }
}
