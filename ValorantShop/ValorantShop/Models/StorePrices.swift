//
//  StorePrices.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/15.
//

import RealmSwift

final class StorePrices: Object, Codable {
    @Persisted var offers: List<Offer>
    
    enum CodingKeys: String, CodingKey {
        case offers = "Offers"
    }
}

final class Offer: EmbeddedObject, Codable {
    @Persisted var offerID: String // 무기 스킨의 첫 번째 Level의 UUID값
    @Persisted var cost: Cost?
    
    enum CodingKeys: String, CodingKey {
        case offerID = "OfferID"
        case cost = "Cost"
    }
}

final class Cost:  EmbeddedObject, Codable {
    @Persisted var vp: Int

    enum CodingKeys: String, CodingKey {
        case vp = "85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741"
    }
}
