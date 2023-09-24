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
            viewModel.getRenewalDate()
            // 현재 날짜 불러오기
            let currentDate = Date()
            // 로테이션 스킨 갱신 날짜 불러오기
            let storeSkinExpiryDate = viewModel.storeSkinsExpiryDate
            
            // ✏️ ①로그인을 하거나 ②갱신 날짜가 아직 유효할 때 앱을 켜면
            // ✏️ DB로부터 사용자 데이터를 갱신시키기 위해 아래 코드를 구현함.
            
            // For Debug
            print(currentDate, storeSkinExpiryDate)
            
            // 로테이션 갱신 날짜가 아직 유효하다면
            if currentDate < storeSkinExpiryDate {
                print("플레이어 데이터 가져오기 - OnAppear")
                // 사용자 데이터 불러오기
                Task {
                    await viewModel.getPlayerData()
                }
            }
        }
        .onReceive(didBecomeActiveNotification) { _ in
            // ✏️ 앱으로 들어오면 서버로부터 최신 데이터가 있는지 확인함.
            Task {
                await viewModel.checkValorantVersion()
            }
            // ✏️ 앱이 완전히 꺼지지 않고, 백그라운드에 머무를 수 있기 때문에
            // ✏️ 앱을 켜면 Timer에 의해 사용자 데이터를 불러올 수 있도록 해야함.
            viewModel.isIntialGettingPlayerDataInTimer = true
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
