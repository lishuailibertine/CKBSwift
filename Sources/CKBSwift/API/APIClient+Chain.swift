//
//  APIClient+Chain.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import PromiseKit
import BigInt

public extension APIClient {
    
    func getBlock(hash: H256) -> Promise<Block> {
         load(APIRequest(method: "get_block", params: [hash]))
    }

    func getBlockByNumber(number: BlockNumber) -> Promise<Block> {
         load(APIRequest(method: "get_block_by_number", params: [number.hexString]))
    }

    func getTransaction(hash: H256) -> Promise<TransactionWithStatus> {
         load(APIRequest(method: "get_transaction", params: [hash]))
    }

    func getBlockHash(number: BlockNumber) -> Promise<H256> {
         load(APIRequest(method: "get_block_hash", params: [number.hexString]))
    }

    func getTipHeader() -> Promise<Header> {
         load(APIRequest(method: "get_tip_header"))
    }

    func getHeader(blockHash: H256) -> Promise<Header> {
         load(APIRequest(method: "get_header", params: [blockHash]))
    }

    func getHeaderByNumber(number: BlockNumber) -> Promise<Header> {
         load(APIRequest(method: "get_header_by_number", params: [number.hexString]))
    }

    func getCellsByLockHash(lockHash: H256, from: BlockNumber, to: BlockNumber) -> Promise<[CellOutputWithOutPoint]> {
         load(APIRequest(
            method: "get_cells_by_lock_hash",
            params: [lockHash, from.hexString, to.hexString]
        ))
    }
    
    func getLiveCell(outPoint: OutPoint, withData: Bool = true) -> Promise<CellWithStatus> {
         load(APIRequest(method: "get_live_cell", params: [outPoint.param, withData]))
    }

    func getUnspentCells(address: String, maxCapacity: BigUInt, limit: Capacity = 1) -> Promise<[CellObject]>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                var last_cursor: String?
                var capacity = BigUInt(0)
                var outpoints = [CellObject]()
                while capacity < maxCapacity && last_cursor != "0x" {
                    let response = try self.getCells(cellsParams: CellsRequestParams(address: address), limit: String(limit, radix: 16).addHexPrefix(), last_cursor: last_cursor).wait()
                    last_cursor = response.last_cursor
                    response.objects.forEach { object in
                        capacity = capacity + BigUInt(object.output.capacity)
                    }
                    outpoints.append(contentsOf: response.objects)
                }
                seal.fulfill(outpoints)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func getCells(cellsParams: CellsRequestParams, direction: String = "desc", limit: String = "0x64", last_cursor: String?) -> Promise<CellsResponse> {
         load(APIRequest(method: "get_cells", params: [cellsParams.param, direction, limit, last_cursor]),"/indexer")
    }
    
    func getTipBlockNumber() -> Promise<String> {
         load(APIRequest(method: "get_tip_block_number"))
    }

    func getCurrentEpoch() -> Promise<Epoch> {
         load(APIRequest(method: "get_current_epoch"))
    }

    func getEpochByNumber(number: EpochNumber) -> Promise<Epoch> {
         load(APIRequest(method: "get_epoch_by_number", params: [number.hexString]))
    }

    func getCellbaseOutputCapacityDetails(blockHash: H256) -> Promise<BlockReward> {
         load(APIRequest(method: "get_cellbase_output_capacity_details", params: [blockHash]))
    }
}
