//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by John on 01/08/2022.
//

import Foundation


public class RemoteFeedLoader: FeedLoader {
    
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
}

extension RemoteFeedLoader {
    
     public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                completion(RemoteFeedLoader.map(data: data, response: response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}

private extension RemoteFeedLoader {
    static func map( data: Data, response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemsMapper.map(data, from: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image ) }
    }
}
