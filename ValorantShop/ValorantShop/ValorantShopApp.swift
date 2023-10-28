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
    
    @StateObject var viewModel: ViewModel = ViewModel()
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    // MARK: - BODY
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.loginDelegate = loginViewModel
                }
        }
    }
    
}
