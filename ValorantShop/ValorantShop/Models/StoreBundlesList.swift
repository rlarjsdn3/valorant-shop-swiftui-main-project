//
//  BundlesMarket.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/24.
//

import RealmSwift

final class StoreBundlesList: Object {
    @Persisted var imageUrl: String
    @Persisted var basePrice: Int
    @Persisted var discountedPrice: Int
    @Persisted var discountedPercent: Double
    @Persisted var uuids: List<String>
}
