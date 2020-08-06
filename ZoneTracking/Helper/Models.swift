//
//  Models.swift
//  RealTracking
//
//  Created by Yasir Iqbal on 07/07/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import CoreLocation
import CoreGraphics
import SwiftyJSON

class FloorPlan {
    
    var floorWidth : Double!
    var floorLength : Double!
    var zones = [Zone]()
    
    init(fileName : String, ext : String) {
        
        let bundle = Bundle.main
        
        if let path = bundle.path(forResource: fileName, ofType: ext) {
            if let data = NSData(contentsOfFile: path) {
                
                let json = try! JSON.init(data: data as Data)
                self.floorWidth = json["floorWidth"].doubleValue.toMeters()
                self.floorLength = json["floorLength"].doubleValue.toMeters()
                
                for zone in json["zones"].arrayValue {
                    let newZone = Zone(json: zone)
                    self.zones.append(newZone)
                }
                
            }
        }
    }
}


class Zone {
    
    let zoneID : Int!
    let name : String!
    
    var polygon = [SCNVector3]()
    var originPt : SCNVector3!
    var endPt : SCNVector3!
    
    var width : Double!
    var length : Double!
    var height : Double!
    
    var devices = [Device]()
    
    init(json : JSON) {
        
        self.zoneID = json["zoneID"].intValue
        self.name = json["name"].stringValue
        
        self.height = json["height"].doubleValue.toMeters()
        
        for poly in json["poly"].arrayValue {
            
            let x = poly["x"].doubleValue.toMeters()
            let y = poly["y"].doubleValue.toMeters()
            let z = poly["z"].doubleValue.toMeters()
            
            let pointFloor = SCNVector3(x, y, z)
            self.polygon.append(pointFloor)
            
            let pointRoof = SCNVector3(x + self.height, y + self.height, z + self.height)
            self.polygon.append(pointRoof)
        }
        
        let minXPt = self.polygon.sorted{ $0.x < $1.x }.first
        let maxXPt = self.polygon.sorted{ $0.x > $1.x }.first
        let minYPt = self.polygon.sorted{ $0.y < $1.y }.first
        let maxYPt = self.polygon.sorted{ $0.y > $1.y }.first
        let minZPt = self.polygon.sorted{ $0.z < $1.z }.first
        let maxZPt = self.polygon.sorted{ $0.z > $1.z }.first
        
        self.originPt = SCNVector3(minXPt!.x, minYPt!.y, minZPt!.z)
        self.endPt = SCNVector3(maxXPt!.x, maxYPt!.y, maxZPt!.z)
        
        self.width = Double(self.endPt.x - self.originPt.x)
        self.length = Double(self.endPt.y - self.originPt.y)
        
        for device in json["devices"].arrayValue {
            let newDevice = Device(device: device, zoneOrigin: self.originPt)
            newDevice.zoneID = self.zoneID
            self.devices.append(newDevice)
        }
        
    }
    
    
    func contains(point: SCNVector3) -> Bool {
        
        if point.x >= self.originPt.x && point.x <= self.endPt.x
            && point.y >= self.originPt.y && point.y <= self.endPt.y
            /*&& point.z >= self.originPt.z && point.z <= self.endPt.z*/ {
                return true
        }
        else {
            return false
        }
        
    }
    
}


class Device {
    
    let ENVIRONMENT_CONSTANT : Double = 2.0
    
    // to be filled
    var zoneID : Int!
    let deviceID : Int!
    let tag : String!
    let uuid : UUID!
    let majorValue : NSNumber!
    let minorValue : NSNumber!
    let regionLoc : SCNVector3!
    var floorLoc : SCNVector3!
    
    let power : Double!
    
    var beacon : CLBeacon? {
        didSet {
            if self.beacon?.rssi != nil {
                let rssi = abs(self.beacon!.rssi)
                if rssi > 110 {
                    return
                }
                self.rssi_queue.insert(element: rssi)
                self.updateTime = Date().timeIntervalSince1970
            }
            else {
                self.rssi_queue.reset()
            }
        }
    }
    
    let rssi_queue = Queue<Int>(length: 1)
    
    var updateTime : TimeInterval!
    
    var avg_rssi : Double {
        get {
            var sum : Int = 0
            for value in self.rssi_queue.list {
                sum += value
            }
            if self.rssi_queue.list.count == 0 {
                return 0
            }
            else {
                return Double(sum) / Double(self.rssi_queue.list.count)
            }
        }
    }
    
    var distance : Double {
        get {
            return pow(10 , ( (self.power - self.avg_rssi ) / (10.0 * self.ENVIRONMENT_CONSTANT) ))
        }
    }
    
    init(device : JSON, zoneOrigin : SCNVector3) {
        
        self.deviceID = device["deviceID"].intValue
        self.tag = device["tag"].stringValue
        self.uuid = UUID(uuidString: device["uuid"].stringValue)
        self.majorValue = NSNumber(value: device["major"].intValue)
        self.minorValue = NSNumber(value: device["minor"].intValue)
        self.power = device["power"].doubleValue
        
        let x = device["x"].doubleValue.toMeters()
        let y = device["y"].doubleValue.toMeters()
        let z = device["z"].doubleValue.toMeters()
        self.regionLoc = SCNVector3(x, y, z)
        
        let floorX = self.regionLoc.x + zoneOrigin.x
        let floorY = self.regionLoc.y + zoneOrigin.y
        let floorZ = self.regionLoc.z + zoneOrigin.z
        self.floorLoc = SCNVector3(floorX, floorY, floorZ)
        
    }
    
    func asBeaconRegion() -> CLBeaconRegion {
        let major = CLBeaconMajorValue(exactly: self.majorValue)
        let minor = CLBeaconMinorValue(exactly: self.minorValue)
        
        if #available(iOS 13.0, *) {
            let region = CLBeaconRegion(uuid: self.uuid!, major: major!, minor: minor!, identifier: self.tag!)
            return region
        }
        else {
            // Fallback on earlier versions
            return CLBeaconRegion(proximityUUID: self.uuid!, major: major!, minor: minor!, identifier: self.tag!)
        }
    }
    
}


class Queue<T> {
    var list = [T]()
    var length : Int!
    
    init(length: Int) {
        self.length = length
    }
    
    func insert(element: T) {
        list.append(element)
        if list.count > 10 {
            list.remove(at: 0)
        }
    }
    
    func reset() {
        self.list.removeAll()
    }
    
}
