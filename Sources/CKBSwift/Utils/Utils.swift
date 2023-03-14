//
//  Utils.swift
//
//  Copyright © 2018 Nervos Foundation. All rights reserved.
//

import Foundation
import Blake2
public struct Utils {
    public static func prefixHex(_ string: String) -> String {
        return string.hasPrefix("0x") ? string : "0x" + string
    }

    public static func removeHexPrefix(_ string: String) -> String {
        return string.hasPrefix("0x") ? String(string.dropFirst(2)) : string
    }
}

extension Blake2{
    static func ckb_hash(message: Data) throws -> Data{
       return try Blake2.hash(.b2b, size: 32, data: message, persional: "ckb-default-hash".data(using: .utf8))
    }
}
