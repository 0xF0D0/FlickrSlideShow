//
//  FlickrImageQueue.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


final class FlickrImageQueue {
  private var freshMetaDataQueue = BehaviorRelay<[FlickrImageMetaData]>(value: [])
  private var oldMetaDataQueue = BehaviorRelay<[FlickrImageMetaData]>(value: [])
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
      .filter{ $0 }
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] _ in
        if self?.oldMetaDataQueue.value.first != nil {
          var oldArray = self?.oldMetaDataQueue.value
          oldArray?.removeFirst()
          
          if let unwrappedOldArray = oldArray {
            self?.oldMetaDataQueue.accept(unwrappedOldArray)
          }
        }
      }).disposed(by: disposeBag)
  }
  
  //Request new images with Rx wrapper!
  private func requestNewImages() {
    FlickrImageAPI.shared.listFromPublicFeed()
      .retryWhen { e in
        e.enumerated().flatMap { attempt, error -> Observable<Int> in
          return Observable<Int>.just(1).delay(1.0, scheduler: MainScheduler.instance)
        }
      }
      .flatMap{ Observable.from($0.items) }
      .flatMap{
        FlickrImageAPI.shared.image(from: $0).catchErrorJustReturn(nil)
      }
      .subscribe(onNext: { [weak self] in
        guard let (metaData, image) = $0 else {return}
        self?.imageCache.setObject(image, forKey: metaData.mediaLink.nsString)
        
        var newArray = self?.freshMetaDataQueue.value
        newArray?.append(metaData)
        if let unwrappedNewArray = newArray {
          self?.freshMetaDataQueue.accept(unwrappedNewArray)
        }
        
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
      
      var oldArray = oldMetaDataQueue.value
      var newArray = freshMetaDataQueue.value
      
      oldArray.append(new)
      newArray.removeFirst()
      
      oldMetaDataQueue.accept(oldArray)
      freshMetaDataQueue.accept(newArray)
    } else if let old = oldMetaDataQueue.value.first,
        let oldImage = imageCache.object(forKey: old.mediaLink.nsString) {
      metaDataImageSubject.on(.next((old, oldImage)))
      
      //rotate the array
      var oldArray = oldMetaDataQueue.value
      oldArray.append(old)
      oldArray.removeFirst()
      oldMetaDataQueue.accept(oldArray)
    }
  }
}
