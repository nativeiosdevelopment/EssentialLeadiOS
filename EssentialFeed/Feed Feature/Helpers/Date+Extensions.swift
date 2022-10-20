//
//  Date+Extensions.swift
//  EssentialFeed
//
//  Created by John on 20/10/2022.
//

import Foundation

public extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(second: TimeInterval) -> Date {
        return self + second
    }
}
