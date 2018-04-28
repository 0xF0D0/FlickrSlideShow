//
//  String.swift
//  FlickrSlideShow
//
//  Created by 김범수 on 2018. 4. 28..
//  Copyright © 2018년 bs. All rights reserved.
//

import Foundation

//TODO: Should I bound check? It'd be safe if bound check can stop termination by exception

extension String {
  private func cut(start: Int, end: Int) -> String.SubSequence {
    let startIndex = self.index(self.startIndex, offsetBy: start)
    let endIndex = self.index(self.startIndex, offsetBy: end)
    
    return self[startIndex...endIndex]
  }
  
  /// Subscript string with x..<y
  subscript(_ sequence: CountableRange<Int>) -> String {
    return String(self.cut(start: sequence.lowerBound, end: sequence.upperBound-1))
  }
  
  /// Subscript string with x...y
  subscript(_ sequence: CountableClosedRange<Int>) -> String {
    return String(self.cut(start: sequence.lowerBound, end: sequence.upperBound))
  }
  
  // Subscript string with x...
  subscript(_ sequence: CountablePartialRangeFrom<Int>) -> String {
    return String(self.cut(start: sequence.lowerBound, end: self.count-1))
  }
  
  // Subscript string with ...x
  subscript(_ sequence: PartialRangeThrough<Int>) -> String {
    return String(self.cut(start: 0, end: sequence.upperBound))
  }
  
}
