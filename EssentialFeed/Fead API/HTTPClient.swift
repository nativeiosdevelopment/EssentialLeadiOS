//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by John on 01/09/2022.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient: AnyObject {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
