//
//  Preview.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/26.
//

import Foundation
import RealmSwift

struct PreviewsData {
    
    static var skinInfo: SkinInfo = {
        
        let chroma1 = Chroma(value: [
            "uuid":"9e59563c-4467-43df-3b58-2ca43c25abde",
            "displayName": "Prime//2.0 Odin",
            "displayIcon": "https://media.valorant-api.com/weaponskinchromas/9e59563c-4467-43df-3b58-2ca43c25abde/displayicon.png",
            "swatch": "https://media.valorant-api.com/weaponskinchromas/9e59563c-4467-43df-3b58-2ca43c25abde/swatch.png"
        ])
        let chroma2 = Chroma(value: [
            "uuid":"ed34c641-4f1d-e38f-0018-4cb11fed9ee7",
            "displayName": "Prime//2.0 Odin Level 4\n(Variant 1 Gold)",
            "displayIcon": "https://media.valorant-api.com/weaponskinchromas/ed34c641-4f1d-e38f-0018-4cb11fed9ee7/displayicon.png",
            "swatch": "https://media.valorant-api.com/weaponskinchromas/ed34c641-4f1d-e38f-0018-4cb11fed9ee7/swatch.png"
        ])
        let chromas: RealmSwift.List<Chroma> = RealmSwift.List<Chroma>()
        chromas.append(chroma1)
        chromas.append(chroma2)
        
        let level1 = Level(value: [
            "uuid": "ef564ec3-497c-3038-543e-eb94bbe46437",
            "levelItem": nil,
            "streamedVideo": "https://valorant.dyn.riotcdn.net/x/videos/release-07.06/07c47f26-4dd6-fe8f-bcdc-18b9c1425667_default_universal.mp4"
        ] as [String : Any])
        let level2 = Level(value: [
            "uuid": "ab04093d-489f-27f3-9e1b-1589db2185c8",
            "levelItem": LevelItem.vfx,
            "streamedVideo": "https://valorant.dyn.riotcdn.net/x/videos/release-07.06/3ed8e0ec-48d9-5e12-58a7-9d9ea5e4fe4f_default_universal.mp4"
        ] as [String : Any])
        let levels: RealmSwift.List<Level> = RealmSwift.List<Level>()
        levels.append(level1)
        levels.append(level2)
        
        let skin = Skin(value: [
            "uuid": "157bcebe-484d-82e2-2a60-c8b4b11197ea",
            "displayName": "Prime//2.0 Odin",
            "contentTier": ContentTier.selectEdition,
            "displayIcon": "https://media.valorant-api.com/weaponskins/157bcebe-484d-82e2-2a60-c8b4b11197ea/displayicon.png",
            "chromas": chromas,
            "levels": levels
        ] as [String: Any])
        let price = Price(basePrice: 1234)
        
        let skinInfo = SkinInfo(skin: skin, price: price)
        return skinInfo
        
    }()
    
}
