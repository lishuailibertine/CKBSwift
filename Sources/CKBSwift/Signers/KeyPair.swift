import Foundation
import CryptoSwift
import RIPEMDSwift
import Secp256k1Swift

public enum CKBKeypairError: LocalizedError{
    case NotExpected
    case SignError
    case InvalidSeed
    case InvalidPrivateKey
    case InvalidPublicKey
    case InvalidAddress
    case otherEror(String)
    public var errorDescription: String?{
        switch self {
        case .NotExpected:
            return "Not Expected"
        case .SignError:
            return "Sign Error"
        case .InvalidSeed:
            return "Invalid Seed"
        case .InvalidPrivateKey:
            return "Invalid PrivateKey"
        case .InvalidPublicKey:
            return "Invalid PublicKey"
        case .InvalidAddress:
            return "Invalid Address"
        case .otherEror(let string):
            return string
        }
    }
}

public final class CKBKeyPair {
    public let privateKey: Data
    public let publicKey: Data
    public let chainCode: Data

    private lazy var identifier: Data? = {
        if publicKey.isEmpty {
            return nil
        }
        guard let hash = try? RIPEMD160.hash(message: publicKey.sha256()) else{
            return nil
        }
        return hash
    }()

    public lazy var fingerprint: UInt32 = {
        if let identifier = identifier {
            let bytes = Array(identifier)
            let index = bytes.startIndex
            let val0 = UInt32(bytes[index.advanced(by: 0)]) << 24
            let val1 = UInt32(bytes[index.advanced(by: 1)]) << 16
            let val2 = UInt32(bytes[index.advanced(by: 2)]) << 8
            let val3 = UInt32(bytes[index.advanced(by: 3)])
            return val0 | val1 | val2 | val3
        }
        return 0
    }()
    public var parentFingerprint: UInt32 = 0
    public var index: UInt32 = 0
    public var depth = 0

    public init(privateKey: Data, chainCode: Data) throws {
        self.privateKey = privateKey
        self.chainCode = chainCode
        guard let publickey = SECP256K1.privateToPublic(privateKey: privateKey, compressed: true) else{
            throw CKBKeypairError.InvalidPrivateKey
        }
        publicKey = publickey
    }

    public init(publicKey: Data, chainCode: Data, path: String = "") {
        privateKey = Data()
        self.publicKey = publicKey
        self.chainCode = chainCode

        let pathComponents = path.split(separator: "/")
        if (pathComponents.count > 0) {
            index = UInt32(String(pathComponents.last!.trimmingCharacters(in: ["'"])))!
            depth = pathComponents.count - 1
        }
    }

    public init(hmac: Data) throws {
        privateKey = Data(hmac[0..<32])
        guard let publickey = SECP256K1.privateToPublic(privateKey: privateKey, compressed: true) else{
            throw CKBKeypairError.InvalidPrivateKey
        }
        publicKey = publickey
        chainCode = Data(hmac[32..<64])
    }

    public convenience init(seed: Data) throws{
        let hmac = Self.hmac(key: "Bitcoin seed".data(using: .ascii)!, message: seed)
        try self.init(hmac: hmac)
    }

    public func derivedKeychain(with path: String) throws -> CKBKeyPair? {
        if ["m", "/", ""].contains(path) {
            return self
        }

        var paths = path.components(separatedBy: "/")
        if path.hasPrefix("m") {
            paths.removeFirst()
        }

        var keychain = self

        for part in paths {
            let hardened = part.hasSuffix("'")
            guard let index = UInt32(hardened ? String(part.dropLast()) : part) else {
                return nil
            }

            keychain = try keychain.derivedKeychain(at: index, hardened: hardened)
        }

        return keychain
    }

    public func derivedKeychain(at index: UInt32, hardened: Bool = false) throws -> CKBKeyPair {
        var data = Data()

        if hardened {
            var padding: UInt8 = 0
            data += Data(bytes: &padding, count: MemoryLayout<UInt8>.size)
            data += privateKey
        } else {
            data += publicKey
        }

        var edge = (hardened ? (0x80000000 + index) : index).byteSwapped
        data += Data(bytes: &edge, count: MemoryLayout<UInt32>.size)

        let digest = Self.hmac(key: chainCode, message: data) // i (il, ir)
        let tweak = digest[0..<32]
        let chainCode = digest[32..<64]
        var derivedKeychain: CKBKeyPair
        if privateKey.isEmpty { // neutered
            let pubkey = Secp256k1.shared.pubkeyTweakAdd(publicKey: publicKey, tweak: tweak)!
            derivedKeychain = CKBKeyPair(publicKey: pubkey, chainCode: chainCode)
        } else {
            let seckey = Secp256k1.shared.seckeyTweakAdd(privateKey: privateKey, tweak: tweak)!
            derivedKeychain = try CKBKeyPair(privateKey: seckey, chainCode: chainCode)
        }

        derivedKeychain.index = index
        derivedKeychain.depth = depth + 1
        derivedKeychain.parentFingerprint = fingerprint

        return derivedKeychain
    }
}

private extension CKBKeyPair {
    static func hmac(key: Data, message: Data) -> Data {
        if let hmac = try? HMAC(key: Array(key), variant: .sha512).authenticate(Array(message)) {
            return Data(hmac)
        } else {
            return Data()
        }
    }
}
