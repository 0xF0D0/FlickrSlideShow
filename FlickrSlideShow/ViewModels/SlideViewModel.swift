//
//  SlideViewModel.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 5. 2..
//  Copyright © 2018년 bs. All rights reserved.
//

import RxSwift
import RxCocoa

public class SlideViewState: ReactiveCompatible {
  
  let elapsedSeconds = BehaviorRelay<Int>(value: 0)
  let slideDuration = BehaviorRelay<Int>(value: 0)
  let isAnimating = BehaviorRelay<Bool>(value: false)
  
  init() {
  }
  
  //set cache & make circular queue?
}

class SlideViewModel {
  //states
  let state = SlideViewState()

  private let timer = Observable<Int>.timer(0.0, period: 1.0, scheduler: MainScheduler.instance)
  
  private let imageQueue = FlickrImageQueue()
  private let disposeBag = DisposeBag()
  
  //outputs
  var metaDataImageObservable: Observable<(FlickrImageMetaData, UIImage)> {
    return imageQueue.metaDataImageObservable.asObservable()
  }
  
  init(sliderValue: ControlProperty<Float>) {
    
    sliderValue.map{lroundf($0)}.bind(to: state.slideDuration).disposed(by: disposeBag)
    
    subscribeToChanges()
  }
  
  private func subscribeToChanges() {
    
    timer.withLatestFrom(state.isAnimating)
      .filter{ !$0 }
      .map { [weak self] _ in
        (self?.state.elapsedSeconds.value ?? 0) + 1
      }.bind(to: state.elapsedSeconds)
      .disposed(by: disposeBag)
    
    
    state.elapsedSeconds.distinctUntilChanged()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] seconds in
      guard let duration = self?.state.slideDuration.value
      else {return}
      
      if seconds > duration + 1 {
        
        self?.imageQueue.triggerOnNext()
        self?.state.elapsedSeconds.accept(0)

      }
    }).disposed(by: disposeBag)
  }
  
}
