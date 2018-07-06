//
//  FlickrListResponse.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import Foundation

//Formatted Flickr list response
struct FlickrPublicFeedResponse {
    let items: [FlickrImageMetaData]
}

extension FlickrPublicFeedResponse: Decodable {
    private enum CodingKeys: CodingKey {
        case items
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.items = try values.decode([FlickrImageMetaData].self, forKey: .items)
    }
}
