//
//  Bundles.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/24.
//

import RealmSwift

final class Bundles: Object, Codable {
    @Persisted var status: Int
    @Persisted var bundle: RealmSwift.List<BundleSkins>
    
    enum CodingKeys: String, CodingKey {
        case status
        case bundle = "data"
    }
}

final class BundleSkins: EmbeddedObject, Codable {
    @Persisted var uuid: String
    @Persisted var displayName: String
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case displayName
    }
}
