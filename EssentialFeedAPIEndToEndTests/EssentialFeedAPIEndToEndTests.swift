//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by John on 08/09/2022.
//

import XCTest
import EssentialFeed

class EssentialFeedAPIEndToEndTests: XCTestCase {
    
    func getImage() {
        let session = URLSession(configuration: .default)
        let url = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        session.dataTask(with: url) { (data, response, error) in
            print("error:\(error)")
            print("--------------")
            print("response:\(response)")
            print("--------------")
            print("data:\(data)")
        }.resume()
    }


    func test_endToEndTestServerGetFeedResult_matchesFixedAccountData() {
        let testServerURL = URL(string: "https://essantialdeveloper.com/feed-case-study/test-api/feed")!
//        getImage()
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(client: client, url: testServerURL)

        let exp = expectation(description: "Wait for load completion")

        var receivedResult: LoadFeedResult?

        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)

        switch receivedResult {
        case let .success(items)?:
            XCTAssertEqual(items.count, 8, "Expected  8 items in the test account feed")
        case let .failure(error)?:
            XCTFail("Expected feed result, got \(error) instead")
        default:
            XCTFail("Expected feed result, got no result instead")
        }
    }
    
}
