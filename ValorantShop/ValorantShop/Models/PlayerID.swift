//
//  PlayerID.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/21.
//

import RealmSwift

class PlayerID: Object, Codable {
    @Persisted var gameName: String
    @Persisted var tagLine: String
    
    enum CodingKeys: String, CodingKey {
        case gameName = "GameName"
        case tagLine = "TagLine"
    }
}
