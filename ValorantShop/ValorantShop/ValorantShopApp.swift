//
//  ValorantShopApp.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/12.
//

import SwiftUI

@main
struct ValorantShopApp: App {
    
    // MARK: - WRAPPER PROPERTIES
    
    @StateObject var resourceViewModel: ResourceViewModel = ResourceViewModel()
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    // MARK: - BODY
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
                .environmentObject(resourceViewModel)
                .onAppear {
                    loginViewModel.resourceDelegate = resourceViewModel
                    resourceViewModel.loginDelegate = loginViewModel
                    
                }
        }
    }
    
}
