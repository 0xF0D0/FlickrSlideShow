//
//  FlickrImageQueue.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit

//I want it to be fresh all the time
//HOw?

//filter Bool and if empty go old ones
//and at the same time request must be explicitly made once
//Also! It should maintain it's size atmost 40ish?

//Objective when pouring Rx.
//1. If all image request ends, then be ready to make new request
//2. make two consecutive requests as single observable

final class FlickrImageQueue {
  private var metaDataQueue: [(hasExposed: Bool, metaData: FlickrImageMetaData)] = []
  private var imageCache = NSCache<NSString, UIImage>()
  let maxQueueLength = 40
  var currentIndex = 0
  
  private var exposedList: [(hasExposed: Bool, metaData: FlickrImageMetaData)] {
    return metaDataQueue.filter { $0.hasExposed }
  }
  
  private var freshList: [(hasExposed: Bool, metaData: FlickrImageMetaData)] {
    return metaDataQueue.filter { !$0.hasExposed }
  }
  
  init() {
    imageCache.countLimit = 100
  }
  
  //
  private func requestNewImages() {
    DispatchQueue.global(qos: .background).async {
      
      FlickrImageAPI.shared.listFromPublicFeed { [weak self] response, error in
        guard error == nil,
          let response = response
        else {
          return
        }
        
        response.items.forEach { metaData in
          FlickrImageAPI.shared.image(from: metaData) { image, error in
            guard let image = image
              else { return }
            print("added to \(self!.metaDataQueue.count)")
            self?.imageCache.setObject(image, forKey: metaData.mediaLink.nsString)
            self?.metaDataQueue.append((false, metaData))
          }
        }
        
      }
      
    }
  }
  
  /**
   - important: I think code quality here is not very unsatifying.
   
   Since metaDataQueue gets appended asynchronously, I had to add bound check logic in this function which led to bad readability.
   
   Code cleaning needed
   - returns: New Image and metadata from feed
   */
  func imageWithMetaData() -> (FlickrImageMetaData, UIImage)? {
    if freshList.count < 5 { requestNewImages() }
    if metaDataQueue.isEmpty { return nil }

    let metaData: FlickrImageMetaData
    let image: UIImage
    
    if freshList.isEmpty {
      metaData = exposedList[currentIndex].metaData
      guard let correspondingImage = imageCache.object(forKey: metaData.mediaLink.nsString)
      else { return nil }
      image = correspondingImage
      
      currentIndex = (currentIndex + 1) % exposedList.count
    } else {
      guard let newMetaData = freshList.first?.metaData,
        let correspondingImage = imageCache.object(forKey: newMetaData.mediaLink.nsString)
      else { return nil }
      
      metaData = newMetaData
      image = correspondingImage
      
      metaDataQueue[exposedList.count].hasExposed = true
    }

    if metaDataQueue.count > maxQueueLength {
      removeOldest(decrementIndex: freshList.isEmpty)
    }
    
    return (metaData, image)
  }
  
  private func removeOldest(decrementIndex: Bool) {
    metaDataQueue.removeFirst()
    if decrementIndex {
      currentIndex -= 1
    }
  }
}
