//
//  SlideViewController.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit
import RxSwift

class SlideViewController: UIViewController {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
  ///Seconds that image has been exposed
  var exposedSeconds = 0
  
  ///Duration of slide show
  var duration = 4
  
  var timer: Timer?
  let imageQueue = FlickrImageQueue()
  let disposeBag = DisposeBag()
  
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    activityIndicator.startAnimating()
    
    imageQueue.metaDataImageObservable
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { metaData, image in
      
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
          }, completion: { (finished) in
            self.timer = Timer.scheduledTimer(timeInterval: 1.0,
                                              target: self,
                                              selector: #selector(self.checkIfTimeHasExceeded),
                                              userInfo: nil, repeats: true)
          })
        }
      }
    }).disposed(by: disposeBag)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  @IBAction func valueChanged(_ sender: UISlider) {
    let sliderValue = lroundf(sender.value)
    
    durationLabel.text = "duration: \(sliderValue+1)"
    duration = sliderValue+1
    
    sender.setValue(Float(sliderValue), animated: false)
  }
  
}

extension SlideViewController {
  
//  @objc private func waitUntilImageIsReady(completion: @escaping () -> Void) {
//    if let (metaData, image) = imageQueue.imageWithMetaData() {
//      DispatchQueue.main.async { [weak self] in
//        self?.titleLabel.text = metaData.title
//        self?.imageView.image = image
//        self?.activityIndicator.stopAnimating()
//        self?.activityIndicator.isHidden = true
//        completion()
//      }
//    } else {
//      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//        self?.waitUntilImageIsReady(completion: completion)
//      }
//    }
//  }
  
  @objc private func checkIfTimeHasExceeded() {
    exposedSeconds += 1
    
    if exposedSeconds >= duration {
      timer?.invalidate()
      exposedSeconds = 0
      imageQueue.triggerOnNext()
    }
  }
  
//  private func animateToNextImage() {
//    exposedSeconds = 0
//
//    UIView.animate(withDuration: 0.5, animations: {
//      self.imageView.alpha = 0
//    }) { finished in
//      if finished {
//        //change image
//
//        guard let (metaData, image) = self.imageQueue.imageWithMetaData()
//        else { return }
//
//        self.activityIndicator.stopAnimating()
//        self.titleLabel.text = metaData.title
//        self.imageView.image = image
//
//        UIView.animate(withDuration: 0.5, animations: {
//          self.imageView.alpha = 1
//        }, completion: { (finished) in
//          self.timer = Timer.scheduledTimer(timeInterval: 1.0,
//                                       target: self,
//                                       selector: #selector(self.checkIfTimeHasExceeded),
//                                       userInfo: nil, repeats: true)
//        })
//      }
//    }
//  }
}
