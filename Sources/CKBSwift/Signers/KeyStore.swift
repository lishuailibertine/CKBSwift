//
//  File.swift
//
//
//  Created by li shuai on 2022/9/16.
//

import Foundation
import CryptoSwift
import CryptoScrypt

// Params
extension KeyStore{
    public struct KdfParamsV3: Decodable, Encodable {
        var salt: String
        var dklen: Int
        var n: Int?
        var p: Int?
        var r: Int?
        var c: Int?
        var prf: String?
    }
    public struct CipherParamsV3: Decodable, Encodable {
        var iv: String
    }

    public struct CryptoParamsV3: Decodable, Encodable {
        var ciphertext: String
        var cipher: String
        var cipherparams: CipherParamsV3
        var kdf: String
        var kdfparams: KdfParamsV3
        var mac: String
        var version: String?
    }
    public struct KeystoreParamsV3: Codable {
        public var crypto: CryptoParamsV3
        public var id: String?
        public var version: Int
        public var isHDWallet: Bool?
        public var type: String?
        public init(crypto cr: CryptoParamsV3, id i: String, version ver: Int, type: String? = "private-key") {
            self.crypto = cr
            self.id = i
            self.version = ver
            self.type = type
        }
    }
}
public final class KeyStore{
    public enum KeystoreError: Error {
        case noEntropyError
        case keyDerivationError
        case aesError
        case invalidAccountError
        case invalidPasswordError
        case encryptionError(String)
    }
    public var keystoreParams: KeystoreParamsV3?
    
    public func UNSAFE_getPrivateKeyData(password: String) throws -> Data {
        guard let privateKey = try? self.getKeyData(password) else {
            throw KeystoreError.invalidPasswordError
        }
        return privateKey
    }
    public convenience init?(_ jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        self.init(jsonData)
    }

    public convenience init?(_ jsonData: Data) {
        guard let keystoreParams = try? JSONDecoder().decode(KeystoreParamsV3.self, from: jsonData) else {
            return nil
        }
        self.init(keystoreParams)
    }
    
    public init?(_ keystoreParams: KeystoreParamsV3) {
        if keystoreParams.version != 3 {
            return nil
        }
        if keystoreParams.crypto.version != nil && keystoreParams.crypto.version != "1" {
            return nil
        }
        self.keystoreParams = keystoreParams
    }
    
    public init?(privateKey: Data, password: String = "", aesMode: String = "aes-128-ctr") throws {
        guard privateKey.count == 32 else {
            return nil
        }
        try encryptDataToStorage(password, keyData: privateKey, aesMode: aesMode)
    }
    
    fileprivate func encryptDataToStorage(_ password: String, keyData: Data?, dkLen: Int = 32, N: Int = 262144, R: Int = 8, P: Int = 1, aesMode: String = "aes-128-ctr") throws {
        if keyData == nil {
            throw KeystoreError.encryptionError("Encryption without key data")
        }
        let saltLen = 32
        guard let saltData = Data.randomBytes(length: saltLen) else {
            throw KeystoreError.noEntropyError
        }
        guard let derivedKey = scrypt(password: password, salt: saltData, length: dkLen, N: N, R: R, P: P) else {
            throw KeystoreError.keyDerivationError
        }
        let last16bytes = Data(derivedKey[(derivedKey.count - 16)...(derivedKey.count - 1)])
        let encryptionKey = Data(derivedKey[0...15])
        guard let IV = Data.randomBytes(length: 16) else {
            throw KeystoreError.noEntropyError
        }
        var aesCipher: AES?
        switch aesMode {
        case "aes-128-cbc":
            aesCipher = try? AES(key: encryptionKey.bytes, blockMode: CBC(iv: IV.bytes), padding: .noPadding)
        case "aes-128-ctr":
            aesCipher = try? AES(key: encryptionKey.bytes, blockMode: CTR(iv: IV.bytes), padding: .noPadding)
        default:
            aesCipher = nil
        }
        if aesCipher == nil {
            throw KeystoreError.aesError
        }
        guard let encryptedKey = try aesCipher?.encrypt(keyData!.bytes) else {
            throw KeystoreError.aesError
        }
        let encryptedKeyData = Data(encryptedKey)
        var dataForMAC = Data()
        dataForMAC.append(last16bytes)
        dataForMAC.append(encryptedKeyData)
        let mac = dataForMAC.sha3(.keccak256)
        let kdfparams = KdfParamsV3(salt: saltData.toHexString(), dklen: dkLen, n: N, p: P, r: R, c: nil, prf: nil)
        let cipherparams = CipherParamsV3(iv: IV.toHexString())
        let crypto = CryptoParamsV3(ciphertext: encryptedKeyData.toHexString(), cipher: aesMode, cipherparams: cipherparams, kdf: "scrypt", kdfparams: kdfparams, mac: mac.toHexString(), version: nil)
        let keystoreparams = KeystoreParamsV3(crypto: crypto, id: UUID().uuidString.lowercased(), version: 3)
        self.keystoreParams = keystoreparams
    }
    
    fileprivate func getKeyData(_ password: String) throws -> Data? {
        guard let keystoreParams = self.keystoreParams else {
            return nil
        }
        let saltData = Data(hex: keystoreParams.crypto.kdfparams.salt)
        let derivedLen = keystoreParams.crypto.kdfparams.dklen
        var passwordDerivedKey: Data?
        switch keystoreParams.crypto.kdf {
        case "scrypt":
            guard let N = keystoreParams.crypto.kdfparams.n else {
                return nil
            }
            guard let P = keystoreParams.crypto.kdfparams.p else {
                return nil
            }
            guard let R = keystoreParams.crypto.kdfparams.r else {
                return nil
            }
            passwordDerivedKey = scrypt(password: password, salt: saltData, length: derivedLen, N: N, R: R, P: P)
        case "pbkdf2":
            guard let algo = keystoreParams.crypto.kdfparams.prf else {
                return nil
            }
            var hashVariant: HMAC.Variant?
            switch algo {
            case "hmac-sha256":
                hashVariant = HMAC.Variant.sha2(.sha256)
            case "hmac-sha384":
                hashVariant = HMAC.Variant.sha2(.sha256)
            case "hmac-sha512":
                hashVariant = HMAC.Variant.sha2(.sha256)
            default:
                hashVariant = nil
            }
            guard hashVariant != nil else {
                return nil
            }
            guard let c = keystoreParams.crypto.kdfparams.c else {
                return nil
            }
            guard let passData = password.data(using: .utf8) else {
                return nil
            }
            guard let derivedArray = try? PKCS5.PBKDF2(password: passData.bytes, salt: saltData.bytes, iterations: c, keyLength: derivedLen, variant: hashVariant!).calculate() else {
                return nil
            }
            passwordDerivedKey = Data(derivedArray)
        default:
            return nil
        }
        guard let derivedKey = passwordDerivedKey else {
            return nil
        }
        var dataForMAC = Data()
        let derivedKeyLast16bytes = Data(derivedKey[(derivedKey.count - 16)...(derivedKey.count - 1)])
        dataForMAC.append(derivedKeyLast16bytes)
        let cipherText = Data(hex: keystoreParams.crypto.ciphertext)
        dataForMAC.append(cipherText)
        let mac = dataForMAC.sha3(.keccak256)
        let calculatedMac = Data(hex: keystoreParams.crypto.mac)
        guard mac.constantTimeComparisonTo(calculatedMac) else {
            return nil
        }
        let cipher = keystoreParams.crypto.cipher
        let decryptionKey = derivedKey[0...15]
        let IV = Data(hex: keystoreParams.crypto.cipherparams.iv)
        var decryptedPK: Array<UInt8>?
        switch cipher {
        case "aes-128-ctr":
            guard let aesCipher = try? AES(key: decryptionKey.bytes, blockMode: CTR(iv: IV.bytes), padding: .noPadding) else {
                return nil
            }
            decryptedPK = try aesCipher.decrypt(cipherText.bytes)
        case "aes-128-cbc":
            guard let aesCipher = try? AES(key: decryptionKey.bytes, blockMode: CBC(iv: IV.bytes), padding: .noPadding) else {
                return nil
            }
            decryptedPK = try? aesCipher.decrypt(cipherText.bytes)
        default:
            return nil
        }
        guard decryptedPK != nil else {
            return nil
        }
        return Data(decryptedPK!)
    }

    public func serialize() throws -> Data? {
        guard let params = self.keystoreParams else {
            return nil
        }
        let data = try JSONEncoder().encode(params)
        return data
    }
    private func scrypt (password: String, salt: Data, length: Int, N: Int, R: Int, P: Int) -> Data? {
        guard let passwordData = password.data(using: .utf8) else {return nil}
        var stop: String?
        var status: Int32 = 0
        var deriver = Data(repeating: 0x00, count: 32)
        let _ = deriver.withUnsafeMutableBytes { (deriverBuffPointer) in
            if let serializedPkRawPointer = deriverBuffPointer.baseAddress, deriverBuffPointer.count > 0 {
                let serializedPubkeyPointer = serializedPkRawPointer.assumingMemoryBound(to: UInt8.self)
                let _ =  passwordData.withUnsafeBytes { (unsafeBytes_pass: UnsafeRawBufferPointer) in
                    let bytes_pass = unsafeBytes_pass.bindMemory(to: UInt8.self).baseAddress!
                    salt.withUnsafeBytes { (unsafeBytes_salt: UnsafeRawBufferPointer) in
                        let bytes_salt = unsafeBytes_salt.bindMemory(to: UInt8.self).baseAddress!
                        status = crypto_scrypt(bytes_pass, unsafeBytes_pass.count, bytes_salt, unsafeBytes_salt.count, UInt64(N), UInt32(R), UInt32(P), serializedPubkeyPointer, deriverBuffPointer.count, &stop)
                    }
                }
            }
        }
        if status != 0{return nil}
        return deriver
    }
}
