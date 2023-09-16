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
    
    func reAuth() async {
        let accessToken = await try! oauthManager.fetchReAuthCookies().get()
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
    
}
