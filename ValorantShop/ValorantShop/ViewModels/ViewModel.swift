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

struct StoreRotationWeaponkins {
    var weaponSkins: [(skin: Skin, price: Int)] = []
}

// MARK: - VIEW MODEL

final class ViewModel: ObservableObject {
    
    // MARK: - USER DEFAULTS
    
    @AppStorage(UserDefaults.isLoggedIn) var isLoggedIn: Bool = false
    @AppStorage(UserDefaults.isDataDownloaded) var isDataDownloaded: Bool = false
    
    // MARK: - WRAPPER PROPERTIES
    
    // For LaunchScreen
    @Published var isPresentLaunchScreenView: Bool = true
    
    // For MultifactorAuth
    @Published var multifactorAuthEmail: String = ""
    @Published var isPresentMultifactorAuthView: Bool = false
    
    // For CustomTab
    @Published var selectedCustomTab: CustomTabType = .shop
    
    // For Downlaod Data
    @Published var isPresentDownloadView: Bool = false
    @Published var totalImageCountToDownload: Int = 0
    @Published var totalDownloadedImageCount: Int = 0
    
    // For PlayerID
//    @Published var
    
    // For Storefront
    @Published var storeRotationWeaponSkins: StoreRotationWeaponkins = .init()
    @Published var rotationWeaponSkinsRemainingSeconds: Int = 0
    
    // MARK: - PROPERTIES
    
    let oauthManager = OAuthManager.shared
    let realmManager = RealmManager.shared
    let resourceManager = ResourceManager.shared
    
    let keychain = Keychain()
    
    var timer: Timer?
    
    // MARK: - INTIALIZER
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            // self 키워드 옵셔널 바인딩하기
            guard let self = self else { return }
            // 다음 상점 로테이션까지 남은 초(sec)가 0 이상이라면
            if self.rotationWeaponSkinsRemainingSeconds > 0 {
                self.rotationWeaponSkinsRemainingSeconds -= 1
            }
        })
    }
    
    // MARK: - FUNCTIONS
    
    @MainActor
    func login(username: String, password: String) async {
        do {
            // ID와 패스워드로 로그인이 가능한지 확인하기
            let _ = try await oauthManager.fetchAuthCookies().get()
            let _ = try await oauthManager.fetchAccessToken(username: username, password: password).get()
            // 로그인에 성공하면 성공 여부 수정하기
            self.isLoggedIn = true
        // 이중 인증이 필요하다면
        } catch OAuthError.needMultifactor(let email) {
            // 인증 이메일을 뷰에 표시하기
            self.multifactorAuthEmail = email
            // 이중 인증 화면 보이게 하기
            self.isPresentMultifactorAuthView = true
        } catch {
            // 로그인에 실패하면 예외 처리하기
        }
    }
    
    @MainActor
    func login(authenticationCode code: String) async {
        do {
            // 이중 인증 코드로 로그인이 가능한지 확인하기
            let _ = try await oauthManager.fetchMultifactorAuth(authenticationCode: code).get()
            // 로그인에 성공하면 성공 여부 수정하기
            self.isLoggedIn = true
        } catch {
            // 로그인에 실패하면 예외 처리하기
        }
    }
    
    func logout() {
        // 새로운 세션 할당하기
        oauthManager.urlSession = URLSession(configuration: .ephemeral)
        resourceManager.urlSession = URLSession.shared
        
        // ReAuth를 위한 쿠키 정보 삭제하기
        try? keychain.removeAll()
        
        // 로그인 여부 및 사용자 정보 삭제하기
        self.isLoggedIn = false
        
        // 커스탬 탭 선택 초기화하기
        self.selectedCustomTab = .shop
        // 불러온 상점 데이터 삭제하기
        self.storeRotationWeaponSkins = .init()
        // 런치 스크린 표시 여부 수정하기
        self.isPresentLaunchScreenView = true
    }
    
    private func fetchReAuthTokens() async -> Result<ReAuthTokens, OAuthError> {
        do {
            // 쿠키 정보를 통해 접근 토큰, 등록 정보 및 PUUID값 가져오기
            let accessToken: String = try await oauthManager.fetchReAuthCookies().get()
            let riotEntitlement: String = try await oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
            let puuid: String = try await oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
            let reAuthTokens = ReAuthTokens(accessToken: accessToken, riotEntitlement: riotEntitlement, puuid: puuid)
            return .success(reAuthTokens)
        } catch {
            // 토큰 정보 가져오기에 실패하면 예외 던지기
            return .failure(.noTokenError)
        }
    }
    
    @MainActor
    func downloadStoreData(reload: Bool = false) async {
        do {
            // ⭐️ 새로운 스킨 데이터가 삭제되는(덮어씌워지는) 와중에 뷰에서는 삭제된 데이터에 접근하고 있기 때문에
            // ⭐️ 'Realm object has been deleted or invalidated' 에러가 발생함. 이를 막기 위해 다운로드 동안 뷰에 표시할 데이터를 삭제함.
            self.storeRotationWeaponSkins.weaponSkins = []
            // 무기 스킨 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadWeaponSkinsData()
            // 가격 정보 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadStorePricesData()
            // 스킨 이미지 데이터 다운로드받고, 로컬 Document 폴더에 저장하기
            try await self.downloadWeaponSkinImages()
            // 새로운 스킨 데이터를 다운로드 받으면
            if reload {
                // 새로운 스킨 데이터로 상점 정보를 뷰에 로드하기
                await self.fetchStoreRotationWeaponSkins()
            }
            // 다운로드를 모두 마치면 성공 여부 수정하기
            self.isDataDownloaded = true
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    @MainActor
    private func downloadWeaponSkinsData() async throws {
        // 무기 스킨 데이터 다운로드받기
        let weaponSkins = try await resourceManager.fetchWeaponSkins().get()
        // 무기 스킨 데이터를 Realm에 저장하기
        self.saveStoreData(weaponSkins)
    }
    
    @MainActor
    private func downloadStorePricesData() async throws {
        // 접근 토큰, 등록 정보 및 PUUID값 가져오기
        let reAuthTokens = try await self.fetchReAuthTokens().get()
        // 상점 가격 데이터 다운로드받기
        let storePrices = try await resourceManager.fetchStorePrices(
            accessToken: reAuthTokens.accessToken,
            riotEntitlement: reAuthTokens.riotEntitlement
        ).get()
        // 상점 가격 데이터를 Realm에 저장하기
        self.saveStoreData(storePrices)
    }
    
    private func saveStoreData<T: Object>(_ object: T) {
        // 데이터를 저장하기 전, 기존 데이터 삭제하기
        realmManager.deleteAll(of: T.self)
        // 새로운 데이터 저장하기
        realmManager.create(object)
    }
    
    @MainActor
    private func downloadWeaponSkinImages() async throws {
        // Realm으로부터 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.skins else { return }
        
        // 경로 접근을 위한 파일 매니저 선언하기
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 경로에 이미지가 저장되지 않은 스킨 UUID값 저장하기
        var notDownloadedImages: [(imageType: ImageType, uuid: String)] = []
        
        // 스킨 데이터를 순회하며 저장되지 않은 스킨 이미지 UUID값 솎아내기
        for skin in skins {
            // UUID값 저장하기
            guard let uuid = skin.chromas.first?.uuid else { return }
            // 경로 설정하기
            let skinPath = documents.appending(path: makeImageFileName(of: ImageType.weaponSkins, uuid: uuid)).path()
            // 파일 매니저의 경로에 해당 파일이 존재하지 않으면
            if !fileManager.fileExists(atPath: skinPath) {
                // 저장되지 않은 스킨 UUID값 저장하기
                notDownloadedImages.append((ImageType.weaponSkins, uuid))
            }
            
            // 스킨 속 크로마 데이터가 하나라면
            if skin.chromas.count <= 1 { continue /* 이미지를 저장하지 않고 건너뛰기 */ }
            
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
                imageData = try await resourceManager.fetchSkinImageData(
                    of: notDownloadedImage.imageType,
                    uuid: notDownloadedImage.uuid
                ).get()
                // 경로 설정하기
                let saveUrl = documents.appending(path: makeImageFileName(of: imageType, uuid: uuid))
                // 해당 경로에 이미지 파일 저장하기
                try imageData.write(to: saveUrl)
            } catch {
                continue
            }
        }
    }
    
    private func makeImageFileName(of type: ImageType, uuid: String) -> String {
        return "\(type.prefixFileName)-\(uuid).png"
    }
    
    @MainActor
    func fetchPlayerID() async {
        do {
            // 접근 토큰, 등록 정보 및 PUUID값 가져오기
            let reAuthTokens = try await self.fetchReAuthTokens().get()
            // 닉네임, 태그 정보 다운로드하기
            let playerId = try await resourceManager.fetchPlayerID(
                accessToken: reAuthTokens.accessToken,
                riotEntitlement: reAuthTokens.riotEntitlement,
                puuid: reAuthTokens.puuid
            )
            print(playerId)
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    @MainActor
    func fetchStoreRotationWeaponSkins() async {
        // 스킨과 가격 정보를 저장할 배열 변수 선언하기
        var storeRotationWeaponSkins: StoreRotationWeaponkins = StoreRotationWeaponkins()
        // Realm으로부터 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.skins else { return }
        // Realm으로부터 가격 데이터 불러오기
        guard let prices = realmManager.read(of: StorePrices.self).first?.offers else { return }
        
        do {
            // 접근 토큰, 등록 정보 및 PUUID값 가져오기
            let reAuthTokens = try await self.fetchReAuthTokens().get()
            // 오늘의 로테이션 상점 정보 가져오기
            let storefront = try await resourceManager.fetchStorefront(
                accessToken: reAuthTokens.accessToken,
                riotEntitlement: reAuthTokens.riotEntitlement,
                puuid: reAuthTokens.puuid
            ).get()
            
            // 다음 로테이션까지 남은 시간 정보 저장하기
            self.rotationWeaponSkinsRemainingSeconds = storefront.skinsPanelLayout.singleItemOffersRemainingDurationInSeconds
            
            // 상점 로테이션 스킨 필터링하기
            for singleItemUUID in storefront.skinsPanelLayout.singleItemOffers {
                // 스킨 데이터를 저장할 변수 선언하기
                var filteredSkin: Skin?
                // 가격 데이터를 저장할 변수 선언하기
                var filteredPrice: Int?
                // 스킨 데이터 필터링하기
                if let firstSkinIndex = skins.firstIndex(where: {
                    $0.levels.first?.uuid == singleItemUUID }) {
                    filteredSkin = skins[firstSkinIndex]
                }
                // 가격 데이터 필터링하기
                if let firstPriceIndex = prices.firstIndex(where: {
                    $0.offerID == singleItemUUID }) {
                    filteredPrice = prices[firstPriceIndex].cost?.vp
                }
                
                // 필터링한 스킨과 가격 데이터 옵셔널 바인딩하기
                guard let skin = filteredSkin,
                      let price = filteredPrice else {
                    continue
                }
                storeRotationWeaponSkins.weaponSkins.append((skin, price))
            }
            
            // 결과 업데이트하기
            self.storeRotationWeaponSkins = storeRotationWeaponSkins
            
            // 런치 스크린 화면 끄기
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isPresentLaunchScreenView = false
            }

        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
}
