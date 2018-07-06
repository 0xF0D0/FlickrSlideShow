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
    var viewModel: SlideViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SlideViewModel(sliderValue: slider.rx.value)
        
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
            .subscribe(processImage).disposed(by: disposeBag)
        
        viewModel?.state.slideDuration
            .observeOn(MainScheduler.instance)
            .map { Float($0) }
            .bind(to: slider.rx.value)
            .disposed(by: disposeBag)
        
        viewModel?.state.slideDuration
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .map { "duration: \($0+1)" }
            .bind(to: durationLabel.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    private func processImage(event: Event<(FlickrImageMetaData, UIImage)>) {
        
        guard case let .next(metaData, image) = event else {return}
        
        self.viewModel?.state.isAnimating.accept(true)
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
                    self.viewModel?.state.isAnimating.accept(false)
                })
            }
        }
        
    }
}
