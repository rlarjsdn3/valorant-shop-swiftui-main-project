//
//  MainView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI

struct MainView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - PROPERTIES
    
    let didBecomeActiveNotification = NotificationCenter.default.publisher(
        for: UIApplication.didBecomeActiveNotification
    )
    
    // MARK: - BODY
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $viewModel.selectedCustomTab) {
                StoreView()
                    .tag(CustomTabType.shop)
                
                CollectionView()
                    .tag(CustomTabType.collection)
                
                SettingsView()
                    .tag(CustomTabType.settings)
            }
            
            CustomTabView()
        }
        .onAppear {
            // ✏️ 로그인에 성공하거나, 앱으로 들어오면 서버나 DB로부터 최신 데이터를 받아옴.
            Task {
                await viewModel.checkValorantVersion()
                await viewModel.getPlayerID()
                await viewModel.getPlayerWallet()
                await viewModel.getStoreRotationWeaponSkins()
            }
        }
        .onReceive(didBecomeActiveNotification) { _ in
            // ✏️ 앱으로 들어오면 서버로부터 최신 데이터가 있는지 확인함.
            Task {
                await viewModel.checkValorantVersion()
            }
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
        .sheet(isPresented: $viewModel.isPresentDataUpdateView) {
            DataDownloadView(of: .update)
        }
    }
}

// MARK: - PREVIEW

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(ViewModel())
    }
}
