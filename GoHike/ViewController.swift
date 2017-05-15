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
import CorePlot
import Alamofire
import SwiftDate


class ViewController: UIViewController,CLLocationManagerDelegate {
    
    var manager = CLLocationManager()
    var totalDistanceMeters2:Double = 0.0
    var preTimeInterval = 0.0
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var updateCount = 0
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var totalDistMiles2: UILabel!
    
    @IBOutlet weak var totalDist2: UILabel!
    
    @IBAction func changeMapType(_ sender: UIButton) {
        if mapView.mapType == MKMapType.standard {
            mapView.mapType = MKMapType.satelliteFlyover
            
        } else {
            mapView.mapType = MKMapType.standard
        }
    }
    
    @IBAction func flyoverMap(_ sender: UIButton) {
        
        let camera = MKMapCamera()
        camera.centerCoordinate = mapView.centerCoordinate
        camera.pitch = 80.0
        camera.altitude = 200.0
        camera.heading = 45.0
        mapView.showsBuildings = true
        mapView.setCamera(camera, animated: false)
        
    }
    
    @IBAction func centerLocation(_ sender: UIButton) {
        if let coord = manager.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000)
            mapView.setRegion(region, animated: true)
        }
    }
    
       
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        //manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //let location = locations[0]
        
        /*
        // 1. dist method using (speed * time)
        
        if location.speed >= 0.0 {
            
            totalDistanceMeters += Double(location.speed)
            
        }
        self.speedLabel.text = String(location.speed)
        self.totalDist.text = String(totalDistanceMeters)
        self.totalDistMiles.text = String(format: "%.4f",(totalDistanceMeters * 0.0006214))
        */
        
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
        //////////
        
        
        
        self.totalDist2.text = String(format: "%.4f", totalDistanceMeters2)
        self.totalDistMiles2.text = String(format: "%.4f",(totalDistanceMeters2 * 0.0006214))
        
    }
}

