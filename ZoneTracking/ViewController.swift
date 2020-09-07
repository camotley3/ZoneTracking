//
//  ViewController.swift
//  RealTracking
//
//  Created by Yasir Iqbal on 07/07/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation
import MessageUI
import RealmSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var txt_zone: UILabel!
    @IBOutlet weak var txt_glX: UILabel!
    @IBOutlet weak var txt_glY: UILabel!
    @IBOutlet weak var txt_glZ: UILabel!
    @IBOutlet weak var txt_llX: UILabel!
    @IBOutlet weak var txt_llY: UILabel!
    @IBOutlet weak var txt_llZ: UILabel!
    
    @IBOutlet weak var view_container: UIView!
    @IBOutlet weak var btn_startStop: UIButton!
    
    @IBOutlet weak var view_sliderX: UISlider!
    @IBOutlet weak var view_sliderY: UISlider!
    @IBOutlet weak var view_sliderZ: UISlider!
    
    @IBOutlet weak var lbl_width: UILabel!
    @IBOutlet weak var lbl_length: UILabel!
    @IBOutlet weak var lbl_height: UILabel!
    
    @IBOutlet weak var lbl_count: UILabel!
    
    let realm = try! Realm()
    
    let view_marker : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.heightAnchor.constraint(equalToConstant: 16).isActive = true
        view.backgroundColor = UIColor.red
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    let locationManager = CLLocationManager()
    var floorPlan : FloorPlan!
    var beaconRegions = [CLBeaconRegion]()
    var devices = [Device]()
    var deviceID : String!
    let UPDATE_SECONDS : TimeInterval = 5
    
    lazy var exportView : ExportView = {
        let exv = ExportView()
        exv.translatesAutoresizingMaskIntoConstraints = false
        exv.isHidden = true
        exv.layer.borderColor = UIColor.blue.cgColor
        exv.layer.borderWidth = 1
        exv.vc = self
        return exv
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.delegate = self
        
        /*
         self.floorPlan = FloorPlan(fileName: "FloorPlanHome", ext: "json")
         self.view_container.subviews.first?.isHidden = true
         self.view_container.backgroundColor = UIColor.gray
         self.view_container.widthAnchor.constraint(equalTo: self.view_container.heightAnchor, multiplier: 21.0/18.0).isActive = true
        */
        
        self.floorPlan = FloorPlan(fileName: "FloorPlan", ext: "json")
        self.view_container.widthAnchor.constraint(equalTo: self.view_container.heightAnchor, multiplier: 780.0/1180.0).isActive = true
        
        
        // extract devices and beaconregions for later use
        for zone in self.floorPlan.zones {
            for device in zone.devices {
                self.devices.append(device)
                self.beaconRegions.append(device.asBeaconRegion())
            }
        }
        
        self.btn_startStop.layer.cornerRadius = self.btn_startStop.frame.width / 2.0
        
        self.view_marker.isHidden = true
        self.view_container.addSubview(self.view_marker)
        
        self.view_sliderX.value = 0
        self.view_sliderY.value = 0
        self.view_sliderZ.value = 0
        self.view_sliderX.maximumValue = Float(self.floorPlan.zones[0].width)
        self.view_sliderY.maximumValue = Float(self.floorPlan.zones[0].length)
        self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[0].height)
        
        self.view.addSubview(self.exportView)
        self.exportView.widthAnchor.constraint(equalTo: self.exportView.heightAnchor, multiplier: 1).isActive = true
        self.exportView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 8).isActive = true
        self.exportView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8).isActive = true
        self.exportView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
    }
    
    // start region monitoring
    func startBeacons() {
        
        for beaconRegion in self.beaconRegions {
            if #available(iOS 13.0, *) {
                self.locationManager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
            else {
                self.locationManager.startRangingBeacons(in: beaconRegion)
            }
        }
        
        DispatchQueue.main.async {
            self.showBeacons()
        }
    }
    
    
    var markers = [UIView]()
    var isBeaconShown = false
    
    func showBeacons() {
        
        if self.isBeaconShown == true {
            return
        }
        
        self.isBeaconShown = true
        
        for device in self.devices {
            
            let marker = UIView()
            marker.translatesAutoresizingMaskIntoConstraints = false
            self.markers.append(marker)
            self.view_container.addSubview(marker)
            marker.backgroundColor = UIColor.blue
            marker.widthAnchor.constraint(equalToConstant: 8).isActive = true
            marker.heightAnchor.constraint(equalToConstant: 8).isActive = true
            marker.layer.cornerRadius = 4
            
            let totalWidth = CGFloat(self.floorPlan.floorWidth)
            let totalLength = CGFloat(self.floorPlan.floorLength)
            let ratioWidth = CGFloat(device.floorLoc.x) / CGFloat(totalWidth)
            let ratioLength = CGFloat(device.floorLoc.y) / CGFloat(totalLength)
            let finalWidth = (1 - ratioWidth) * self.view_container.frame.width
            let finalLength = ratioLength * self.view_container.frame.height
            
            DispatchQueue.main.async {
                marker.center = CGPoint(x: finalWidth, y: finalLength)
                marker.setNeedsLayout()
            }
        }
    }
    
    // stop region monitoring
    func stopBeacons() {
        
        for beaconRegion in self.beaconRegions {
            if #available(iOS 13.0, *) {
                self.locationManager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
            else {
                self.locationManager.stopRangingBeacons(in: beaconRegion)
            }
        }
    }
    
    func compareDevice( device: Device, beacon : CLBeacon ) -> Bool {
        
        if device.uuid == beacon.proximityUUID && device.majorValue == beacon.major && device.minorValue == beacon.minor {
            return true
        }
        return false
    }
    
    
    var isStarted = false
    @IBAction func btn_startStop(_ sender: UIButton) {
        if self.isStarted == false {
            self.isStarted = true
            self.startBeacons()
            self.btn_startStop.setTitle("Stop", for: .normal)
        }
        else {
            self.isStarted = false
            self.stopBeacons()
            self.btn_startStop.setTitle("Start", for: .normal)
        }
    }
    
    
    var selectedZone = 0
    @IBAction func btn(_ sender: UISegmentedControl) {
        
        self.lbl_width.text = "X: 0"
        self.lbl_length.text = "Y: 0"
        self.lbl_height.text = "Z: 0"
        
        if sender.selectedSegmentIndex == 0 {
            
            self.selectedZone = 0
            if self.isStarted == true {
                self.btn_startStop(UIButton())
            }
            
            self.view_sliderX.value = 0
            self.view_sliderY.value = 0
            self.view_sliderZ.value = 0
            self.view_sliderX.maximumValue = Float(self.floorPlan.zones[0].width)
            self.view_sliderY.maximumValue = Float(self.floorPlan.zones[0].length)
            self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[0].height)
        }
        else if sender.selectedSegmentIndex == 1 {
            
            self.selectedZone = 1
            if self.isStarted == true {
                self.btn_startStop(UIButton())
            }
            
            self.view_sliderX.value = 0
            self.view_sliderY.value = 0
            self.view_sliderZ.value = 0
            self.view_sliderX.maximumValue = Float(self.floorPlan.zones[1].width)
            self.view_sliderY.maximumValue = Float(self.floorPlan.zones[1].length)
            self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[1].height)
        }
        else if sender.selectedSegmentIndex == 2 {
            
            self.selectedZone = 2
            if self.isStarted == true {
                self.btn_startStop(UIButton())
            }
            self.view_sliderX.value = 0
            self.view_sliderY.value = 0
            self.view_sliderZ.value = 0
            self.view_sliderX.maximumValue = Float(self.floorPlan.zones[2].width)
            self.view_sliderY.maximumValue = Float(self.floorPlan.zones[2].length)
            self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[2].height)
        }
        
    }
    
    
    @IBAction func btn_export(_ sender: UIButton) {
        
        if self.isStarted == true {
            self.btn_startStop(UIButton())
        }
        
        self.exportView.isHidden = false
        
        let rows = self.realm.objects(LogRow.self)
        
        let totalSamples : Double = Double(rows.count)
        var trackedSamples : Double! = 0
        var unTrackedSamples : Double! = 0
        
        for row in rows {
            if row.tzone == row.zzone {
                trackedSamples += 1
            }
            else {
                unTrackedSamples += 1
            }
        }
        
        let percTracked = (trackedSamples / totalSamples) * 100
        let percUnTracked = (unTrackedSamples / totalSamples) * 100
        
        var deltaXSum : Double! = 0
        var deltaYSum : Double! = 0
        var deltaZSum : Double! = 0
        var deltaCount : Double! = 0
        
        for row in rows {
            
            guard let xz = Double(row.xz) else {
                continue
            }
            guard let yz = Double(row.yz) else {
                continue
            }
            guard let zz = Double(row.zz) else {
                continue
            }
            
            deltaXSum += abs(xz - row.x)
            deltaYSum += abs(yz - row.y)
            deltaZSum += abs(zz - row.z)
            
            deltaCount += 1
        }
        
        let deltaAVGX = deltaXSum / deltaCount
        let deltaAVGY = deltaYSum / deltaCount
        let deltaAVGZ = deltaZSum / deltaCount
        
        let finalString = "Total Samples: \(totalSamples) \nTracked Samples: \(trackedSamples!) - Perc: \(percTracked) \nUntracked Samples: \(unTrackedSamples!) - Perc:\(percUnTracked) \n\n Delta-Count:\(deltaCount) \nAVG-Delta-X: \(deltaAVGX) \nAVG-Delta-Y: \(deltaAVGY)\nAVG-Delta-Z: \(deltaAVGZ)"
        self.exportView.txtInfo.text = finalString
        
    }
    
    
    func export() {
        
        var finalString = ""
        finalString.append("sn,deviceID,time,zone,tzone,b1Tag,b2Tag,b3Tag,b1r,b2r,b3r,b1d,b2d,b3d,x,y,z,xz,yz,zz,xg,yg,zg\n")
        
        let rows = self.realm.objects(LogRow.self)
        
        for row in rows {
            
            finalString.append("\(row.sn),")
            finalString.append("\(row.deviceID),")
            finalString.append("\(row.time),")
            
            finalString.append("\(row.zzone),")
            finalString.append("\(row.tzone),")
            
            finalString.append("\(row.b1Tag),")
            finalString.append("\(row.b2Tag),")
            finalString.append("\(row.b3Tag),")
            
            finalString.append("\(row.b1r),")
            finalString.append("\(row.b2r),")
            finalString.append("\(row.b3r),")
            
            finalString.append("\(row.b1d),")
            finalString.append("\(row.b2d),")
            finalString.append("\(row.b3d),")
            
            finalString.append("\(row.x),")
            finalString.append("\(row.y),")
            finalString.append("\(row.z),")
            
            finalString.append("\(row.xz),")
            finalString.append("\(row.yz),")
            finalString.append("\(row.zz),")
            
            finalString.append("\(row.xg),")
            finalString.append("\(row.yg),")
            finalString.append("\(row.zg)")
            
            finalString.append("\n")
            
        }
        
        let df = DateFormatter()
        df.dateFormat = "dd-mm___hh-mm"
        let dateString = df.string(from: Date())
        
        // export
        let fileName = "logs - \(dateString)"
        let docDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        if let fileURL = docDirectory?.appendingPathComponent(fileName).appendingPathExtension("csv") {
            do {
                try finalString.write(to: fileURL, atomically: true, encoding: .utf8)
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
                self.present(activityVC, animated: true, completion: nil)
                
            } catch let error as NSError {
                print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }
        }
        
    }
    
    
    @IBAction func seg_width(_ sender: UISlider) {
        self.lbl_width.text = "X: \(sender.value)"
    }
    
    @IBAction func seg_length(_ sender: UISlider) {
        self.lbl_length.text = "Y: \(sender.value)"
    }
    
    @IBAction func seg_height(_ sender: UISlider) {
        self.lbl_height.text = "Z: \(sender.value)"
    }
    
}


extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("rangingBeaconsDidFailFor", error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
    }
    
    @available(iOS 13.0, *)
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        self.updateBeacons(beacons: beacons)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.updateBeacons(beacons: beacons)
    }
    
    func updateBeacons( beacons : [CLBeacon] ) {
        
        for clBeacon in beacons {
            let detectedDevices = self.devices.filter { (device) -> Bool in
                if self.compareDevice(device: device, beacon: clBeacon) {   // devices in beacon above
                    return true
                }
                else {
                    return false
                }
            }
            
            for device in detectedDevices {
                device.beacon = clBeacon
            }
        }
        
        // get latest updated devices in 5 seconds
        let currentTime = Date().timeIntervalSince1970
        let currentDevices = self.devices.filter { (device) -> Bool in
            if device.updateTime == nil {
                return false
            }
            if currentTime >= (device.updateTime + self.UPDATE_SECONDS) {
                return false
            }
            return true
        }
        
        // filtering out beacons with nearest distance
        let nearestSortedBeacons = currentDevices.sorted { $0.distance < $1.distance }
        
        if nearestSortedBeacons.count < 3 {
            self.txt_zone.text = "Devices < 3"
            self.txt_llX.text = "X: -"
            self.txt_llY.text = "Y: -"
            self.txt_llZ.text = "Z: -"
            return
        }
        
        // 3 unique nearest beacons
        var finalBeacons = [Device]()
        for beacon in nearestSortedBeacons {
            var isInFinal = false
            for finalBeacon in finalBeacons {
                if finalBeacon.uuid == beacon.uuid  && finalBeacon.majorValue == beacon.majorValue && finalBeacon.minorValue == beacon.minorValue {
                    isInFinal = true
                }
            }
            if isInFinal == false {
                finalBeacons.append(beacon)
            }
            if finalBeacons.count == 3 {
                break
            }
        }
        
        
        Trilaterator.shared.trilaterate(finalBeacons, success: { (global : SCNVector3! ) in
            
            let newRow = LogRow()
            
            self.txt_glX.text = "X: \(global.x)"
            self.txt_glY.text = "Y: \(global.y)"
            self.txt_glZ.text = "Z: \(global.z)"
            
            newRow.sn = self.realm.objects(LogRow.self).count
            newRow.deviceID = self.deviceID!
            newRow.time = Date().timeIntervalSince1970
            newRow.zzone = "\(self.selectedZone + 1)"
            
            let inZone = self.floorPlan.zones.filter { (zone) -> Bool in
                if zone.contains(point: global) {
                    return true
                }
                else {
                    return false
                }
            }.first
            
            if inZone == nil {
                self.txt_zone.text = "Zone: -"
                self.txt_llX.text = "X: -"
                self.txt_llY.text = "Y: -"
                self.txt_llZ.text = "Z: -"
                
                newRow.tzone  = "-"
                newRow.xz = "-"
                newRow.yz = "-"
                newRow.zz = "-"
                
            }
            else {
                
                self.txt_zone.text = "Zone: \(inZone!.name!)"
                let locX = global.x -  inZone!.originPt.x
                let locY = global.y -  inZone!.originPt.y
                let locZ = global.z -  inZone!.originPt.z
                self.txt_llX.text = "X: \(locX)"
                self.txt_llY.text = "Y: \(locY)"
                self.txt_llZ.text = "Z: \(locZ)"
                
                newRow.tzone = "\(inZone!.zoneID!)"
                newRow.xz = "\(locX)"
                newRow.yz = "\(locY)"
                newRow.zz = "\(locZ)"
            }
            
            newRow.b1Tag = "\(finalBeacons[0].deviceID!)"
            newRow.b2Tag = "\(finalBeacons[1].deviceID!)"
            newRow.b3Tag = "\(finalBeacons[2].deviceID!)"
            
            newRow.b1r = finalBeacons[0].avg_rssi
            newRow.b2r = finalBeacons[1].avg_rssi
            newRow.b3r = finalBeacons[2].avg_rssi
            
            newRow.b1d = finalBeacons[0].distance
            newRow.b2d = finalBeacons[1].distance
            newRow.b3d = finalBeacons[2].distance
            
            newRow.x = Double(self.view_sliderX.value)
            newRow.y = Double(self.view_sliderY.value)
            newRow.z = Double(self.view_sliderZ.value)
            
            newRow.xg = Double(global.x)
            newRow.yg = Double(global.y)
            newRow.zg = Double(global.z)
            
            try! self.realm.write {
                self.realm.add(newRow)
            }
            
            self.lbl_count.text = "\(newRow.sn)"
            
            if global.x.isNaN || global.y.isNaN || global.z.isNaN {
                
            }
            else {
                self.setPosition(pos: global)
            }
            
        }) { (error) in
            print("Trilateration Error")
        }
        
    }
    
    
    func setPosition(pos : SCNVector3!) {
        self.view_marker.isHidden = false
        let totalWidth = CGFloat(self.floorPlan.floorWidth)
        let totalLength = CGFloat(self.floorPlan.floorLength)
        let ratioWidth = CGFloat(pos.x) / CGFloat(totalWidth)
        let ratioLength = CGFloat(pos.y) / CGFloat(totalLength)
        let finalWidth = CGFloat( (1 - ratioWidth) * self.view_container.frame.width)
        let finalLength = CGFloat(ratioLength * self.view_container.frame.height)
        self.view_marker.center = CGPoint(x: finalWidth , y: finalLength )
        self.view_marker.setNeedsLayout()
        
    }
    
    
}

