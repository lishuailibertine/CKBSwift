//
//  CellsRequestParams.swift
//  
//
//  Created by li shuai on 2023/3/15.
//

import Foundation

public struct CellsRequestParams: Param{
   
    public let script: Script
    public let script_type: String
    public init(address: String, type: String = "lock") {
        self.script = Script(args: AddressGenerator.publicKeyHash(for: address)!.addHexPrefix(), codeHash: SystemScript.loadSystemScript().secp256k1TypeHash, hashType: .type)
        self.script_type = type
    }

    public var param: [String : Any] {
        let result: [String: Any] = [
            "script": script.param,
            "script_type": script_type
        ]
        return result
    }
}

public struct CellsResponse: Codable{
    public let last_cursor: String
    public let objects: [CellsResponseObject]
}

public struct CellsResponseObject: Codable{
    public let block_number: String
    public let out_point: OutPoint
    public let output: CellOutput
    public let output_data: String
    public let tx_index: String
}
