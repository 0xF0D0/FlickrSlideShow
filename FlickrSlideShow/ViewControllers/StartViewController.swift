//
//  StartViewController.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
  
  @IBOutlet weak var startButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpUI()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func setUpUI() {
    startButton.layer.cornerRadius = 5.0
  }
  
}

