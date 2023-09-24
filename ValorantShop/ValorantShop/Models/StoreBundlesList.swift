//
//  BundlesMarket.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/24.
//

import RealmSwift

final class StoreBundlesList: Object {
    @Persisted var uuid: String // 번들 UUID
    @Persisted var basePrice: Int
    @Persisted var discountedPrice: Int
    @Persisted var discountedPercent: Double
    @Persisted var wholeSaleOnly: Bool
    @Persisted var itemInfos: RealmSwift.List<BundleSkinInfo>
}

final class BundleSkinInfo: EmbeddedObject {
    @Persisted var uuid: String // 첫 번째 레벨의 UUID
    @Persisted var basePrice: Int // 세트로 구매하지 않으면 일반 가격
    @Persisted var discountedPrice: Int // 세트로 구매하면 할인 가격
}
