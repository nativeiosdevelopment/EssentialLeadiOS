//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by John on 28/09/2022.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCacheFeed()
    }
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
    
    func deleteCacheFeed() {
        deleteCachedFeedCallCount += 1
    }
}

final class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let items = [FeedItem]()
        sut.save(items)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
}

private extension CacheFeedUseCaseTests {
    
    func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}
