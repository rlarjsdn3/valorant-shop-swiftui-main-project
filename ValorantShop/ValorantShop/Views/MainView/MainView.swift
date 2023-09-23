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
            Task {
                await viewModel.checkValorantVersion()
                await viewModel.getPlayerID()
                await viewModel.getPlayerWallet()
                await viewModel.getStoreRotationWeaponSkins()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { output in
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
