//
//  SlideViewController.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit

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
  
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    timer = Timer.scheduledTimer(timeInterval: 1.0,
                                 target: self,
                                 selector: #selector(checkIfTimeHasExceeded),
                                 userInfo: nil, repeats: true)
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
  @objc private func checkIfTimeHasExceeded() {
    exposedSeconds += 1
    
    if exposedSeconds >= duration {
      timer?.invalidate()
      animateToNextImage()
    }
  }
  
  private func animateToNextImage() {
    exposedSeconds = 0
    
    UIView.animate(withDuration: 0.5, animations: {
      self.imageView.alpha = 0
    }) { finished in
      if finished {
        //change image
        self.imageView.backgroundColor = (self.imageView.backgroundColor ?? UIColor.red) == UIColor.red ?  UIColor.blue : UIColor.red
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
  }
}
