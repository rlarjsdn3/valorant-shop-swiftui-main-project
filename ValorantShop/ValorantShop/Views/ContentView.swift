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
    
    @State private var isIntialFetch: Bool = false
    
    // MARK: - INTIALIZER
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    // MARK: - BODY
    
    var body: some View {
        // 로그인을 하지 않았다면
        if !viewModel.isLoggedIn {
            OAuthView()
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
                if viewModel.isPresentLoadingScreenView {
                    VStack {
                        Text("Valorant Shop")
                            .font(.custom("VALORANT-Regular", size: 30))
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: UIColor.systemBackground))
                }
            }
            // 로그아웃했다가 다시 들어오는 상황도 고려
            .onAppear {
                print("Shop - onAppear")
                Task {
                    await viewModel.checkValorantVersion()
                    await viewModel.getPlayerID()
                    await viewModel.getPlayerWallet()
                    await viewModel.getStoreRotationWeaponSkins()
                }
            }
            // 앱을 완전히 나갔다 다시 들어오면 다시 로드
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { output in
                Task {
                    await viewModel.checkValorantVersion()
                }
            }
            .sheet(isPresented: $viewModel.isPresentDataDownloadView) {
                DataDownloadView(of: .update)
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
