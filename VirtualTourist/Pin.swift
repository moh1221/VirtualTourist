//
//  Pin.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/18/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var photos: [Photo]
    @NSManaged var pinlocation: PinLocation?
    
    var calculatedCoordinate : CLLocationCoordinate2D? = nil
    
    // MARK: - Parameter to fulfill mkkannotation class
    var coordinate: CLLocationCoordinate2D {
        return calculatedCoordinate!
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        calculatedCoordinate = CLLocationCoordinate2DMake(latitude as Double, longitude as Double)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        longitude = dictionary[Pin.Keys.Longitude] as! Double
        latitude = dictionary[Pin.Keys.Latitude] as! Double
        
        self.calculatedCoordinate = CLLocationCoordinate2DMake(latitude as Double, longitude as Double)
        
    }
    
}
