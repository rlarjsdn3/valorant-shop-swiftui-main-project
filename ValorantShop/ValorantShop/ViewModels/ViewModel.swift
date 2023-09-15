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
    
    // MARK: - FUNCTIONS
    
    func login(username: String, password: String) async {
        await oauthManager.fetchAuthCookies()
        let accessToken = await try! oauthManager.fetchAccessToken(username: username, password: password).get()
        let entitlementToken = await try! oauthManager.fetchEntitlementToken(accessToken: accessToken).get()
        let uuid = await try! oauthManager.fetchRiotAccountPUUID(accessToken: accessToken)
    }
    
    func reAuth() async {
        await oauthManager.fetchReAuthCookies()
    }
    
}
