//
//  AddressGenerator.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import Blake2

// Based on CKB Address Format [RFC](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0021-ckb-address-format/0021-ckb-address-format.md).

public enum AddressPlayloadFormatType: UInt8 {
    case full = 0x00
    case short = 0x01     // short version for locks with popular code_hash
    case fullData = 0x02  // full version with hash_type = "Data"
    case fullType = 0x04  // full version with hash_type = "Type"
}

/// Code hash index for Short Payload Format
public enum AddressCodeHashIndex: UInt8 {
    case secp256k1Blake160 = 0x00
    case secp256k1Multisig = 0x01
    case acp = 0x02
}

/**
 # ref: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0024-ckb-system-script-list/0024-ckb-system-script-list.md
 SCRIPT_CONST_MAINNET = {
     CODE_INDEX_SECP256K1_SINGLE : {
         "code_hash" : "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
         "hash_type" : "type",
         "tx_hash"   : "0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c",
         "index"     : "0",
         "dep_type"  : "dep_group"
     },
     CODE_INDEX_SECP256K1_MULTI : {
         "code_hash" : "0x5c5069eb0857efc65e1bca0c07df34c31663b3622fd3876c876320fc9634e2a8",
         "hash_type" : "type",
         "tx_hash"   : "0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c",
         "index"     : "1",
         "dep_type"  : "dep_group"
     },
     CODE_INDEX_ACP : {
         "code_hash" : "0xd369597ff47f29fbc0d47d2e3775370d1250b85140c670e4718af712983a2354",
         "hash_type" : "type",
         "tx_hash"   : "0x4153a2014952d7cac45f285ce9a7c5c0c0e1b21f2d378b82ac1433cb11c25c4d",
         "index"     : "0",
         "dep_type"  : "dep_group"
     }
 }
 */

/// Nervos CKB Address generator.
/// Currently only the short version lock for SECP256K1 + blake160 is implemented.
/// Format type is 0x01 and code hash index is 0x00.
public class AddressGenerator {
    static func prefix(network: Network) -> String {
        switch network {
        case .testnet:
            return "ckt"
        default:
            return "ckb"
        }
    }

    public static func publicKeyHash(for address: String) -> String? {
        if let data = parse(address: address, type: .BECH32_CONST)?.data{
            return Data(data.bytes.suffix(20)).toHexString()
        }
        if let data = parse(address: address, type: .BECH32M_CONST)?.data{
            return Data(data.bytes.suffix(20)).toHexString()
        }
        return nil
    }

    public static func address(for publicKey: String, network: Network = .mainnet) -> String {
        return address(for: Data(hex: publicKey), network: network)
    }

    public static func address(for publicKey: Data, network: Network = .mainnet) -> String {
        return address(publicKeyHash: hash(for: publicKey), network: network)
    }
    public static func address(publicKeyHash: String, network: Network = .mainnet) -> String {
        return address(publicKeyHash: Data(hex: publicKeyHash), network: network)
    }

    public static func address(publicKeyHash: Data, network: Network = .mainnet) -> String {
        let type = Data([AddressPlayloadFormatType.short.rawValue])
        let codeHashIndex = Data([AddressCodeHashIndex.secp256k1Blake160.rawValue])
        let payload = type + codeHashIndex + publicKeyHash
        return CKBBech32().encode(prefix(network: network), values: convertBits(data: payload, fromBits: 8, toBits: 5, pad: true)!)
    }
    
    public static func addressFull(for publicKey: String, network: Network = .mainnet) -> String {
        return addressFull(for: Data(hex: publicKey), network: network)
    }
    
    public static func addressFull(for publicKey: Data, network: Network = .mainnet) -> String {
        return addressFull(publicKeyHash: hash(for: publicKey), network: network)
    }
    public static func addressFull(publicKeyHash: String, network: Network = .mainnet) -> String {
        return addressFull(publicKeyHash: Data(hex: publicKeyHash), network: network)
    }
    
    /**
     The hash_type field is for CKB VM version selection.

     When the hash_type is 0, the script group matches code via data hash and will run the code using the CKB VM version 0.
     When the hash_type is 1, the script group matches code via type script hash and will run the code using the CKB VM version 1.
     When the hash_type is 2, the script group matches code via data hash and will run the code using the CKB VM version 1.
     */

    public static func addressFull(code_hash: Data = Data(hex: SystemScript.loadSystemScript().secp256k1TypeHash), hash_type: ScriptHashType = .type, publicKeyHash: Data, network: Network = .mainnet) -> String {
        let type = Data([AddressPlayloadFormatType.full.rawValue])
        var hashType: UInt8 = 0x01
        switch hash_type {
        case .data:
            hashType = 0x00
        case .type:
            hashType = 0x01
        case .data1:
            hashType = 0x02
        }
        let payload = type + code_hash  + Data([hashType]) + publicKeyHash
        return CKBBech32().encode(prefix(network: network), values: convertBits(data: payload, fromBits: 8, toBits: 5, pad: true)!, type: .BECH32M_CONST)
    }
    
    public static func hash(for publicKey: Data) -> Data {
        return blake160(publicKey)
    }
}

public extension AddressGenerator {
    static func validate(_ address: String) -> Bool{
        if validate(address, type: .BECH32_CONST){
            return true
        }
        if validate(address, type: .BECH32M_CONST){
            return true
        }
        return false
    }
    static func validate(_ address: String, type: BECH32_CONST_Type) -> Bool {
        guard let (hlp, _) = parse(address: address, type: type) else {
            return false
        }
        return [prefix(network: .mainnet), prefix(network: .testnet)].contains(hlp)
    }
}

private extension AddressGenerator {
    static func parse(address: String, type: BECH32_CONST_Type = .BECH32_CONST) -> (hrp: String, data: Data)? {
        if let parsed = try? CKBBech32().decode(address, type: type){
            if let data = convertBits(data: parsed.checksum, fromBits: 5, toBits: 8, pad: false) {
                let payload = data.bytes
                if payload.count != 22 && payload.count != 54 {
                    return nil
                }
                guard let format = AddressPlayloadFormatType(rawValue: payload[0]) else {
                    return nil
                }
                if format == .short && format == .full{
                    return nil
                }
                return (hrp: parsed.hrp, data: data)
            }
        }

        return nil
    }

    static func blake160(_ data: Data) -> Data {
        return try! Blake2.ckb_hash(message: data).prefix(upTo: 20)
    }

    static func convertBits(data: Data, fromBits: Int, toBits: Int, pad: Bool) -> Data? {
        var ret = Data()
        var acc = 0
        var bits = 0
        let maxv = (1 << toBits) - 1
        for p in 0..<data.count {
            let value = data[p]
            if value < 0 || (value >> fromBits) != 0 {
                return nil
            }
            acc = (acc << fromBits) | Int(value)
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                ret.append(UInt8((acc >> bits) & maxv))
            }
        }
        if pad {
            if bits > 0 {
                ret.append(UInt8((acc << (toBits - bits)) & maxv))
            }
        } else if bits >= fromBits || ((acc << (toBits - bits)) & maxv) > 0 {
            return nil
        }
        return ret
    }
}
