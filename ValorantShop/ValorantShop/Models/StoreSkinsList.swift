//
//  RotatedWeaponSkins.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/20.
//

import Foundation
import RealmSwift

final class StoreSkinsList: Object {
    @Persisted var renewalDate: Date
    @Persisted var itemInfos: RealmSwift.List<RotationSkinInfo>
}

final class RotationSkinInfo: EmbeddedObject {
    @Persisted var uuid: String // 첫 번째 레벨의 UUID
}
