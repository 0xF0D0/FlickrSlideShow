//
//  FlickrImageAPI.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxAlamofire

final class FlickrImageAPI {
    static let shared = FlickrImageAPI()
    private init() {}
    
    enum ResponseError: Error {
        case dataEmpty
        case formatWrong
        case urlInvalid
        case downloadFailed
        case imageDecodeFailed
    }
    
    ///Trim the original response string, then decode the FlickrPublicFeedResonse from it.
    private func flickrResponse(from data: Data) throws -> FlickrPublicFeedResponse {
        guard let originalString = String(data: data, encoding: .utf8),
            let jsonData = originalString[15..<originalString.count-1].data(using: .utf8),
            let response = (try? JSONDecoder().decode(FlickrPublicFeedResponse.self, from: jsonData))
            else { throw ResponseError.formatWrong }
        
        return response
    }
    
    ///Get image meta-data list from Flickr public feed (Rx version)
    func listFromPublicFeed() -> Observable<FlickrPublicFeedResponse> {
        return RxAlamofire.requestData(.get, FlickrURL.publicFeedList).map { [weak self] in
            guard let ss = self else { fatalError("FlickrImageAPI is singleton. So it should be always present")}
            return try ss.flickrResponse(from: $0.1)
        }
    }
    
    ///Get image from url (Rx version)
    func image(from metaData: FlickrImageMetaData) -> Observable<(FlickrImageMetaData, UIImage)?> {
        return RxAlamofire.data(.get, metaData.mediaLink).map { imageData -> (FlickrImageMetaData, UIImage)? in
            guard let image = UIImage(data: imageData) else { return nil }
            return (metaData, image)
        }
    }
    
}
