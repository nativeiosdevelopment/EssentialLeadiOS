//
//  Date+Extensions.swift
//  EssentialFeed
//
//  Created by John on 20/10/2022.
//

import Foundation

public extension Date {
    
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }

    func adding(second: TimeInterval) -> Date {
        return self + second
    }
}

private extension Date {
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }

    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}
