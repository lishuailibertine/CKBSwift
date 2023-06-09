//
//  APIClient.swift
//
//  Copyright © 2018 Nervos Foundation. All rights reserved.
//

import Foundation
import PromiseKit

/// JSON RPC API client.
/// Implement CKB [JSON-RPC](https://github.com/nervosnetwork/ckb/tree/develop/rpc#ckb-json-rpc-protocols) interfaces.
public class APIClient {
    private let url: String
    public static let defaultLocalURL = "http://127.0.0.1:8114"

    public init(url: String = APIClient.defaultLocalURL) {
        self.url = url
    }

    public func load<R: Codable>(_ request: APIRequest, _ path: String = "") -> Promise<R> {
        return Promise<R> { [unowned self] resove in
            let req: URLRequest
            do {
                req = try self.createRequest(request, path)
            } catch {
                return resove.reject(error)
            }

            URLSession.shared.dataTask(with: req) { (data, _, err) in
                do {
                    guard let data = data else {
                        return resove.reject(APIError.emptyResponse)
                    }
                    let result = try JSONDecoder().decode(APIResult<R>.self, from: data)
                    if let result = result.result {
                        return resove.fulfill(result)
                    } else {
                        return resove.reject(APIError.emptyResponse)
                    }
                } catch {
                    return resove.reject(APIError.genericError(error.localizedDescription))
                }
            }.resume()
        }
    }

    private func createRequest(_ request: APIRequest, _ path: String = "") throws -> URLRequest {
        guard let url = URL(string: "\(url)\(path)") else{
            throw APIError.invalidUrl
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonObject: Any = [ "jsonrpc": "2.0", "id": request.id, "method": request.method, "params": request.params ]
        if !JSONSerialization.isValidJSONObject(jsonObject) {
            throw APIError.invalidParameters
        }
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        } catch {
            throw APIError.genericError(error.localizedDescription)
        }

        return req
    }
}

extension APIClient {
    public func genesisBlockHash() -> Promise<H256> {
        getBlockHash(number: 0)
    }

    public func genesisBlock() -> Promise<Block> {
        getBlockByNumber(number: 0)
    }
}
