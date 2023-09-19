//
//  Version.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/15.
//

import RealmSwift

final class Version: Object, Codable {
    @Persisted var status: Int
    @Persisted var client: Client?
    
    enum CodingKeys: String, CodingKey {
        case status
        case client = "data"
    }
}

final class Client: EmbeddedObject, Codable {
    @Persisted var riotClientVersion: String
    @Persisted var riotClientBuild: String
    @Persisted var buildDate: String
    
    enum CodingKeys: String, CodingKey {
        case riotClientVersion
        case riotClientBuild
        case buildDate
    }
}
