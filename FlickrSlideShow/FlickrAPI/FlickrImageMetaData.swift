//
//  FlickrImageMetaData.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import Foundation

struct FlickrImageMetaData {
    let title: String
    let flickrLink: String
    let mediaLink: String
}

extension FlickrImageMetaData: Decodable {
    private enum CodingKeys: CodingKey {
        case title
        case link
        case media
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try values.decode(String.self, forKey: .title)
        self.flickrLink = try values.decode(String.self, forKey: .link)
        self.mediaLink = (try values.decode(FlickrMediaResponse.self, forKey: .media)).mediaLink
    }
}

/**
 This struct is only used for parsing media link from FlickrListResponse(string below).
    ```
    ...
    "media": {"m":"https:\/\/farm1.staticflickr.com\/908\/26884732907_42175628a2_m.jpg"}
    ...
    ```
 */
private struct FlickrMediaResponse {
    let mediaLink: String
}

extension FlickrMediaResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case image = "m"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.mediaLink = try values.decode(String.self, forKey: .image)
    }
}
