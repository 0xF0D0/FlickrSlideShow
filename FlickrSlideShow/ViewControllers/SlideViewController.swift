//
//  SlideViewController.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SlideViewController: UIViewController {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var slider: UISlider!
    
  let disposeBag = DisposeBag()
  let isAnimatingRelay = BehaviorRelay(value: true)
  var viewModel: SlideViewModel?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    viewModel = SlideViewModel(isAnimating: isAnimatingRelay.asObservable(),
                               sliderValueChanged: slider.rx.controlEvent(.valueChanged),
                               sliderValue: slider.rx.value)
    
    subscribeToChanges()
    
    activityIndicator.startAnimating()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func subscribeToChanges() {
    viewModel?.metaDataImageObservable
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { metaData, image in
      self.isAnimatingRelay.accept(true)
      UIView.animate(withDuration: 0.5, animations: {
        self.imageView.alpha = 0
      }) { finished in
        if finished {
          //change image
          self.activityIndicator.stopAnimating()
          self.activityIndicator.isHidden = true
          self.titleLabel.text = metaData.title
          self.imageView.image = image
          
          UIView.animate(withDuration: 0.5, animations: {
            self.imageView.alpha = 1
            self.isAnimatingRelay.accept(false)
          })
        }
        }
    }).disposed(by: disposeBag)
    
    viewModel?.sliderValueRelay
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: {[weak self] value in
      let sliderValue = lroundf(value)
      self?.durationLabel.text = "duration: \(sliderValue+1)"
      self?.slider.setValue(Float(sliderValue), animated: false)
    }).disposed(by: disposeBag)
  }
}
