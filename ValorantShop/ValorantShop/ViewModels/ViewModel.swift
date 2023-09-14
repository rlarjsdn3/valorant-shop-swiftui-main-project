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
        await oauthManager.getAuthCookies()
        let accessToken = await try! oauthManager.getAccessToken(username: username, password: password).get()
        await oauthManager.getEntitlementToken(accessToken: accessToken)
    }
    
}
