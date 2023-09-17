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
    
    // For Downlaod Data
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
    
    func downloadStoreData() async {
        do {
            // 무기 스킨 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadWeaponSkinsData()
            // 가격 정보 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadStorePricesData()
            // 스킨 이미지 데이터 다운로드받고, 로컬 Document 폴더에 저장하기
            try await self.downloadWeaponSkinImages()
        } catch {
            // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    private func downloadWeaponSkinsData() async throws {
        // 무기 스킨 데이터 다운로드받기
        let weaponSkins = try await resourceManager.fetchWeaponSkins().get()
        // 무기 스킨 데이터를 Realm에 저장하기
        self.saveStoreData(weaponSkins)
    }
    
    private func downloadStorePricesData() async throws {
        //  접근 토큰, 등록 정보 및 PUUID값 가져오기
        guard let reAuthTokens = await self.fetchReAuthTokens() else { return }
        // 상점 가격 데이터 다운로드받기
        let storePrices = try await resourceManager.fetchStorePrices(
            accessToken: reAuthTokens.accessToken,
            riotEntitlement: reAuthTokens.riotEntitlement
        ).get()
        // 상점 가격 데이터를 Realm에 저장하기
        self.saveStoreData(storePrices)
    }
    
    private func saveStoreData<T: Object>(_ object: T) {
        print(T.self)
        // 데이터를 저장하기 전, 기존 데이터 삭제하기
        realmManager.deleteAll(of: T.self)
        // 새로운 데이터 저장하기
        realmManager.create(object)
    }
    
    private func downloadWeaponSkinImages() async throws {
        // Realm으로부터 스킨 데이터 불러오기
        let weaponSkins = realmManager.read(of: WeaponSkins.self)
        
        // 경로 접근을 위한 파일 매니저 선언하기
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 경로에 이미지가 저장되지 않은 스킨 UUID값 저장하기
        var notDownloadedImages: [(imageType: ImageType, uuid: String)] = []
        
        // 정상적으로 스킨 데이터를 불러왔는지 확인하기
        guard let skins = weaponSkins.first?.skins else { return }
        // 스킨 데이터를 순회하며 저장되지 않은 스킨 이미지 UUID값 솎아내기
        for skin in skins {
            // UUID값 저장하기
            let uuid = skin.uuid
            // 경로 설정하기
            let skinPath = documents.appending(path: makeImageFileName(of: ImageType.weaponSkins, uuid: uuid)).path()
            // 파일 매니저의 경로에 해당 파일이 존재하지 않으면
            if !fileManager.fileExists(atPath: skinPath) {
                // 저장되지 않은 스킨 UUID값 저장하기
                notDownloadedImages.append((ImageType.weaponSkins, uuid))
            }
            
            // 스킨 속 크로마 데이터가 하나라면
            if skin.chromas.count <= 1 { continue }
            
            // 크로마 데이터를 순회하며 저장되지 않은 스킨과 스와치 이미지 UUID값 솎아내기
            for chroma in skin.chromas {
                // UUID값 저장하기
                let uuid = chroma.uuid
                // 경로 설정하기
                let chromaPath = documents.appending(path: makeImageFileName(of: ImageType.weaponSkinChromas, uuid: uuid)).path()
                let swatchPath = documents.appending(path: makeImageFileName(of: ImageType.weaponSkinSwatchs, uuid: uuid)).path()
                // 파일 매니저의 경로에 해당 파일이 존재하지 않으면
                if !fileManager.fileExists(atPath: chromaPath) {
                    // 저장되지 않은 스킨 UUID값 저장하기
                    notDownloadedImages.append((ImageType.weaponSkinChromas, uuid))
                }
                // 파일 매너지의 경로에 해당 파일이 존재하지 않으면
                if !fileManager.fileExists(atPath: swatchPath) {
                    // 저장되지 않은 스킨 UUID값 저장하기
                    notDownloadedImages.append((ImageType.weaponSkinSwatchs, uuid))
                }
            }
        }
        
        // 총 다운로드할 이미지 개수를 프로퍼티 래퍼에 저장하기
        self.totalImageCountToDownload = notDownloadedImages.count
        
        // 이미지를 다운로드해 Documents 폴더에 저장하기
        for notDownloadedImage in notDownloadedImages {
            // 다운로드한 이미지 데이터를 저장하는 변수 선언하기
            var imageData: Data
            // 다운로드 한 이미지 개수 증가시키기
            self.totalDownloadedImageCount += 1
            // 이미지 타입 저장하기
            let imageType = notDownloadedImage.imageType
            // UUID값 저장하기
            let uuid = notDownloadedImage.uuid
            // 이미지 다운로드하기
            do {
                print("다운로드할 이미지 이름 - \(makeImageFileName(of: imageType, uuid: uuid))")
                imageData = try await resourceManager.fetchSkinImageData(
                    of: notDownloadedImage.imageType,
                    uuid: notDownloadedImage.uuid
                ).get()
            } catch {
                continue
            }
            // 경로 설정하기
            let saveUrl = documents.appending(path: makeImageFileName(of: imageType, uuid: uuid))
            // 해당 경로에 이미지 파일 저장하기
            try imageData.write(to: saveUrl)
        }
        
    }
    
    private func makeImageFileName(of type: ImageType, uuid: String) -> String {
        return "\(type.prefixFileName)-\(uuid).png"
    }
    
    // For Test
    func deleteAll() {
        realmManager.deleteAll()
    }
    
}
