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
    struct CenterViews {
        //use in switch functions to control viewtypes
        var mapViewType = "standard"
    }
    
    var centerViews = CenterViews()
    
    var manager = CLLocationManager()
    var totalDistanceMeters2:Double = 0.0
    var preTimeInterval = 0.0
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var updateCount = 0
    var runSpeed: Double = 0.000
    
    // using CorePlot for speedBar Display:
    
    @IBOutlet weak var progressView: UIProgressView! // alternative view for speedbar
    
    @IBOutlet weak var speedBarView: CPTGraphHostingView!
    var propAnnotation: CPTPlotSpaceAnnotation?
    // plot* defines a bar for displaying speed
    var plot1: CPTBarPlot!
    let BarWidth = 0.5
    let BarInitialX = 0.5
    ///////////////////////////
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var totalDistMiles2: UILabel!
    
    @IBAction func changeMapType(_ sender: UIButton) {
        
        centerViews.mapViewType = "standard"
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
    
    @IBAction func flyoverMap(_ sender: UIButton) {
        
        let camera = MKMapCamera()
        camera.centerCoordinate = mapView.centerCoordinate
        camera.pitch = 80.0
        camera.altitude = 150.0
        camera.heading = 45.0
        mapView.showsBuildings = true
        mapView.setCamera(camera, animated: true)
        centerViews.mapViewType = "flyover"
    }
    
    @IBAction func centerLocation(_ sender: UIButton) {
        
        if let coord = manager.location?.coordinate {
            //
            
            switch centerViews.mapViewType {
                
                case "standard":
                    let region = MKCoordinateRegionMakeWithDistance(coord, 1000, 1000)
                    mapView.setRegion(region, animated: true)
                
                case "flyover":
                    let camera = MKMapCamera()
                    camera.centerCoordinate = coord
                    camera.pitch = 80.0
                    camera.altitude = 150.0
                    camera.heading = 45.0
                    mapView.showsBuildings = true
                    mapView.setCamera(camera, animated: false)
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
            progressView.setProgress(Float(runSpeed/12), animated: true)
            // initPlot initiates the CorePlot Bar Chart
            initPlot()
            
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
        //////////
        
        
        
        self.totalDistMiles2.text = String(format: "%.4f",(totalDistanceMeters2 * 0.0006214))
        
    }
    
    ////////////////////// CorePlot Functions /////////////////////
    
    func initPlot() {
        configureHostView()
        configureGraph()
        configureChart()
        configureAxes()
    }
    
    func configureHostView() {
        speedBarView.allowPinchScaling = false
    }
    
    func configureGraph() {
        // 1 - Create the graph
        let graph = CPTXYGraph(frame: speedBarView.bounds)
        graph.plotAreaFrame?.masksToBorder = false
        speedBarView.hostedGraph = graph
        
        
        
        // 2 - Configure the graph
        graph.apply(CPTTheme(named: CPTThemeName.plainWhiteTheme))
        graph.fill = CPTFill(color: CPTColor.clear())
        graph.paddingBottom = 2.0
        graph.paddingLeft = 0.0
        graph.paddingTop = 0.0
        graph.paddingRight = 0.0
        
        // 3 - Set up styles
        let titleStyle = CPTMutableTextStyle()
        titleStyle.color = CPTColor.black()
        titleStyle.fontName = "HelveticaNeue-Bold"
        titleStyle.fontSize = 8.0
        titleStyle.textAlignment = .center
        graph.titleTextStyle = titleStyle
        
        let title = "Speed"
        graph.title = title
        graph.titlePlotAreaFrameAnchor = .top
        graph.titleDisplacement = CGPoint(x: 0.0, y: 16.0)
        
        //Below is to reset the yAxis tick scale for the yAxis data(speed)
        // miles/hour units range
        let axisSet = graph.axisSet as! CPTXYAxisSet
        let y = axisSet.yAxis
        y?.majorIntervalLength = 6
        
        // 4 - Set up plot space
        // Number of data sets
        let xMin = 0.0
        let xMax = Double(1.0)
        // miles/hr range limit
        let yMin = 0.0
        let yMax = 12.0
        
        guard let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return }
        plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
        plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(yMin), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))
        //print("xRange = \(plotSpace.xRange)")
        //print("yRange = \(plotSpace.yRange)")
    }
    
    func configureChart() {
        // 1 - Set up the MW and PSA plots
        // MW & STD
        plot1 = CPTBarPlot()
        plot1.fill = CPTFill(color: CPTColor(componentRed:0.28, green:0.28, blue:0.95, alpha:1.00))
        
        // 2 - Set up line style
        let barLineStyle = CPTMutableLineStyle()
        barLineStyle.lineColor = CPTColor.lightGray()
        barLineStyle.lineWidth = 1.5
        
        // 3 - Add plots to graph
        guard let graph = speedBarView.hostedGraph else { return }
        var barX = BarInitialX
        // MW and PSA plots:
        let plots = [plot1!]
        for plot: CPTBarPlot in plots {
            plot.dataSource = self
            plot.delegate = self
            plot.barWidth = NSNumber(value: BarWidth)
            plot.barOffset = NSNumber(value: barX)
            plot.lineStyle = barLineStyle
            graph.add(plot, to: graph.defaultPlotSpace)
            barX += BarWidth
        }
        
    }
    
    func configureAxes() {
        let axisLineStyle = CPTMutableLineStyle()
        axisLineStyle.lineWidth = 2.0
        axisLineStyle.lineColor = CPTColor.black()
        
        // 2 - Get the MW and PSA graph's axis set
        guard let axisSet = speedBarView.hostedGraph?.axisSet as? CPTXYAxisSet else { return }
        // 3 - Configure the x-axis
        if let xAxis = axisSet.xAxis {
            xAxis.labelingPolicy = .none
            xAxis.majorIntervalLength = 1
            xAxis.axisLineStyle = axisLineStyle
            var majorTickLocations = Set<NSNumber>()
            var axisLabels = Set<CPTAxisLabel>()
            let rates = ["Speed"]
            var tickNum = 0.00
            for (idx, rate) in rates.enumerated() {
                tickNum = tickNum + 0.25
                majorTickLocations.insert(NSNumber(value: idx))
                let label = CPTAxisLabel(text: "\(rate)", textStyle: CPTTextStyle())
                // cannot use idx because x-axis length = 1.50
                // need to use 0, 0.25, 0.5, 0.75, 1.00, so use tickNum values
                label.tickLocation = NSNumber(value: tickNum)
                label.offset = 0.0
                label.alignment = .right
                axisLabels.insert(label)
            }
            xAxis.majorTickLocations = majorTickLocations
            xAxis.axisLabels = axisLabels
        }
    
        // 4 - Configure the y-axis for speed graph:
        if let yAxis = axisSet.yAxis {
            yAxis.labelingPolicy = .fixedInterval
            yAxis.labelOffset = -5.0
            yAxis.minorTicksPerInterval = 3
            yAxis.majorTickLength = 6
            let majorTickLineStyle = CPTMutableLineStyle()
            majorTickLineStyle.lineColor = CPTColor.black().withAlphaComponent(0.4)
            yAxis.majorTickLineStyle = majorTickLineStyle
            yAxis.minorTickLength = 5
            let minorTickLineStyle = CPTMutableLineStyle()
            minorTickLineStyle.lineColor = CPTColor.black().withAlphaComponent(0.20)
            yAxis.minorTickLineStyle = minorTickLineStyle
            yAxis.axisLineStyle = axisLineStyle
        }
    
    }
}

    

extension ViewController: CPTBarPlotDataSource, CPTBarPlotDelegate {
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return 1
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        
        if fieldEnum == UInt(CPTBarPlotField.barTip.rawValue) {
            if plot == plot1 {
                return (runSpeed)
            }
            
        }
        return idx
    }
    
    func barPlot(_ plot: CPTBarPlot, barWasSelectedAtRecord idx: UInt, with event: UIEvent) {
        // 1 - Is the plot hidden?
        if plot.isHidden == true {
            return
        }
        // 2 - Create style, if necessary
        let style = CPTMutableTextStyle()
        style.fontSize = 6.0
        style.fontName = "HelveticaNeue-Bold"
        style.color = CPTColor.magenta()
        
        // 3 - Create annotation
        guard let prop = number(for: plot,
                                field: UInt(CPTBarPlotField.barTip.rawValue),
                                record: idx) as? CGFloat else { return }
        
        propAnnotation?.annotationHostLayer?.removeAnnotation(propAnnotation)
        propAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace!, anchorPlotPoint: [0,0])
        
        
        // 4 - Create number formatter
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        // 5 - Create text layer for annotation
        let propValue = formatter.string(from: NSNumber(cgFloat: prop))
        let textLayer = CPTTextLayer(text: propValue, style: style)
        propAnnotation!.contentLayer = textLayer
        
        // 6 - Get plot index
        var plotIndex: Int = 0
        if plot == plot1 {
            plotIndex = 0
        }
        
        
        // 7 - Get the anchor point for annotation
        let x = CGFloat(idx) + CGFloat(BarInitialX) + (CGFloat(plotIndex) * CGFloat(BarWidth))
        let y = CGFloat(prop) + 0.05
        
        propAnnotation!.anchorPlotPoint = [NSNumber(cgFloat: x), NSNumber(cgFloat: y)]
        
        // 8 - Add the annotation
        guard let plotArea = plot.graph?.plotAreaFrame?.plotArea else { return }
        plotArea.addAnnotation(propAnnotation)
        
    }
    
}
