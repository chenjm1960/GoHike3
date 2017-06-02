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
    let distance: CLLocationDistance = 550
    let pitch: CGFloat = 60
    let heading = 0.0
    
    var mapViewType = "Standard"
    var manager = CLLocationManager()
    var totalDistanceMeters2:Double = 0.0
    var preTimeInterval = 0.0
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var updateCount = 0
    var runSpeed: Double = 0.000
    
    // using CorePlot for speedBar Display:
    
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
        
        // Makes the progressView Bar thicker
        self.progressView.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
        self.progressViewDist.transform = CGAffineTransform(scaleX: 1.0, y: 6.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        
        // 1. dist method using (speed * time)
        
        if location.speed >= 0.0 {
            print("speed (miles/hr)= \(location.speed*(2.236))")
            
            runSpeed = location.speed*(2.236) // converted to miles/hour
            
            // Using iOS Progress View Bar to plot speed instead of CorePlot
            // max speed scale = 12 miles/hr
            progressView.setProgress(Float(runSpeed/12), animated: true)
            
        }
        
        
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
            
            if distance > 0.0 {
                
                totalDistanceMeters2 += distance
                
            }
            
            startLocation = lastLocation
        }
        
        //self.totalDistMiles2.text = String(format: "%.4f",(totalDistanceMeters2 * 0.0006214))
        let progressBarPercent = ((totalDistanceMeters2 * 0.0006214)/12)
        progressViewDist.setProgress(Float(progressBarPercent), animated: true)
        
    }
    
}
