//
//  APIClient+Net.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import Combine


public extension APIClient {
    func localNodeInfo() -> Future<Node, APIError> {
        load(APIRequest(method: "local_node_info", params: []))
    }

    func getPeers() -> Future<[Node], APIError> {
        load(APIRequest(method: "get_peers", params: []))
    }
}
