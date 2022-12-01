//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by John on 17/11/2022.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        setupEmptyStoreState()
    }
    
    override func setUp() {
        super.setUp()
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliverEmptyOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // When
        // no insertion
        
        // Then
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // When
        // no insertion
        
        // Then
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliersFoundValuesOnNonEmptyCache() {
        // Given
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        // When
        insert((feed, timestamp), to: sut)

        // Then
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        // Given
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        // When
        insert((feed, timestamp), to: sut)
        
        // Then
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        // Given
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        // When
        try! "invalide data".write(to: storeURL, atomically: false, encoding: .utf8)

        // Then
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSidesEffectsOnFailure() {
        // Given
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        // When
        try! "invalide data".write(to: storeURL, atomically: false, encoding: .utf8)

        // Then
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_retrieve_overridesPreviouslyInsertedCacheValues() {
        // Given
        let sut = makeSUT()
        let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

        // When
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")

        // Then
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        // Given
        let invalidURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidURL)
        let feed = uniqueImageFeed().local
        let timeStamp = Date()

        // When
        let latestInsertionError = insert((feed, timeStamp), to: sut)

        // Then
        XCTAssertNotNil(latestInsertionError, "Expected cache insertion to fail with an error")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // When
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        
        // Then
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        // Given
        let sut = makeSUT()
        
        // When
        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        
        // Then
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        // Given
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        // When
        let deletionError = deleteCache(from: sut)
        
        // Then
        XCTAssertNotNil(deletionError, "Expected non-empty cache deletion to succeed")
    }
}

private extension CodableFeedStoreTests {
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            XCTAssertNil(deletionError, "Expected feed to be deleted successfully")
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(feed: cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedresult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedresult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
                
            case (.empty, .empty),
                (.failure, .failure):
                break

            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(retrieved.feed, expected.feed, file: file, line: line)
                XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)

            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
    
    func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
