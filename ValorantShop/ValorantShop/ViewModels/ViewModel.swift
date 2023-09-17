//
//  ViewModel.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI
import RealmSwift
import KeychainAccess

// MARK: - MODELS

struct ReAuthTokens {
    let accessToken: String
    let riotEntitlement: String
    let puuid: String
}

// MARK: - VIEW MODEL

@MainActor
final class ViewModel: ObservableObject {
    
    // MARK: - USER DEFAULTS
    
    @AppStorage(UserDefaultsKey.isLoggedIn) var isLoggedIn: Bool = false
    @AppStorage(UserDefaultsKey.isDataDownloaded) var isDataDownloaded: Bool = false
    
    // MARK: - WRAPPER PROPERTIES
    
    // For Test
    @Published var totalImageCountToDownload: Int = 0
    @Published var totalDownloadedImageCount: Int = 0
    
    // MARK: - PROPERTIES
    
    let oauthManager = OAuthManager.shared
    let realmManager = RealmManager.shared
    let resourceManager = ResourceManager.shared
    
    let keychain = Keychain()
    
    // MARK: - FUNCTIONS
    
    func login(username: String, password: String) async {
        do {
            // ID와 패스워드로 로그인이 가능한지 확인하기
            try await oauthManager.fetchAuthCookies().get()
            try await oauthManager.fetchAccessToken(username: username, password: password).get()
            // 로그인에 성공하면 UserDefaults 수정하기
            self.isLoggedIn = true
        } catch {
            // 로그인에 실패하면 예외 처리하기
        }
    }
    
    func logout() {
        // ReAuth를 위한 쿠키 정보 삭제하기
        try? keychain.removeAll()
        
        // 로그인 여부 및 사용자 정보 삭제하기
        self.isLoggedIn = false
    }
    
    func downloadStoreData() async {
        // 무기 스킨 데이터 다운로드받고, Realm에 저장하기
        await self.downloadWeaponSkinsData()
        // 가격 정보 데이터 다운로드받고, Realm에 저장하기
        await self.downloadStorePricesData()
        // 스킨 이미지 데이터 다운로드받고, 로컬 Document 폴더에 저장하기
        await self.downloadWeaponSkinImages()
    }
    
    private func downloadWeaponSkinsData() async {
        do {
            // 무기 스킨 데이터 다운로드받기
            let weaponSkins = try await resourceManager.fetchWeaponSkins().get()
            // 무기 스킨 데이터를 Realm에 저장하기
            self.saveStoreData(weaponSkins)
        } catch {
            // 다운로드에 실패하면 예외 처리하기
        }
    }
    
    private func downloadStorePricesData() async {
        do {
            //  접근 토큰, 등록 정보 및 PUUID값 가져오기
            guard let reAuthTokens = await self.fetchReAuthTokens() else { return }
            // 상점 가격 데이터 다운로드받기
            let storePrices = try await resourceManager.fetchStorePrices(
                accessToken: reAuthTokens.accessToken,
                riotEntitlement: reAuthTokens.riotEntitlement
            ).get()
            // 상점 가격 데이터를 Realm에 저장하기
            saveStoreData(storePrices)
        } catch {
            // 다운로드에 실패하면 예외 처리하기
        }
    }
    
    private func downloadWeaponSkinImages() async {
        
    }
    
    private func saveStoreData<T: Object>(_ object: T) {
        // 데이터를 저장하기 전, 기존 데이터 삭제하기
        realmManager.deleteAll(of: T.self)
        // 새로운 데이터 저장하기
        realmManager.create(object)
    }
    
    
    
    
    
    private func fetchReAuthTokens() async -> ReAuthTokens? {
        do {
            // 쿠키 정보를 통해 접근 토큰, 등록 정보 및 PUUID값 가져오기
            let accessToken: String = try await oauthManager.fetchReAuthCookies().get()
            let riotEntitlement: String = try await oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
            let puuid: String = try await oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
            return ReAuthTokens(accessToken: accessToken, riotEntitlement: riotEntitlement, puuid: puuid)
        } catch {
            // 토큰 정보 가져오기에 실패하면 nil 반환하기
            return nil
        }
    }
    
    
    
    
    
    
    
    
    
    
    func fetchRiotVersion() async {
        let riotVersion = await try? resourceManager.fetchValorantVersion().get()
        dump(riotVersion)
    }
    
    func fetchWallet() async {
        let accessToken = await try! oauthManager.fetchReAuthCookies().get()
        let entitlementToken = await try! oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
        let uuid = await try! oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
        let wallet = await try? resourceManager.fetchUserWallet(accessToken: accessToken, riotEntitlement: entitlementToken, puuid: uuid).get()
        dump(wallet)
    }
    
    
    
}
