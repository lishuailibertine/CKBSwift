//
//  Secp256k1.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import CSecp256k1

/// Thin wrapper of [C Secp256k1 library](https://github.com/bitcoin-core/secp256k1).
final public class Secp256k1 {
    private let context: OpaquePointer
    public static let shared = Secp256k1()

    private init() {
        context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN) | UInt32(SECP256K1_CONTEXT_VERIFY))!
    }

    deinit {
        secp256k1_context_destroy(context)
    }
    func serializePublicKey(pubkey: UnsafePointer<secp256k1_pubkey>, compressed: Bool = true) -> Data {
        var length = compressed ? 33 : 65
        var data = Data(count: length)
        let flag = compressed ? UInt32(SECP256K1_EC_COMPRESSED) : UInt32(SECP256K1_EC_UNCOMPRESSED)
        data.withUnsafeMutableBytes {
            let mutableBytes = $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
            _ = secp256k1_ec_pubkey_serialize(context, mutableBytes, &length, pubkey, flag)
        }
        return data
    }

    func parsePublicKey(publicKey: Data) -> secp256k1_pubkey? {
        let len = publicKey.count
        guard len == 33 || len == 65 else {
            return nil
        }
        var pub = secp256k1_pubkey()
        let result = secp256k1_ec_pubkey_parse(context, &pub, publicKey.bytes, len)
        return result == 0 ? nil: pub
   }
    
    public func seckeyTweakAdd(privateKey: Data, tweak: Data) -> Data? {
        var data = privateKey
        data.withUnsafeMutableBytes {
            let mutableBytes = $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
            _ = secp256k1_ec_privkey_tweak_add(context, mutableBytes, Array(tweak))
        }
        return data
    }

    public func pubkeyTweakAdd(publicKey: Data, tweak: Data) -> Data? {
        var pubkey = parsePublicKey(publicKey: publicKey)!
        _ = secp256k1_ec_pubkey_tweak_add(context, &pubkey, Array(tweak))
        return serializePublicKey(pubkey: &pubkey, compressed: true)
    }
}
