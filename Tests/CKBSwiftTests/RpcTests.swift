//
//  RpcTests.swift
//  
//
//  Created by li shuai on 2023/3/16.
//

import XCTest
import Combine
import BigInt

@testable import CKBSwift

final class RpcTests: XCTestCase {
    let apiClient = APIClient(url: "https://mainnet.ckb.dev")
    var cancellables = Set<AnyCancellable>()
    func testGetCells() async throws {
        let reqeustExpectation = XCTestExpectation(description: #function)
        
        apiClient.getUnspentCells(publicKeyHash: "ckb1qyqxmxaxqmzyxssfrj07m4898g7qn5rn482sl8mwf4", maxCapacity: BigUInt(8000000000), limit: 1).done { cells in
            reqeustExpectation.fulfill()
        }.catch { error in
            print(error)
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 10)
    }
}
