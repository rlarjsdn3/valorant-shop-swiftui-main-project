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
    
    @StateObject var appViewModel: AppViewModel = AppViewModel()
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    @StateObject var resourceViewModel: ResourceViewModel = ResourceViewModel()
    @StateObject var settingsViewModel: SettingsViewModel = SettingsViewModel()
    
    // MARK: - BODY
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    loginViewModel.appDelegate = appViewModel
                    loginViewModel.resourceDelegate = resourceViewModel
                    
                    resourceViewModel.loginDelegate = loginViewModel
                }
                .environmentObject(appViewModel)
                .environmentObject(loginViewModel)
                .environmentObject(resourceViewModel)
                .environmentObject(settingsViewModel)
        }
    }
    
}
