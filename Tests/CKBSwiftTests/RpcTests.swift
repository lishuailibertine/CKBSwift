//
//  RpcTests.swift
//  
//
//  Created by li shuai on 2023/3/16.
//

import XCTest
import Combine
@testable import CKBSwift

final class RpcTests: XCTestCase {
    let apiClient = APIClient(url: "https://mainnet.ckb.dev")
    var cancellables = Set<AnyCancellable>()
    func testGetCells() async throws {
        let reqeustExpectation = XCTestExpectation(description: #function)
        
        apiClient.getUnspentCells(publicKeyHash: "0x6d9ba606c44342091c9fedd4e53a3c09d073a9d5", maxCapacity: 8000000000, limit: 1).done { cells in
            reqeustExpectation.fulfill()
        }.catch { error in
            print(error)
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 10)
    }
}
