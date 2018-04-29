//
//  FlickrImageAPI.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import Foundation
import UIKit

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
  
  ///Get image meta-data list from Flickr public feed
  func listFromPublicFeed(completion: @escaping (FlickrPublicFeedResponse?, Error?) -> Void) {
    guard let requestURL = URL(string: FlickrURL.publicFeedList)
    else { return completion(nil, ResponseError.urlInvalid) }
    
    let task = URLSession.shared.dataTask(with: requestURL) { data, response, error in
      guard error == nil,
        let receivedData = data
      else {
          let error = error ?? ResponseError.dataEmpty
          return completion(nil, error)
      }
      
      do {
        let flickrResponse = try self.flickrResponse(from: receivedData)
        completion(flickrResponse, nil)
      } catch {
        completion(nil, error)
      }
    }
    
    task.resume()
  }
  
  ///Get image from url
  func image(from metaData: FlickrImageMetaData, completion: @escaping (UIImage?, Error?) -> Void) {
    guard let requestURL = URL(string: metaData.mediaLink)
    else { return completion(nil, ResponseError.urlInvalid) }
    
    let task = URLSession.shared.downloadTask(with: requestURL) { (location, _, error) in
      guard error == nil,
        let location = location
      else {
        let error = error ?? ResponseError.downloadFailed
        return completion(nil, error)
      }
      
      guard let imageData = FileManager.default.contents(atPath: location.path),
        let image = UIImage(data: imageData)
      else { return completion(nil, ResponseError.imageDecodeFailed) }
      
      completion(image, nil)
    }
    
    task.resume()
  }
}
