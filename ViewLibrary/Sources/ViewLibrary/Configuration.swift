//
//  File.swift
//  
//
//  Created by Yang Xu on 2022/11/24.
//

import Foundation

enum Configuration {
    static let titleLengthRange:ClosedRange = 4...50
    static let memoLineLimit:ClosedRange = 10...15
    static let groupTitleMaxLength = 20
}

extension ClosedRange where Bound == Int {
    var rangeDescription:String {
        "\(lowerBound)...\(upperBound)"
    }
}
