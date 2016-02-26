//
//  PinLocation.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/25/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import CoreData

class PinLocation: NSManagedObject {
    @NSManaged var location: String
    @NSManaged var pin : Pin
    
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(pinLocation:Pin, Location: String, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("PinLocation", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        pin = pinLocation
        location = Location
        
    }

}
