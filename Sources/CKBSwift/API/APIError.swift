//
//  APIError.swift
//
//  Copyright © 2019 Nervos Foundation. All rights reserved.
//

import Foundation

public struct APIError: Codable, LocalizedError {
    let code: Int
    let message: String

    var errorDescription: String { message }
}

extension APIError {
    public static let genericErrorCode = -1
    public static let invalidUrl = APIError(code: genericErrorCode, message: "Invalid URL")
    public static let invalidParameters = APIError(code: genericErrorCode, message: "Invalid parameters")
    public static let emptyResponse = APIError(code: genericErrorCode, message: "Empty response")
    public static let nullResult = APIError(code: genericErrorCode, message: "Null result")
    public static let unmatchedId = APIError(code: genericErrorCode, message: "Unmatched id")
    public static func genericError(_ message: String) -> APIError { APIError(code: genericErrorCode, message: message) }
}
