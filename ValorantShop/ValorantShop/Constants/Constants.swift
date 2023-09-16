//
//  Constants.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import Foundation

struct OAuthURL {
    
    // For Auth
    static var auth: String = "https://auth.riotgames.com/api/v1/authorization"
    static var reAuth: String = "https://auth.riotgames.com/api/v1/authorization"
    static var entitlement: String = "https://entitlements.auth.riotgames.com/api/token/v1"
    
    // For User
    static var userInfo: String = "https://auth.riotgames.com/userinfo"
}

struct ResourceURL {
    
    // For Resource
    static var version: String = "https://valorant-api.com/v1/version"
    static var wallet: String = "https://pd.kr.a.pvp.net/store/v1/wallet/"
}
