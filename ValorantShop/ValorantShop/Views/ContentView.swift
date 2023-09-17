//
//  ContentView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/12.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var selectedCustomTab: CustomTabType = .shop
    
    // MARK: - INTIALIZER
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    // MARK: - BODY
    
    var body: some View {
        // 로그인을 하였다면
        if !viewModel.isLoggedIn {
            LoginView()
                .onAppear {
                    print(viewModel.isLoggedIn)
                }
        // 로그인을 하지 않았다면
        } else {
            VStack(spacing: 0) {
                TabView(selection: $selectedCustomTab) {
                    ShopView()
                        .tag(CustomTabType.shop)
                    
                    CollectionView()
                        .tag(CustomTabType.collection)
                    
                    SettingsView()
                        .tag(CustomTabType.settings)
                }
                
                CustomTabView($selectedCustomTab)
            }
            .onAppear {
                Task {
                    await viewModel.getStoreRotationWeaponSkins()
                }
            }
        }
    }
}

// MARK: - PREVIEW

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ViewModel())
    }
}
