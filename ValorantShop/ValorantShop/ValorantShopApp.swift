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
    
    // MARK: - BODY
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(loginViewModel)
                .environmentObject(resourceViewModel)
                .onAppear {
                    loginViewModel.appDelegate = appViewModel
                    loginViewModel.resourceDelegate = resourceViewModel
                    
                    resourceViewModel.loginDelegate = loginViewModel
                }
        }
    }
    
}
