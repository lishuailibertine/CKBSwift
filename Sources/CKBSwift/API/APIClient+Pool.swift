//
//  APIClient+Pool.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import PromiseKit

public extension APIClient {
    func sendTransaction(transaction: Transaction) -> Promise<H256> {
        load(APIRequest(method: "send_transaction", params: [transaction.param]))
    }

    func txPoolInfo() -> Promise<TxPoolInfo> {
        load(APIRequest(method: "tx_pool_info", params: []))
    }
}
