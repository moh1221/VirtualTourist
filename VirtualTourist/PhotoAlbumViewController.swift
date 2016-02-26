//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/14/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import UIKit

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var barBtn: UIBarButtonItem!
    
    var pin: Pin!
    var flickr = FlickrClient()
    var page = 1
    
    // MARK: - Indexes used for the collection view
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error!!")
        }
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setMap()
        setFlowLayout()
        updateNoImagesLabel()
        
        if fetchedResultsController.fetchedObjects!.count == 0 {
            getImages(page)
            selectedIndexes = [NSIndexPath]()
            CoreDataStackManager.sharedInstance().saveContext()
            updateBarBtn()
        }
        
        // set pin location as title
        
        if let info = self.pin.pinlocation?.location {
            self.navigationItem.title = info
        }
    }
    
    //set flow layout
    
    func setFlowLayout() {
        let space: CGFloat = 3.0
        let dimi: CGFloat = (view.frame.size.width - ( space * 2 )) / 3.0
        flowLayout.itemSize = CGSizeMake(dimi, dimi)
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
    }
    
    // Convenience lazy context var
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    @IBAction func loadPhotos(sender: UIBarButtonItem) {
        // MARK: - Bottom button functionality depends if the user has selected some images
        
        if(self.selectedIndexes.count==0){
            page++
            print(page)
            for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                self.sharedContext.deleteObject(photo)
                FlickrClient.sharedInstance().deleteImage(photo.imageURL())
            }
            getImages(page)
        }
        else{
            for index in self.selectedIndexes {
                let photo = self.fetchedResultsController.objectAtIndexPath(index) as! Photo
                self.sharedContext.deleteObject(photo)
                FlickrClient.sharedInstance().deleteImage(photo.imageURL())
            }
            
        }
        
        selectedIndexes = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
        updateBarBtn()
    }
    
    
    func setMap(){
        
        mapView.addAnnotation(pin)
        
        //Set a region
        
        let span = MKCoordinateSpanMake(0.15, 0.15)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // Disable Zoom, scroll and user interaction.
        
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.userInteractionEnabled = false
    }
    
    // Update bar button title
    
    func updateBarBtn() {
        if self.selectedIndexes.count > 0 {
            barBtn.title = "Remove Selected Pictures"
        } else {
            barBtn.title = "New Collection"
        }
    }
    
    func updateNoImagesLabel(){
        if self.fetchedResultsController.fetchedObjects!.count > 0{
            self.noImageLabel.hidden = true
        }else{
            self.noImageLabel.hidden = false
        }
    }
    
    func indicatorUpdate(cell: PhotoCell, value: Bool) -> Void{
        if value {
            let space: CGFloat = 3.0
            let dimi: CGFloat = (view.frame.size.width - ( space * 2 )) / 3.0
            cell.activityView.center = CGPointMake(dimi/2, dimi/2)
            cell.activityView.startAnimating()
            
            cell.activityView.alpha = 1
        } else {
            cell.activityView.stopAnimating()
            cell.activityView.alpha = 0
        }
    }
    
    func getImages(page: Int) {
        FlickrClient.sharedInstance().getImagesFromFlickrBySearch(searchLongitude: self.pin.coordinate.longitude, searchLatitude: self.pin.coordinate.latitude, page: page){
            photos, error in
            dispatch_async(dispatch_get_main_queue(), {
                if let error = error {
                    //Handle error
                    print(error)
                } else {
                    if photos?.count > 0{
                        // map the array of dictionary to photo objects
                        _ = photos?.map() { (dictionary: [String:AnyObject]) -> Photo in
                            let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            photo.pin = self.pin
                            return photo
                        }
                    } else {
                        self.updateNoImagesLabel()
                    }
                }
            })
        }
    }
    
    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.imageView.image = UIImage(named: "Image")!
        cell.activityView.startAnimating()
        indicatorUpdate(cell, value: true)
        
        
        if photo.imagePath != "" {
            
            let photoURL = photo.imagePath
            
            if (NSFileManager.defaultManager().fileExistsAtPath(photo.imageURL()))
            {
                cell.imageView.image = photo.image()
                indicatorUpdate(cell, value: false)
                if (self.selectedIndexes.indexOf(indexPath) != nil) {
                    cell.imageView.alpha = 0.5
                } else {
                    cell.imageView.alpha = 1.0
                }
            }
            else
            {
                FlickrClient.sharedInstance().storeImage(photoURL, completionHandler: { downloaded, error in
                    dispatch_async(dispatch_get_main_queue(), {
                        if(downloaded){
                            self.indicatorUpdate(cell, value: false)
                            
                            if let image = photo.image(){
                                cell.imageView.image = image
                                cell.imageView.alpha = 1.0
                            }else{
                                cell.imageView.image = UIImage(named: "Image")!
                            }
                        }else{
                            cell.imageView.image = UIImage(named: "Image")!
                        }
                    })
                })
            }
        }
    }
    
    // MARK: - Update Cell
    
    func updateCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            cell.imageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.5
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            self.insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            self.deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            self.updatedIndexPaths.append(indexPath!)
            break
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        self.collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: - CollectionView Delegate methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        configureCell(cell, atIndexPath: indexPath)
        updateNoImagesLabel()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Then reconfigure the cell
        updateCell(cell, atIndexPath: indexPath)
        updateNoImagesLabel()
        updateBarBtn()
        
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let objectNumber = self.fetchedResultsController.sections?.count {
            return objectNumber
        }else{
            return 0
        }
    }

}
