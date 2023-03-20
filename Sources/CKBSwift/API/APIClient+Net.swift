//
//  APIClient+Net.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import PromiseKit

public extension APIClient {
    func localNodeInfo() -> Promise<Node> {
        load(APIRequest(method: "local_node_info", params: []))
    }

    func getPeers() -> Promise<[Node]> {
        load(APIRequest(method: "get_peers", params: []))
    }
}
