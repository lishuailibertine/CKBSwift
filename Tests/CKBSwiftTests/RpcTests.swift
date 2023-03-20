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
        
        apiClient.getUnspentCells(address: "ckb1qyqxmxaxqmzyxssfrj07m4898g7qn5rn482sl8mwf4", maxCapacity: BigUInt(8000000000)).done { cells in
            print(cells)
            reqeustExpectation.fulfill()
        }.catch { error in
            print(error)
            reqeustExpectation.fulfill()
        }
//        let cellsResponse = apiClient.getUnspentCells(address: "ckb1qyqxmxaxqmzyxssfrj07m4898g7qn5rn482sl8mwf4", maxCapacity: 8000000000)
//        cellsResponse.sink { completion in
//            if case let .failure(error) = completion{
//                print(error)
//            }
//        } receiveValue: { cells in
//            print(cells)
//        }.store(in: &cancellables)
//
//        apiClient.getCells(cellsParams: CellsRequestParams(address: "ckb1qyqxmxaxqmzyxssfrj07m4898g7qn5rn482sl8mwf4"), last_cursor: nil).sink { completion in
//            if case let .failure(error) = completion{
//                print(error)
//            }
//        } receiveValue: { CellsResponse in
//            print(CellsResponse)
//        }.store(in: &cancellables)

        wait(for: [reqeustExpectation], timeout: 10)
    }
}
