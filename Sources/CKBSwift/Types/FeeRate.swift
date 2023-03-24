//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/22.
//

import Foundation

public struct FeeRate: Codable{
    public let mean: Capacity
    public let median: Capacity
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mean = Capacity(hexString: try container.decode(String.self, forKey: .mean))!
        median = Capacity(hexString: try container.decode(String.self, forKey: .median))!
    }
}
