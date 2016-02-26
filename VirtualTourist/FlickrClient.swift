//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/14/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation


class FlickrClient: NSObject {
    
    // Shared Session
    var session: NSURLSession
    
    override init () {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // GET Method
    
    func taskForGetMethod (parameters: [String: AnyObject], completionHandler:(result: AnyObject! ,error: NSError?) -> Void ) -> NSURLSessionDataTask {
        
        // Set the parameters
        var mutableParameters = parameters
        
        mutableParameters[UrlKeys.ApiKey] = Constants.ApiKey
        mutableParameters[UrlKeys.Format] = Constants.Format
        mutableParameters[UrlKeys.NoJsonCallBack] = Constants.NoJsonCallBack
        mutableParameters[UrlKeys.Per_page] = Constants.per_page
        
        // Build the URL
        
        let urlString = Constants.BaseUrl + escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        
        let request = NSURLRequest(URL: url)
        
        // Make the request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completionHandler(result: nil, error: error)
                
            } else {
                
                var error: NSError? = nil
                
                // Parse the data
                do {
                    let parsedData: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                    
                    if let error = error {
                        completionHandler(result: nil, error: error)
                        
                    } else {
                        completionHandler(result: parsedData, error: nil)
                    }
                } catch let error1 as NSError {
                    error = error1
                } catch {
                    fatalError()
                }
            }
        }
        
        // Start the request
        task.resume()
        return task
    }
    
    
    // Task Method to download an image from a given string url
    
    func taskForImage (imagePath: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void ) -> NSURLSessionTask {
        
        let url = NSURL(string: imagePath)!
        
        let request = NSURLRequest(URL: url)
        
        //Make the request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completionHandler(imageData: nil, error: error)
                
            } else {
                completionHandler(imageData: data, error: nil)
            }
            
        }
        
        task.resume()
        return task
    }
    
    func storeImage(url: String, completionHandler: (downloaded: DarwinBoolean, error: NSError?) ->  Void) -> Void{
        
        self.taskForImage(url, completionHandler: { imageData,error in
            if let result = imageData {
                
                let fileName = NSURL(fileURLWithPath: url).lastPathComponent
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                let fileURL = NSURL.fileURLWithPathComponents([dirPath, fileName!])
                
                NSFileManager.defaultManager().createFileAtPath(fileURL!.path!, contents: result, attributes: nil)
                
                completionHandler(downloaded: true, error: nil)
                
            }
        })
        
    }
    
    // Remove saved image
    
    func deleteImage(path: String){
        
        var error: NSError? = nil
        
        //Delete it from the document directory
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch let error1 as NSError {
                error = error1
            }
            
            if let error = error {
                print(error)
            }
        }
    }
    
    
    
    //MARK: - Helpers
    
    // Helper function, given a dictionary of parameters, convert to a string for a URL
    func escapedParameters(parameters: [String:AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key,value) in parameters {
            
            let valueString = "\(value)"
            
            let escapedValue = valueString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars.append("\(key)=\(escapedValue!)")
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    //MARK: - SharedInstance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}