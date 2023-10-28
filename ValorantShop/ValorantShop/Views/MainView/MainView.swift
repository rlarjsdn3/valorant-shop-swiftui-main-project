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
            
            let taskQueue = TaskQueue()
            
            Task {
                // 최신 버전의 데이터가 존재하는지 확인하기
                await resourceViewModel.checkValorantVersion()
            }
            
            // ⭐️ async 작업을 순서대로 처리하도록 도와주는 큐
            // 이렇게 처리해주지 않는다면, 쿠키가 동시에 설정되어 통신에 실패할 가능성이 있음.
            taskQueue.dispatch {
                // 사용자ID 등 기본적인 정보 불러오기
                // ⭐️ 사용자ID 등 기본적인 정보는 언제 바뀔지 모르니 항상 불러옴.
                await resourceViewModel.getPlayerID(forceLoad: true)
                await resourceViewModel.getPlayerWallet(forceLoad: true)
                await resourceViewModel.getOwnedWeaponSkins()
                
                // ⭐️
                // taskQueue를 사용하지 않으면
                // -- Consol Area --
                //  fetchReAuthCookies()
                //  fetchReAuthCookies()
                //  loadSetCookie()
                //  loadSetCookie()
                //  saveSetCookie(_:)
                //  saveSetCookie(_:)
                //  fetchRiotEntitlement(accessToken:)
                //  fetchRiotEntitlement(accessToken:)
                //  fetchRiotAccountPUUID(accessToken:)
                //  fetchRiotAccountPUUID(accessToken:)
                // -----------------
                // 와 같이 메서드가 중복으로 호출되는 문제가 발생함.
            }
            
            // 컬렉션 정보 불러오기
            resourceViewModel.getCollection()
            
            // 로테이션 스킨 갱신 날짜 불러오기
            if let renewalDate = realmManager.read(of: StoreSkinsList.self).first?.renewalDate {
                resourceViewModel.storeSkinsRenewalDate = renewalDate
            }
            // 번들 스킨 갱신 날짜 불러오기
            resourceViewModel.storeBundlesRenewalDate = []
            let storeBundles = realmManager.read(of: StoreBundlesList.self)
            for bundle in storeBundles {
                resourceViewModel.storeBundlesRenewalDate.append(bundle.renewalDate)
            }
            
            // 현재 날짜 불러오기
            let currentDate = Date()
            // 로테이션 스킨을 갱신할 필요가 없다면
            if currentDate < resourceViewModel.storeSkinsRenewalDate {
                print("OnAppear: Skin - Realm에서 데이터 가져오기")
                // Realm에서 데이터 가져오기
                Task {
                    await resourceViewModel.getStoreSkins()
                }
            } else {
                print("OnAppear: Skin - 서버에서 데이터 가져오기")
                // 서버에서 데이터 가져오기
                Task {
                    await resourceViewModel.getStoreSkins(forceLoad: true)
                }
            }
            
            // 번들 갱신이 필요한지 확인하는 변수 선언하기
            var needRenewalBundles: Bool = false
            // 각 번들을 순회해보며
            for renewalDate in resourceViewModel.storeBundlesRenewalDate {
                // 번들 스킨을 갱신할 필요가 없다면
                if currentDate < renewalDate {
                    continue
                // 번들 스킨을 갱신할 필요가 있다면
                } else {
                    needRenewalBundles = true; break
                }
            }
            // 번들 스킨을 갱신할 필요가 없다면
            if !needRenewalBundles {
                print("OnAppear: Bundle - Realm에서 데이터 가져오기")
                // Realm에서 데이터 가져오기
                Task {
                    await resourceViewModel.getStoreBundles()
                }
            // 번들 스킨을 갱신할 필요가 있다면
            } else {
                print("OnAppear: Bundle - 서버에서 데이터 가져오기")
                // 서버에서 데이터 가져오기
                Task {
                    await resourceViewModel.getStoreBundles(forceLoad: true)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                // 타이머 작동시키기
                resourceViewModel.storeSkinsTimer = Timer.scheduledTimer(
                    withTimeInterval: 1.0,
                    repeats: true,
                    block: resourceViewModel.updateStoreSkinsRemainingTime(_:)
                )
                resourceViewModel.storeBundlesTimer = Timer.scheduledTimer(
                    withTimeInterval: 1.0,
                    repeats: true,
                    block: resourceViewModel.updateStoreBundlesRemainingTime(_:)
                )
                
                withAnimation(.spring()) {
                    // 로딩 스크린 가리기
                    resourceViewModel.isPresentLoadingScreenViewFromView = false
                }
                
                // 다운로드 화면을 가리기
                loginViewModel.isPresentDataDownloadView = false
                // ✏️ 팝 내비게이션 스택 애니메이션이 보이게 하지 않기 위해 1초 딜레이를 둠.
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
