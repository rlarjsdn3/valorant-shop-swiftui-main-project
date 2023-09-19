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
    
    // MARK: - INTIALIZER
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    // MARK: - BODY
    
    var body: some View {
        // 로그인을 하지 않았다면
        if !viewModel.isLoggedIn {
            LoginView()
        // 로그인을 하였다면
        } else {
            VStack(spacing: 0) {
                TabView(selection: $viewModel.selectedCustomTab) {
                    ShopView()
                        .tag(CustomTabType.shop)
                    
                    CollectionView()
                        .tag(CustomTabType.collection)
                    
                    SettingsView()
                        .tag(CustomTabType.settings)
                }
                
                CustomTabView()
            }
            .overlay {
                if viewModel.isPresentLaunchScreenView {
                    VStack {
                        Text("VALORANT SHOP")
                            .font(.custom("VALORANT-Regular", size: 30))
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                }
            }
            .onAppear {
                Task(priority: .high) {
                    await viewModel.fetchStoreRotationWeaponSkins()
                    await viewModel.fetchPlayerID()
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
