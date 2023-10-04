//
//  WeaponSkins.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/15.
//

import SwiftUI
import Foundation
import RealmSwift

final class WeaponSkins: Object, Codable {
    @Persisted var status: Int
    @Persisted var weaponSkins: RealmSwift.List<Skin>
    
    enum CodingKeys: String, CodingKey {
        case weaponSkins = "data"
    }
}

final class Skin: EmbeddedObject, Codable {
    @Persisted var uuid: String
    @Persisted var displayName: String
    @Persisted var contentTier: ContentTier?
    @Persisted var displayIcon: String?
    @Persisted var chromas: RealmSwift.List<Chroma>
    @Persisted var levels: RealmSwift.List<Level>
    
    enum CodingKeys: String, CodingKey {
        case uuid, displayName
        case contentTier = "contentTierUuid"
        case displayIcon
        case chromas, levels
    }
}

enum ContentTier: String, PersistableEnum, Codable {
    case selectEdition = "12683d76-48d7-84a3-4e09-6985794f0445"
    case deulxeEdition = "0cebb8be-46d7-c12a-d306-e9907bfc5a25"
    case primeumEdition = "60bca009-4182-7998-dee7-b8a2558dc369"
    case exclusiveEdition = "e046854e-406c-37f4-6607-19a9ba8426fc"
    case ultraEdition = "411e4a55-4e59-7757-41f0-86a53f101bb5"
    
    var hightlightColor: Color {
        switch self {
        case .selectEdition:
            return Color.selectEdition
        case .deulxeEdition:
            return Color.deulxeEdition
        case .primeumEdition:
            return Color.premiumEdition
        case .exclusiveEdition:
            return Color.exclusiveEdition
        case .ultraEdition:
            return Color.ultraEdition
        }
    }
    
    var rankLogoName: String {
        switch self {
        case .selectEdition:
            return "selectEdition"
        case .deulxeEdition:
            return "deluxeEdition"
        case .primeumEdition:
            return "premiumEdition"
        case .exclusiveEdition:
            return "exclusiveEdition"
        case .ultraEdition:
            return "ultraEdition"
        }
    }
}

final class Chroma: EmbeddedObject, Codable {
    @Persisted var uuid: String
    @Persisted var displayName: String
    @Persisted var displayIcon: String?
    @Persisted var swatch: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case displayName
        case displayIcon
        case swatch
    }
}

final class Level: EmbeddedObject, Codable {
    @Persisted var uuid: String
    @Persisted var levelItem: LevelItem?
    @Persisted var streamedVideo: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case levelItem
        case streamedVideo
    }
}

enum LevelItem: String, PersistableEnum, Codable {
    case animation = "EEquippableSkinLevelItem::Animation"
    case attackerDefenderSwap = "EEquippableSkinLevelItem::AttackerDefenderSwap"
    case finisher = "EEquippableSkinLevelItem::Finisher"
    case fishAnimation = "EEquippableSkinLevelItem::FishAnimation"
    case heartbeatAndMapSensor = "EEquippableSkinLevelItem::HeartbeatAndMapSensor"
    case inspectAndKill = "EEquippableSkinLevelItem::InspectAndKill"
    case killBanner = "EEquippableSkinLevelItem::KillBanner"
    case killCounter = "EEquippableSkinLevelItem::KillCounter"
    case killEffect = "EEquippableSkinLevelItem::KillEffect"
    case randomizer = "EEquippableSkinLevelItem::Randomizer"
    case soundEffects = "EEquippableSkinLevelItem::SoundEffects"
    case etopFrag = "EEquippableSkinLevelItem::TopFrag"
    case transformation = "EEquippableSkinLevelItem::Transformation"
    case vfx = "EEquippableSkinLevelItem::VFX"
    case voiceover = "EEquippableSkinLevelItem::Voiceover"
    
    var displayName: String {
        switch self {
        case .animation:
            return "애니메이션"
        case .attackerDefenderSwap:
            return "-"
        case .finisher:
            return "마무리"
        case .fishAnimation:
            return "-"
        case .heartbeatAndMapSensor:
            return "-"
        case .inspectAndKill:
            return "-"
        case .killBanner:
            return "-"
        case .killCounter:
            return "-"
        case .killEffect:
            return "-"
        case .randomizer:
            return "-"
        case .soundEffects:
            return "-"
        case .etopFrag:
            return "-"
        case .transformation:
            return "-"
        case .vfx:
            return "-"
        case .voiceover:
            return "-"
        }
    }
}
