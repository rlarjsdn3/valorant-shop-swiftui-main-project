//
//  MainView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI
import SwiftTaskQueue

struct MainView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    
    // MARK: - PROPERTIES
    
    let realmManager: RealmManager = RealmManager.shared
    
    let didEnterBackgroundNotification = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
    
    let willEnterForegroundNotification = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    
    // MARK: - BODY
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $appViewModel.selectedCustomTab) {
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
            // ✏️ onAppear에서는 (앱이 처음 실행되면)
            // 사용자 ID, 재화 정보와 내스킨 정보를 불러오고,
            // 토큰 만료 유무에 따라 서버 혹은 Realm에서 상점 정보를 불러옴.
            
            // ✏️ Timer에서는 (앱이 백그→포그 혹은 실행 중이라면)
            // 상점 정보의 만료 유무에 따라 서버에서 상점 정보를 불러옴.
            // Realm에서는 불러올 필요가 없는 이유는 메모리에서 해제된 상태가 아니기 때문임.
            // (즉, Persisted 변수에 상점 정보가 유지되어 있음)
            
            Task {
                await resourceViewModel.loadPlayerData()
            }
        }
        .onReceive(willEnterForegroundNotification) { _ in
            // 최신 버전의 데이터가 존재하는지 확인하기
            Task {
                await resourceViewModel.checkValorantVersion()
            }
            // 앱 실행 중 자동으로 리로드될 수 있도록 변수에 새로운 값 넣기
            resourceViewModel.isAutoReloadedStoreSkinsData = false
            resourceViewModel.isAutoReloadedStoreBundlesData = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring()) {
                    // 로딩 화면 가리기
                    resourceViewModel.isPresentLoadingScreenViewFromView = false
                }
            }
        }
        .onReceive(didEnterBackgroundNotification) { _ in
            // 로딩 화면 띄우기
            resourceViewModel.isPresentLoadingScreenViewFromView = true
            resourceViewModel.isPresentLoadingScreenViewFromSkinsTimer = true
            resourceViewModel.isPresentLoadingScreenViewFromBundlesTimer = true
        }
        .overlay {
            if resourceViewModel.isPresentLoadingScreenViewFromView ||
                resourceViewModel.isPresentLoadingScreenViewFromSkinsTimer ||
                resourceViewModel.isPresentLoadingScreenViewFromBundlesTimer {
                LoadingView()
            }
        }
        .fullScreenCover(isPresented: $loginViewModel.isPresentDataUpdateView) {
            DataDownloadView(of: .update)
        }
    }
 
}

// MARK: - PREVIEW

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppViewModel())
            .environmentObject(LoginViewModel())
            .environmentObject(ResourceViewModel())
    }
}
