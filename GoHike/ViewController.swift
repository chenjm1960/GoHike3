//
//  ViewController.swift
//  GoHike
//
//  Created by James Chen on 5/8/17.
//  Copyright © 2017 jmchen. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class ViewController: UIViewController,CLLocationManagerDelegate {
    
    // constants below are the camera settings
    let distance: CLLocationDistance = 650
    let pitch: CGFloat = 30
    let heading = 90.0
    
    var mapViewType = "Standard"
    var manager = CLLocationManager()
    var totalDistanceMeters2:Double = 0.0
    var preTimeInterval = 0.0
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var updateCount = 0
    var runSpeed: Double = 0.000
    
    // Label for OpenWeatherMap data:
    @IBOutlet weak var citiName: UILabel!
    @IBOutlet weak var tempurature: UILabel!
    @IBOutlet weak var weatherType: UILabel!
    
    // using Progress View for speedBar Display:
    @IBOutlet weak var progressView: UIProgressView! // alternative view for speedbar
    @IBOutlet weak var progressViewDist: UIProgressView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func changeMapType(_ sender: UIButton) {
        
        //mapViewType = "Standard"
        
        let title = sender.titleLabel?.text
        
        switch title!{
        case "Satellite":
            mapView.mapType = .satellite
            sender.setTitle("Hybrid", for: [])
        case "Hybrid":
            mapView.mapType = .hybrid
            sender.setTitle("Standard", for: [])
        case "Standard":
            mapView.mapType = .standard
            sender.setTitle("Satellite", for: [])
        default:
            mapView.mapType = .standard
            sender.setTitle("Sat Fly", for: [])
        }
    }
    // setting for the 3D button
    @IBAction func flyoverMap(_ sender: UIButton) {
        
        let title = sender.titleLabel?.text
        //mapView.mapType = .standard
        switch title!{
        case "Satellite3D":
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
            mapView.mapType = .satelliteFlyover
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "SatelliteFlyover"
            sender.setTitle("Hybrid3D", for: [])
            break
        case "Hybrid3D":
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
            mapView.mapType = .hybridFlyover
            mapView.showsBuildings = true
            mapViewType = "HybridFlyover"
            mapView.setCamera(camera, animated: true)
            sender.setTitle("Standard3D", for: [])
            break
        case "Standard3D":
            let camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: distance, pitch: pitch, heading: heading)
            mapView.mapType = .standard
            mapView.showsBuildings = true
            mapView.setCamera(camera, animated: true)
            mapViewType = "Flyover"
            sender.setTitle("Satellite3D", for: [])
            break
        default:
            mapView.mapType = .standard
            sender.setTitle("Sat Fly", for: [])
            break
        }
        
    }
    
    @IBAction func centerLocation(_ sender: UIButton) {
        
        if let coord = manager.location?.coordinate {
            //
            switch mapViewType {
                case "Standard":
                    let region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000)
                    mapView.setRegion(region, animated: true)
                case "Flyover":
                    let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: heading)
                    mapView.showsBuildings = true
                    mapView.setCamera(camera, animated: true)
                case "SatelliteFlyover":
                    let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: heading)
                    mapView.showsBuildings = true
                    mapView.setCamera(camera, animated: true)
                    mapView.mapType = .satelliteFlyover
                case "HybridFlyover":
                    let camera = MKMapCamera(lookingAtCenter: coord, fromDistance: distance, pitch: pitch, heading: heading)
                    mapView.showsBuildings = true
                    mapView.setCamera(camera, animated: true)
                    mapView.mapType = .hybridFlyover
                default:
                    print("No selection")
            }
        }
    }
    
       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        //manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        // Makes the progressView Bar thicker
        self.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
        self.progressViewDist.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // 1. dist method using (speed * time)
        
        let location = locations[0]
        
        if location.speed >= 0.0 {
            //print("speed (miles/hr)= \(location.speed*(2.236))")
            
            runSpeed = location.speed*(2.236) // converted to miles/hour
            
            // Using iOS Progress View Bar to plot speed instead of CorePlot
            // max speed scale = 12 miles/hr
            progressView.setProgress(Float(runSpeed/10), animated: true)
            
        }
        
        // constants for openweathermap.org to get weather conditions /////////////////
        // call the getWeather function:
        
        let latit = location.coordinate.latitude
        let longit = location.coordinate.longitude
        
        DispatchQueue.main.async {
            self.getWeather(latit: latit, longit: longit)
        }
        
        
        
        /////////////////////////////////////////////////////////////
        
        
        // set map to center and focus on your location
        // use if loop to update map just 5 times
        
        if updateCount < 5 {
            let region = MKCoordinateRegionMakeWithDistance((manager.location?.coordinate)!, 1000, 1000)
            mapView.setRegion(region, animated: false)
            updateCount += 1
        } else {
            manager.startUpdatingLocation()
        }
        
        // 2. dist method using distance between two locations
        if startLocation == nil {
            startLocation = locations.first!
            
        } else {
            let lastLocation = locations.last!
            let distance = startLocation.distance(from: lastLocation)
            var progressBarPercent = 0.0
            if distance > 0.0 {
                
                totalDistanceMeters2 += distance
                //self.totalDistMiles2.text = String(format: "%.4f",(totalDistanceMeters2 * 0.0006214))
                progressBarPercent = ((totalDistanceMeters2 * 0.0006214)/10)
                progressViewDist.setProgress(Float(progressBarPercent), animated: true)
                
            }
            
            startLocation = lastLocation
        }
        
    }
    
    func getWeather(latit:Double,longit:Double) {
        // constants for openweathermap.org to get weather conditions /////////////////
        //
        //print("location = \(location)")
        
        
        // setup for OpenWeatherMap.org using weather API
        // Get location for first 10 updates.
        
        let url = URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(latit)&lon=\(longit)&appid=8c93be12eb4dc96a11f5fffdd66eef37")!
        
        // creating a task from url to get content of url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if error != nil {
                
                // all UI updates should run on main-thread
                DispatchQueue.main.async {
                    print(error!)
                }
                
                
            } else {
                
                // check if we can get data
                if let urlContent = data {
                    
                    // all UI updates should run on main-thread
                    DispatchQueue.main.async {
                        do {
                            
                            // if data exist, process with JSON
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers)
                            
                            // if processing successful, print the swift array with the contents
                            //print(jsonResult)
                            
                            if let cityName = (jsonResult as AnyObject)["name"] {
                                self.citiName.text = cityName as? String
                                //print(cityName!)
                            }
                            
                            
                            if let weatherDict = (jsonResult as AnyObject)["weather"] {
                                // use [AnyObject] Array since it will use subscript [index] = [0]
                                // using just AnyObject will not work, have to define as an array object
                                let weatherCondition = (weatherDict as! [AnyObject])[0]["main"]!!
                                //print(weatherCondition)
                                self.weatherType.text = weatherCondition as? String
                            }
                            
                            
                            // currentTemp: ºF = 1.8 x (K - 273) + 32.
                            
                            if let preTemp = (((jsonResult as AnyObject)["main"]) as! [String:AnyObject])["temp"] {
                                let currentTemp = (1.8 * ((preTemp as! Double) - 273.0)) + 32.0
                                self.tempurature.text = String(describing: currentTemp)
                                //print(currentTemp)
                            }
                            
                        } catch {
                            
                            print("JSON Processing Failed")
                            
                        }
                    }
                    
                }
            }
        }
        
        task.resume()
        
    }
    
}
