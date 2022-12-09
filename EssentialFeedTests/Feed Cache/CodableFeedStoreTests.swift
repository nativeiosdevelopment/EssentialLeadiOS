//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by John on 17/11/2022.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
    override func tearDown() {
        super.tearDown()
        setupEmptyStoreState()
    }
    
    override func setUp() {
        super.setUp()
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // When
        // no insertion
        
        // Then
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // When
        // no insertion
        
        // Then
        assertThatRetrieveHasNoSideEffecsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // Then
        assertThatRetrieveDeliversFoundValueOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // Then
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        // Given
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT()
        
        // When
        try! "invalide data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        // Then
        expect(sut, toRetrieve: .failure(anyNSError()))
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
        
    func test_insert_deliversNoErrorOnEmptyCache() {
        // Given
        let sut = makeSUT()

        // Then
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        // Given
        let sut = makeSUT()

        // Then
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        // Given
        let sut = makeSUT()
        
        // Then
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
                
    func test_insert_deliversErrorOnInsertionError() {
        // Given
        let invalidURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidURL)
        
        // Then
        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        // Given
        let invalidURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidURL)

        // Then
        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // Then
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
        
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        // Given
        let sut = makeSUT()
        
        // Then
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        // Given
        let sut = makeSUT()
                
        // Then
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        // Given
        let sut = makeSUT()
        
        // Then
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() {
//        // Given
//        let noDeletePermissionURL = cachesDirectory()
//        let sut = makeSUT(storeURL: noDeletePermissionURL)
//
//        // When
//        deleteCache(from: sut)
//
//        // Then
//        expect(sut, toRetrieve: .empty)
    }
    
        func test_delete_deliversErrorOnDeletionError() {
    //        // Given
    //        let noDeletePermissionURL = cachesDirectory()
    //        let sut = makeSUT(storeURL: noDeletePermissionURL)
    //
    //        // When
    //        let deletionError = deleteCache(from: sut)
    //
    //        // Then
    //        XCTAssertNotNil(deletionError, "Expected non-empty cache deletion to succeed")
        }
    
    func test_storeSidesEffects_runSerially() {
        // Given
        let sut = makeSUT()
        var completedOperationsInOrder: [XCTestExpectation] = []
        
        // When
        let op1 = expectation(description: "Operation 1")
        sut.insert(feed: uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 1")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(feed: uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        // Then
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order.")
    }
}

private extension CodableFeedStoreTests {
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
