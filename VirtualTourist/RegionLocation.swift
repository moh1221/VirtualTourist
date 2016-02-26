//
//  RegionLocation.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/16/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation
import MapKit

class RegionLocation {
    func save(region:MKCoordinateRegion) {
        
        let regionAttr = [
            "centerLat": region.center.latitude,
            "centerLong": region.center.longitude,
            "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
        ]
        
        // saving your CLLocation object
        let locationData = NSKeyedArchiver.archivedDataWithRootObject(regionAttr)
        NSUserDefaults.standardUserDefaults().setObject(locationData, forKey: "locationData")
        
    }
    
    func load()  -> MKCoordinateRegion? {
        // Set the map region to the last region displayed by the user
        if let loadedData = NSUserDefaults.standardUserDefaults().dataForKey("locationData") {
            if let region = NSKeyedUnarchiver.unarchiveObjectWithData(loadedData) as? [String: AnyObject] {
                
                let centerLat = region["centerLat"] as! CLLocationDegrees
                let centerLong = region["centerLong"] as! CLLocationDegrees
                let latitudeDelta = region["latitudeDelta"] as! CLLocationDegrees
                let longitudeDelta = region["longitudeDelta"] as! CLLocationDegrees
                
                let center = CLLocationCoordinate2DMake(centerLat, centerLong)
                let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
                
                return MKCoordinateRegion(center: center, span: span)
            }
        }
        return nil
        
    }
}
