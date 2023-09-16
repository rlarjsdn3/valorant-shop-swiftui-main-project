//
//  ViewModel.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI

final class ViewModel: ObservableObject {
    
    // MARK: - WRAPPER PROPERTIES
    
    // ...
    
    // MARK: - PROPERTIES
    
    let oauthManager = OAuthManager.shared
    let resourceManager = ResourceManager.shared
    
    // MARK: - FUNCTIONS
    
    func login(username: String, password: String) async {
        await oauthManager.fetchAuthCookies()
        let accessToken = await try! oauthManager.fetchAccessToken(username: username, password: password).get()
        let entitlementToken = await try! oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
        let uuid = await try! oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
    }
    
    func reAuth() async -> (String, String, String) {
        let accessToken = await try! oauthManager.fetchReAuthCookies().get()
        let riotEntitlement = await try! oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
        let uuid = await try! oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
        return (accessToken, riotEntitlement, uuid)
    }
    
    func fetchRiotVersion() async {
        let riotVersion = await try? resourceManager.fetchValorantVersion().get()
        dump(riotVersion)
    }
    
    func fetchWallet() async {
        let accessToken = await try! oauthManager.fetchReAuthCookies().get()
        let entitlementToken = await try! oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
        let uuid = await try! oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
        let wallet = await try? resourceManager.fetchUserWallet(accessToken: accessToken, riotEntitlement: entitlementToken, puuid: uuid).get()
        dump(wallet)
    }
    
    func fetchWeaponSkins() async {
        let weaponSkins = await try! resourceManager.fetchWeaponSkins()
        dump(weaponSkins)
    }
    
    func fetchWeaponPrices() async {
        let tokens = await reAuth()
        print(tokens.0)
        print(tokens.1)
        let weaponPrices = await try! resourceManager.fetchStorePrices(accessToken: tokens.0, riotEntitlement: tokens.1)
        dump(weaponPrices)
    }
    
}
