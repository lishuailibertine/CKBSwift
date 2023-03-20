//
//  Payment.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation
import Secp256k1Swift
import PromiseKit
import BigInt

public final class Payment {
    public static let minAmount = Capacity(61 * 100_000_000) // Assuming output data is `0x` and algorithm is the default Secp256k1

    private let fromPublicKeyHash: String
    private let toPublicKeyHash: String
    private let amount: Capacity
    private let fee: Capacity

    private let apiClient: APIClient

    public var signedTx: Transaction?
    
    public init(from: String, to: String, amount: Capacity, fee: Capacity = 1000, apiClient: APIClient) throws {
        guard let fromHash = AddressGenerator.publicKeyHash(for: from) else {
            throw Error.invalidFromAddress
        }
        fromPublicKeyHash = fromHash
        guard let toHash = AddressGenerator.publicKeyHash(for: to) else {
            throw Error.invalidToAddress
        }
        toPublicKeyHash = toHash

        guard amount >= Payment.minAmount else {
            throw Error.insufficientAmount
        }
        self.amount = amount

        self.fee = fee

        self.apiClient = apiClient
    }

    @discardableResult
    public func sign(privateKey: Data) -> Promise<Transaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise) {
                let pubKeyHash = AddressGenerator.hash(for: SECP256K1.privateToPublic(privateKey: privateKey, compressed: true)!)
                guard pubKeyHash.toHexString() == self.fromPublicKeyHash else {
                    throw Error.privateKeyAndAddressNotMatch
                }
                let tx = try self.generateTx().wait()
                seal.fulfill(try Transaction.sign(tx: tx, with: privateKey))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func send() throws -> H256 {
        guard let signedTx = signedTx else {
            throw Error.txNotSigned
        }
        _ = apiClient.sendTransaction(transaction: signedTx)
        return signedTx.hash
    }

    private lazy var systemScript: SystemScript = {
        return SystemScript.loadSystemScript()
    }()
}

public extension Payment {
    enum Error: Swift.Error, LocalizedError {
        case invalidFromAddress
        case invalidToAddress
        case insufficientAmount
        case insufficientBalance
        case privateKeyAndAddressNotMatch
        case txNotSigned

        public var errorDescription: String? {
            switch self {
            case .invalidFromAddress:
                return "Invalid from address."
            case .invalidToAddress:
                return "Invalid to address."
            case .insufficientAmount:
                return "Insufficient Amount. Require at least \(Payment.minAmount) shannons."
            case .insufficientBalance:
                return "Insufficient balance to send out."
            case .privateKeyAndAddressNotMatch:
                return "The private key to sign the tx doesn't match the from address."
            case .txNotSigned:
                return "The tx hasn't been signed."
            }
        }
    }
}

extension Payment {
   public func generateTx() -> Promise<Transaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise) {
                let (inputs, changeAmount) = try self.collectInputs().wait()
                if inputs.count == 0 {
                    throw Error.insufficientBalance
                }
                var outputs = [CellOutput(capacity: self.amount, lock: self.systemScript.lock(for: self.toPublicKeyHash))]
                if changeAmount > 0 {
                    outputs.append(CellOutput(capacity: changeAmount, lock: self.systemScript.lock(for: self.fromPublicKeyHash)))
                }
                seal.fulfill(Transaction(
                    version: 0,
                    cellDeps: [self.cellDep],
                    inputs: inputs,
                    outputs: outputs,
                    outputsData: outputs.map { _ in "0x" },
                    unsignedWitnesses: inputs.enumerated().map({ (index, _) in
                        if index == 0 {
                            return WitnessArgs.emptyLock
                        }
                        return .data("0x")
                    })
                ))
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    /// Collect inputs from live cells in a FIFO manner.
    /// - Returns: Collected inputs and change amount.
    public func collectInputs() -> Promise<([CellInput], Capacity)> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let amountToCollect = self.amount + self.fee
                var amountCollected = Capacity(0)
                var inputs = [CellInput]()
                let unspentCells = try self.apiClient.getUnspentCells(publicKeyHash: self.fromPublicKeyHash, maxCapacity: BigUInt(amountToCollect)).wait()
                collecting: for cell in unspentCells {
                    let input = CellInput(previousOutput: cell.out_point, since: 0)
                    inputs.append(input)
                    amountCollected += cell.output.capacity

                    if amountCollected >= amountToCollect {
                        let diff = amountCollected - amountToCollect
                        if diff >= Payment.minAmount || diff == 0 {
                            break collecting
                        }
                    }
                }
                if amountToCollect > amountCollected {
                    seal.fulfill(([], 0))
                    return
                }
                seal.fulfill((inputs, amountCollected - amountToCollect))
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    var cellDep: CellDep {
        return CellDep(outPoint: systemScript.depOutPoint, depType: .depGroup)
    }
}
