//
//  Version.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/15.
//

import RealmSwift

final class Version: Object, Codable {
    @Persisted var status: Int
    @Persisted var valorant: ValorantVersion?
    
    enum CodingKeys: String, CodingKey {
        case status
        case valorant = "data"
    }
}

final class ValorantVersion: Object, Codable {
    @Persisted var riotClientVersion: String
    @Persisted var riotClientBuild: String
    
    enum CodingKeys: String, CodingKey {
        case riotClientVersion
        case riotClientBuild
    }
}
