//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by John on 08/09/2022.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            guard let data = data, let response = response as? HTTPURLResponse else { return }
            
            completion(.success(data, response))
        }.resume()
    }
}
