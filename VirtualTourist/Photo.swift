//
//  Photo.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/14/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation
import CoreData
import UIKit



class Photo: NSManagedObject {
    
    struct Keys {
        static let ImagePath = "url_m"
    }
    
    @NSManaged var imagePath: String
    @NSManaged var pin : Pin?
    
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary:[String:AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        if dictionary[Photo.Keys.ImagePath] != nil{
            imagePath = dictionary[Photo.Keys.ImagePath] as! String
        }
        
        
    }
    
    // MARK: - Convenience methods
    func image() -> UIImage?{
        return UIImage(contentsOfFile: self.imageURL())
    }
    
    func imageURL() -> String{
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileURL = NSURL.fileURLWithPathComponents([dirPath, NSURL(fileURLWithPath: self.imagePath).lastPathComponent!])
        return fileURL!.path!
    }
}
