//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Moh abu on 2/14/16.
//  Copyright © 2016 Moh. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
        static let ApiKey = "151c617f9577197bfba58978a2a773b6"
        static let BaseUrl = "https://api.flickr.com/services/rest/"
        static let Format = "json"
        static let NoJsonCallBack = "1"
        static let SearchWidth = 1.0
        static let SearchLenght = 1.0
        static let Url = "url_m"
        static let per_page = 21
    }
    
    struct Method {
        static let SearchPhotos = "flickr.photos.search"
    }
    
    struct UrlKeys {
        static let ApiKey = "api_key"
        static let Format = "format"
        static let NoJsonCallBack = "nojsoncallback"
        static let Bbox = "bbox"
        static let Method = "method"
        static let Extras = "extras"
        static let Per_page = "per_page"
        static let Page = "page"
    }
    
    struct ResponseKeys {
        static let Photos = "photos"
        static let Photo = "photo"
    }

}