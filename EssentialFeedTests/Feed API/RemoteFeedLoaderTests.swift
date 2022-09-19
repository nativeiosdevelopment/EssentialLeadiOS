//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by John on 29/07/2022.
//

import XCTest
import EssentialFeed
import Foundation


class RemoteFeedLoaderTests: XCTestCase {
        
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://www.a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load() { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestDataFromURL() {
        let url = URL(string: "https://www.a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load() { _ in }
        sut.load() { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deiversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "Test", code: 0)
        expect(sut, toCompleteWithResult: failure(.connectivity), when: {
            client.complete(with: clientError)
        })
    }
    
    func test_load_deiversErrorOnNon200Response() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: failure(.invalidData), when: {
                let jsonsData = makeItemJSon([])
                client.complete(withStatusCode: code, data: jsonsData, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: failure(.invalidData), when: {
            let invalidJSON = Data("Invalid JSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoItemOn200HTTPResponseEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let emptyListJSON = makeItemJSon([])

        expect(sut, toCompleteWithResult: .success([])) {
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(id: UUID(),
                              imageURL: URL(string: "http://a-url.com")!)
                
        let item2 = makeItem(id: UUID(),
                             description: "a-description",
                             location: "a-location",
                             imageURL: URL(string: "http://another-url.com")!)
                
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWithResult: .success(items), when: {
            let jsonData = makeItemJSon([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        let url = URL(string: "http://any-url.com")!
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
            
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemJSon([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }
}

private extension RemoteFeedLoaderTests {
    
    // Helpers
    func makeSUT(url: URL = URL(string: "https://www.a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
        
    func makeItemJSon(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { acc, e in
            if let value = e.value {
                acc[e.key] = value
            }
        }
        return (item, json)
    }
    
    func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    class HTTPClientSpy: HTTPClient {

        var requestedURLs: [URL] {
            messages.map { $0.url }
        }

        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
