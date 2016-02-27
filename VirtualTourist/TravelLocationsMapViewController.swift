//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/13/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var viewMap: MKMapView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var deleteTopView: NSLayoutConstraint!
    @IBOutlet weak var mapBottomView: NSLayoutConstraint!
    
    var editCheck: Bool = false
    var longPressGesture: UILongPressGestureRecognizer!
    var addedPin = MKPointAnnotation()
    var selectedPin: Pin!
    let RegionLoc = RegionLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: "longPressed:")
        
        viewMap.addGestureRecognizer(longPressGesture)
        viewMap.delegate = self
        
        // Set the map region to the last region displayed by the user
        if let lastRegionDisplayed = RegionLoc.load() {
            self.viewMap.setRegion(lastRegionDisplayed, animated: true)
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error!!")
        }
        
        fetchedResultsController.delegate = self
        loadPins()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // Convenience lazy context var
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    //MARK: Core Data
    
    func loadPins() {
        let pins = fetchedResultsController.fetchedObjects!
        for pin in pins {
            let p = pin as! Pin
            viewMap.addAnnotation(p)
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    
    @IBAction func editBtnTouchUp(sender: UIBarButtonItem) {
        if editCheck{
            editBtn.title =  "Edit"
            mapBottomView.constant = 0
            deleteTopView.constant = 70
        } else {
            editBtn.title =  "Ok"
            mapBottomView.constant = 70
            deleteTopView.constant = 0
        }
        editCheck = !editCheck
        print(editCheck)
    }
    
    // long pressed handler
    func longPressed(sender: UIGestureRecognizer){
        if editCheck{
            return
        } else {
            var pinCoordinate: CLLocationCoordinate2D{
                let location = viewMap.convertPoint(sender.locationInView(viewMap), toCoordinateFromView: viewMap)
                return location
            }
            
            if sender.state == .Ended {
                print("UIGestureRecognizerStateEnded")
                print("Done")
                let dictionary: [String:AnyObject] = [
                    Pin.Keys.Latitude: Double(pinCoordinate.latitude),
                    Pin.Keys.Longitude: Double(pinCoordinate.longitude)
                ]
                let p = Pin(dictionary: dictionary, context: self.sharedContext)
                
                getLocation(p)
                getImages(p, page: 1)
                viewMap.addAnnotation(p)
                viewMap.removeAnnotation(addedPin)
                CoreDataStackManager.sharedInstance().saveContext()
                
            }
            else if sender.state == .Changed {
                print("UIGestureRecognizerStateChanged.")
                // Changed of Gesture
                
                viewMap.removeAnnotation(addedPin)
                addedPin.coordinate = pinCoordinate
                viewMap.addAnnotation(addedPin)
            } else {
                print("UIGestureRecognizerStateBegan.")
                addedPin.coordinate = pinCoordinate
                viewMap.addAnnotation(self.addedPin)
            }
        }
    }
    
    // get image search from flickr
    
    func getImages(pin: Pin, page: Int) {
        FlickrClient.sharedInstance().getImagesFromFlickrBySearch(searchLongitude: pin.coordinate.longitude, searchLatitude: pin.coordinate.latitude, page: page){
            photos, error in
            dispatch_async(dispatch_get_main_queue(), {
            if let error = error {
                //Handle error
                print(error)
            } else {
                _ = photos?.map() { (dictionary: [String:AnyObject]) -> Photo in
                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                    photo.pin = pin
                    return photo
                }
            }
        })
        }
    }
    
    // get Location of pin from pin address
    
    func getLocation(pin: Pin){
        let clocation = CLLocation(latitude: Double(pin.latitude), longitude: Double(pin.longitude))
        CLGeocoder().reverseGeocodeLocation(clocation) { placemarks, error in
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                return
            }
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                
                if pm.locality != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        _ = PinLocation(pinLocation: pin, Location: pm.locality!, context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showPhotoViewController" )
        {
            let backItem = UIBarButtonItem()
            backItem.title = "Ok"
            navigationItem.backBarButtonItem = backItem
            
            let destinationView = segue.destinationViewController as! PhotoAlbumViewController
            destinationView.pin = self.selectedPin
            
        }
        
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate{
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // Each time the region changes, save it
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // saving your CLLocation object
        RegionLoc.save(mapView.region)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if editCheck{
            if let pinAnnotation = view as? MKPinAnnotationView {
                if let annotation = pinAnnotation.annotation {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.viewMap.removeAnnotation(annotation)
                        self.sharedContext.deleteObject(annotation as! Pin)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
            
        } else {
            selectedPin = view.annotation as! Pin
            performSegueWithIdentifier("showPhotoViewController", sender: self)
            
        }
    }
}

