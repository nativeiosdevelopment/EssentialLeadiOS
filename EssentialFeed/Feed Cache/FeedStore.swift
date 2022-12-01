//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by John on 10/10/2022.
//

import Foundation

public typealias DeletionCompletion = (Error?) -> Void
public typealias InsertionCompletion = (Error?) -> Void
public typealias RetrievalCompletion = (RetrieveCachedFeedresult) -> Void

public enum RetrieveCachedFeedresult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
