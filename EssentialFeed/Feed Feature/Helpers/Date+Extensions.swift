//
//  Date+Extensions.swift
//  EssentialFeed
//
//  Created by John on 20/10/2022.
//

import Foundation

public extension Date {
    
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(second: TimeInterval) -> Date {
        return self + second
    }
}
