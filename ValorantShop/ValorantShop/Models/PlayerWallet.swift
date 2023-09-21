//
//  PlayerWallet.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/21.
//

import RealmSwift

class PlayerWallet: Object, Codable {
    @Persisted var balances: Balance?

    enum CodingKeys: String, CodingKey {
        case balances = "Balances"
    }
}

class Balance: EmbeddedObject, Codable {
    @Persisted var vp: Int
    @Persisted var rp: Int
    @Persisted var kp: Int
    
    enum CodingKeys: String, CodingKey {
        case vp = "85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741"
        case rp = "e59aa87c-4cbf-517a-5983-6e81511be9b7"
        case kp = "85ca954a-41f2-ce94-9b45-8ca3dd39a00d"
    }
}
