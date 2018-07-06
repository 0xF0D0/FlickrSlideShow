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
        return Observable<FlickrPublicFeedResponse>.create { observer in
            let disposable = Disposables.create()
            guard let requestURL = URL(string: FlickrURL.publicFeedList)
                else {
                    observer.on(.error(ResponseError.urlInvalid))
                    return disposable
            }
            
            let task = URLSession.shared.dataTask(with: requestURL) { data, _, error in
                guard error == nil,
                    let receivedData = data
                    else {
                        let error = error ?? ResponseError.dataEmpty
                        observer.on(.error(error))
                        return
                }
                
                do {
                    let flickrResponse = try self.flickrResponse(from: receivedData)
                    observer.on(.next(flickrResponse))
                    observer.on(.completed)
                } catch {
                    observer.on(.error(error))
                }
            }
            
            task.resume()
            return disposable
        }
    }
    
    ///Get image from url (Rx version)
    func image(from metaData: FlickrImageMetaData) -> Observable<(FlickrImageMetaData, UIImage)?> {
        return Observable<(FlickrImageMetaData, UIImage)?>.create { observer in
            let disposable = Disposables.create()
            guard let requestURL = URL(string: metaData.mediaLink)
                else {
                    observer.on(.error(ResponseError.urlInvalid))
                    return disposable
            }
            
            let task = URLSession.shared.downloadTask(with: requestURL) { location, _, error in
                guard error == nil,
                    let location = location
                    else {
                        let error = error ?? ResponseError.downloadFailed
                        observer.on(.error(error))
                        return
                }
                
                guard let imageData = FileManager.default.contents(atPath: location.path),
                    let image = UIImage(data: imageData)
                    else {
                        observer.on(.error(ResponseError.imageDecodeFailed))
                        return
                }
                observer.on(.next((metaData, image)))
                observer.on(.completed)
            }
            
            task.resume()
            
            return disposable
        }
    }
    
}
