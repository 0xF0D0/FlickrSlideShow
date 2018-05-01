//
//  FlickrImageQueue.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit
import RxSwift


final class FlickrImageQueue {
  private var freshMetaDataQueue = Variable<[FlickrImageMetaData]>([])
  private var oldMetaDataQueue = Variable<[FlickrImageMetaData]>([])
  private var imageCache = NSCache<NSString, UIImage>()
  private var isInitial = true
  
  private let maxQueueLength = 40
  private let metaDataImageSubject = PublishSubject<(FlickrImageMetaData, UIImage)>()
  private let disposeBag = DisposeBag()
  
  var metaDataImageObservable: Observable<(FlickrImageMetaData, UIImage)> {
    return metaDataImageSubject.asObservable()
  }
  
  private var needsNewRequest: Observable<Bool> {
    return freshMetaDataQueue.asObservable().map{ $0.count < 5}
  }
  
  private var shouldRemoveOldest: Observable<Bool> {
    return oldMetaDataQueue.asObservable().map{ $0.count > self.maxQueueLength }
  }
  
  
  init() {
    imageCache.countLimit = 100
    subscribeToChanges()
  }
  
  private func subscribeToChanges() {
    needsNewRequest.distinctUntilChanged()
      .filter{ $0 }
      .subscribe(onNext: {[weak self] _ in
        self?.requestNewImages()
      }).disposed(by: disposeBag)
    
    shouldRemoveOldest.asObservable()
      .filter{ !$0 }
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] _ in
        if self?.oldMetaDataQueue.value.first != nil {
          self?.oldMetaDataQueue.value.removeFirst()
        }
      }).disposed(by: disposeBag)
  }
  
  //Request new images with Rx wrapper!
  private func requestNewImages() {
    FlickrImageAPI.shared.listFromPublicFeed()
      .retry()
      .flatMap{ Observable.from($0.items) }
      .flatMap{
        FlickrImageAPI.shared.image(from: $0).catchErrorJustReturn(nil)
      }
      .subscribe(onNext: { [weak self] in
        guard let (metaData, image) = $0 else {return}
        self?.imageCache.setObject(image, forKey: metaData.mediaLink.nsString)
        self?.freshMetaDataQueue.value.append(metaData)
        
        //At the very beggining, we should emit image to start timer!
        if self?.isInitial ?? false {
          self?.isInitial = false
          self?.triggerOnNext()
        }
      }).disposed(by: disposeBag)
  }
  
  //Make metaDataImage Observable emit next event
  func triggerOnNext() {
    if let new = freshMetaDataQueue.value.first,
      let newImage = imageCache.object(forKey: new.mediaLink.nsString) {
      metaDataImageSubject.on(.next((new, newImage)))
      
      oldMetaDataQueue.value.append(new)
      freshMetaDataQueue.value.removeFirst()
    } else if let old = oldMetaDataQueue.value.first,
        let oldImage = imageCache.object(forKey: old.mediaLink.nsString) {
      metaDataImageSubject.on(.next((old, oldImage)))
      
      oldMetaDataQueue.value.removeFirst()
    }
  }
}
