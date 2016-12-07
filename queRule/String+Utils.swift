//
//  String+Utils.swift
//  queRule
//
//  Created by Timple Soft on 02/12/16.
//  Copyright © 2016 TimpleSoft. All rights reserved.
//

import Foundation

extension String {
    
    func indexOf(target: String) -> Int? {
        if let range = self.range(of: target){
            return distance(from: self.startIndex, to: range.lowerBound)
        }
        return nil
    }
    
}
