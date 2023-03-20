//
//  APIClient+Stats.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import PromiseKit

public extension APIClient {
    func getBlockchainInfo() -> Promise<ChainInfo> {
        load(APIRequest(method: "get_blockchain_info", params: []))
    }

    func getPeersState() -> Promise<[PeerState]> {
        load(APIRequest(method: "get_peers_state", params: []))
    }
}
