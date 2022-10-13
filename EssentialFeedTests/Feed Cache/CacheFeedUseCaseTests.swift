//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by John on 28/09/2022.
//

import XCTest
import EssentialFeed


final class CacheFeedUseCaseTests: XCTestCase {
        
    func test_init_doesNotMessageStroreUponCreation() {
        let (_, store) = makeSUT()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.receivedMessages, [] )
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = uniqueItems()
        
        sut.save(items.models , completion: { _ in })
        
        XCTAssertEqual(store.receivedMessages, [.deletedCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = uniqueItems()
        let deletionError = anyNSError()
        
        sut.save(items.models, completion: { _ in })
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deletedCacheFeed])
    }
        
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = uniqueItems()
        let (sut, store) = makeSUT { timestamp }
        
        sut.save(items.models, completion: { _ in })
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deletedCacheFeed, .insert(items.locals, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [Error?]()
        sut?.save(uniqueItems().models) { receivedResults.append($0) }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
}

private extension CacheFeedUseCaseTests {
    
    class FeedStoreSpy: FeedStore {
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        enum ReceivedMessage: Equatable {
            case deletedCacheFeed
            case insert([LocalFeedImage], Date)
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        func deleteCacheFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deletedCacheFeed)
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
        
        func insert(items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
    }
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate )
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void,  file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        var receivedError: Error?
        sut.save(uniqueItems().models) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    func uniqueItems() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let models = [uniqueItem(), uniqueItem()]
        let locals = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        
        return (models, locals)
    }
    
    func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}
