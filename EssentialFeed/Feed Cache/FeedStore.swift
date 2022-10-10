//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by John on 10/10/2022.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion)
    func insert(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}
