//
//  SlideViewModel.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 5. 2..
//  Copyright © 2018년 bs. All rights reserved.
//

import RxSwift
import RxCocoa

class SlideViewModel {
  //inputs
  private let isAnimatingRelay = BehaviorRelay<Bool>(value: true)
  private let sliderEventSubject = PublishSubject<Void>()
  
  //states
  private let durationRelay = BehaviorRelay<Int>(value: 4)
  private let exposedSecondsRelay = BehaviorRelay<Int>(value: 0)
  private let timer = Observable<Int>.timer(0.0, period: 1.0, scheduler: MainScheduler.instance)
  
  private let imageQueue = FlickrImageQueue()
  private let disposeBag = DisposeBag()
  
  //outputs
  let sliderValueRelay = BehaviorRelay<Float>(value: 4)
  var metaDataImageObservable: Observable<(FlickrImageMetaData, UIImage)> {
    return imageQueue.metaDataImageObservable.asObservable()
  }
  
  init(isAnimating: Observable<Bool>,
       sliderValueChanged: ControlEvent<()>,
       sliderValue: ControlProperty<Float>) {
    
    
    isAnimating.bind(to: isAnimatingRelay).disposed(by: disposeBag)
    sliderValueChanged.bind(to: sliderEventSubject).disposed(by: disposeBag)
    sliderValue.bind(to: sliderValueRelay).disposed(by: disposeBag)
    
    subscribeToChanges()
  }
  
  private func subscribeToChanges() {
    
    timer.withLatestFrom(isAnimatingRelay)
      .filter{ !$0 }
      .subscribe(onNext: { [weak self] _ in
        self?.exposedSecondsRelay.accept((self?.exposedSecondsRelay.value ?? 0) + 1)
    }).disposed(by: disposeBag)
    
    exposedSecondsRelay.distinctUntilChanged()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] seconds in
      guard let duration = self?.durationRelay.value
      else {return}
      
      if seconds > duration {
        self?.imageQueue.triggerOnNext()
        self?.exposedSecondsRelay.accept(0)
      }
    }).disposed(by: disposeBag)
    
    sliderValueRelay.map{ lroundf($0) }
      .distinctUntilChanged()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] value in
        self?.durationRelay.accept(value+1)
        self?.sliderValueRelay.accept(Float(value))
    }).disposed(by: disposeBag)

  }
}
