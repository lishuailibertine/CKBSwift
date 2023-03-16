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
    func testGetCells() throws {
        let expectation = XCTestExpectation(description: #function)
        
        apiClient.getCells(cellsParams: CellsRequestParams(address: "ckb1qyqxmxaxqmzyxssfrj07m4898g7qn5rn482sl8mwf4"), last_cursor: nil).sink { completion in
            if case let .failure(error)  = completion {
                print(error)
            }
        } receiveValue: { cell in
            print(cell)
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 10)
    }
}
