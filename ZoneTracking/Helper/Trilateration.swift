//
//  Trilateration.swift
//  Locator
//
//  Created by Yasir Iqbal on 29/05/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import UIKit
import SceneKit

class Trilaterator {
    
    static let shared = Trilaterator()
    
    func trilaterate( _ beaconInfo: [Device],
                            success: @escaping (_ location: SCNVector3?) -> Void,
                            failure: @escaping (_ error: Error?) -> Void ) {
        
        if beaconInfo.count != 3 {
            failure( NSError(domain: "At least 3 useful beacons are required", code: 101, userInfo: nil) )
            return
        }
        
        // use always only three beacons / transmits
        let beacon1 = beaconInfo[0]
        let beacon2 = beaconInfo[1]
        let beacon3 = beaconInfo[2]
        
        let latA = CGFloat(beacon1.floorLoc.x)
        let lonA = CGFloat(beacon1.floorLoc.y)
        let distA = CGFloat(beacon1.distance)
        
        let latB = CGFloat(beacon2.floorLoc.x)
        let lonB = CGFloat(beacon2.floorLoc.y)
        let distB = CGFloat(beacon2.distance)
        
        let latC = CGFloat(beacon3.floorLoc.x)
        let lonC = CGFloat(beacon3.floorLoc.y)
        let distC = CGFloat(beacon3.distance)
        
        let P1:[CGFloat] = [lonA, latA, 0]
        let P2:[CGFloat] = [lonB, latB, 0]
        let P3:[CGFloat] = [lonC, latC, 0]
        
        // ex = (P2 - P1)/(numpy.linalg.norm(P2 - P1))
        var ex:[CGFloat] = [0, 0, 0]
        var P2P1: CGFloat = 0
        
        for i in 0..<3 {
            P2P1 += pow(P2[i] - P1[i], 2)
        }
        
        for i in 0..<3 {
            ex[i] = (P2[i] - P1[i]) / sqrt(P2P1)
        }
        
        // i = dot(ex, P3 - P1)
        var p3p1:[CGFloat] = [0, 0, 0]
        
        for i in 0..<3 {
            p3p1[i] = P3[i] - P1[i]
        }
        
        var ivar: CGFloat = 0
        
        for i in 0..<3 {
            ivar += ex[i] * p3p1[i]
        }
        
        // ey = (P3 - P1 - i*ex)/(numpy.linalg.norm(P3 - P1 - i*ex))
        var p3p1i: CGFloat = 0
        
        for i in 0..<3 {
            p3p1i += pow(P3[i] - P1[i] - ex[i] * ivar, 2)
        }
        
        var ey:[CGFloat] = [0, 0, 0]
        
        for i in 0..<3 {
            ey[i] = (P3[i] - P1[i] - ex[i] * ivar) / sqrt(p3p1i)
        }
        
        // ez = numpy.cross(ex,ey)
        // if 2-dimensional vector then ez = 0
        let ez:[CGFloat] = [0, 0, 0]
        
        // d = numpy.linalg.norm(P2 - P1)
        let d = sqrt(P2P1)
        
        // j = dot(ey, P3 - P1)
        var jvar: CGFloat = 0
        
        for i in 0..<3 {
            jvar += ey[i] * p3p1[i]
        }
        
        // from wikipedia
        // plug and chug using above values
        
        let temp = pow(distA, 2) - pow(distB, 2) + pow(d, 2)
        let x:CGFloat = (temp) / (2 * d)
        
        
        let y:CGFloat = ((pow(distA, 2) - pow(distC, 2) + pow(ivar, 2)
            + pow(jvar, 2)) / (2 * jvar)) - ((ivar / jvar) * x);
        
        // only one case shown here
        
        var z1:CGFloat = pow(distA, 2) - pow(x, 2) - pow(y, 2);
        
        // changing to poxitive
        if (z1 < 0) {
            z1 = -z1;
        }
        var z:CGFloat = sqrt(z1);
        
        if z.isNaN {
            z = 0
        }
        
        // triPt is an array with ECEF x,y,z of trilateration point
        // triPt = P1 + x*ex + y*ey + z*ez
        var triPt:[CGFloat] = [ 0, 0, 0 ];
        
        for i in 0..<3 {
            triPt[i] = P1[i] + ex[i] * x + CGFloat(ey[i] * y + ez[i] * z)
        }
        
        // convert back to lat/long from ECEF
        // convert to degrees
        let lon = triPt[0];
        let lat = triPt[1];
        
        success( SCNVector3(lat, lon, z)  )
    }
    
}


