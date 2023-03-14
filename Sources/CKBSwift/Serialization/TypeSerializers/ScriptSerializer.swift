//
//  ScriptSerializer.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import Blake2

extension ScriptHashType {
    var byte: UInt8 {
        return self == .data ? 0x0 : 0x1
    }
}

public final class ScriptSerializer: TableSerializer<Script> {
    public required init(value: Script) {
        super.init(
            value: value,
            fieldSerializers: [
                Byte32Serializer(value: value.codeHash)!,
                ByteSerializer(value: value.hashType.byte),
                BytesSerializer(value: Data(hex: value.args).bytes)
            ]
        )
    }
}

public extension Script {
    internal var serializer: Serializer {
        return ScriptSerializer(value: self)
    }

    func serialize() -> [UInt8] {
        return serializer.serialize()
    }

    func computeHash() throws -> H256 {
        let serialized = serialize()
        return try Blake2.ckb_hash(message: Data(serialized)).toHexString()
    }

    var hash: H256 {
        return try! computeHash()
    }
}
