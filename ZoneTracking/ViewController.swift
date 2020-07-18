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

class ViewController: UIViewController {
    
    @IBOutlet weak var txt_zone: UILabel!
    @IBOutlet weak var txt_glX: UILabel!
    @IBOutlet weak var txt_glY: UILabel!
    @IBOutlet weak var txt_glZ: UILabel!
    @IBOutlet weak var txt_llX: UILabel!
    @IBOutlet weak var txt_llY: UILabel!
    @IBOutlet weak var txt_llZ: UILabel!
    
    @IBOutlet weak var btn_startStop: UIButton!
    
    let locationManager = CLLocationManager()
    var floorPlan : FloorPlan!
    var beaconRegions = [CLBeaconRegion]()
    var devices = [Device]()
    
    let UPDATE_SECONDS : TimeInterval = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestAlwaysAuthorization()
        
        self.locationManager.delegate = self
        self.floorPlan = FloorPlan(fileName: "FloorPlan", ext: "json")
        
        // extract devices and beaconregions for later use
        for zone in self.floorPlan.zones {
            for device in zone.devices {
                self.devices.append(device)
                self.beaconRegions.append(device.asBeaconRegion())
            }
        }
        
        self.startBeacons()
        self.btn_startStop.layer.cornerRadius = self.btn_startStop.frame.width / 2.0
        
    }
    
    // start region monitoring
    func startBeacons() {
        for beaconRegion in self.beaconRegions {
            //self.locationManager.startMonitoring(for: beaconRegion)
            self.locationManager.startRangingBeacons(in: beaconRegion)
            if #available(iOS 13.0, *) {
                self.locationManager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
        }
    }
    
    // stop region monitoring
    func stopBeacons() {
        for beaconRegion in self.beaconRegions {
            //self.locationManager.stopMonitoring(for: beaconRegion)
            self.locationManager.stopRangingBeacons(in: beaconRegion)
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
            
            if currentTime <= (device.updateTime + self.UPDATE_SECONDS) {
                return true
            }
            else {
                return false
            }
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
        
        let finalBeacons = Array(nearestSortedBeacons[0...2])
        
        Trilaterator.shared.trilaterate(finalBeacons, success: { (pos : SCNVector3! ) in
            
            self.txt_glX.text = "X: \(pos.x)"
            self.txt_glY.text = "Y: \(pos.y)"
            self.txt_glZ.text = "Z: \(pos.z)"
            
            let inZone = self.floorPlan.zones.filter { (zone) -> Bool in
                
                if zone.contains(point: pos) {
                    return true
                }
                else {
                    return false
                }
                
            }.first
            
            if inZone == nil {
                // TODO
                self.txt_zone.text = "Zone: -"
                self.txt_llX.text = "X: -"
                self.txt_llY.text = "Y: -"
                self.txt_llZ.text = "Z: -"
                return
            }
            
            self.txt_zone.text = "Zone: \(inZone!.name!)"
            
            let locX = pos.x -  inZone!.originPt.x
            let locY = pos.y -  inZone!.originPt.y
            let locZ = pos.z -  inZone!.originPt.z
            
            self.txt_llX.text = "X: \(locX)"
            self.txt_llY.text = "Y: \(locY)"
            self.txt_llZ.text = "Z: \(locZ)"
            
        }) { (error) in
            print("Error")
        }
        
    }
    
}

