//
//  ViewModel.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI
import Foundation
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
    @AppStorage(UserDefaults.accessTokenExpiryDate) var accessTokenExpiryDate: Double = 0.0
    @AppStorage(UserDefaults.rotatedWeaponSkinsExpiryDate) var rotatedWeaponSkinsExpiryDate: Double = 0.0
    
    // MARK: - WRAPPER PROPERTIES
    
    // For LaunchScreen
    @Published var isPresentLaunchScreenView: Bool = true
    
    // For Login
    @Published var isLoadingLogin: Bool = false
    @Published var loginErrorText: String = ""
    @Published var loginButtonShakeAnimation: CGFloat = 0.0
    
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
    @Published var gameName: String = ""
    @Published var tagLine: String = ""
    
    // For Storefront
    @Published var storeRotationWeaponSkins: StoreRotationWeaponkins = .init()
    var rotationWeaponSkinsRemainingSeconds: Date {
        let calendar = Calendar.current
        let rotatedWeaponSkinsExpiryDate = Date(timeIntervalSinceReferenceDate: rotatedWeaponSkinsExpiryDate)
        let dateComponents = calendar.dateComponents([.second], from: Date.now, to: rotatedWeaponSkinsExpiryDate)
        return calendar.date(from: dateComponents) ?? Date()
    }
    
    // MARK: - PROPERTIES
    
    let oauthManager = OAuthManager.shared
    let realmManager = RealmManager.shared
    let resourceManager = ResourceManager.shared
    let hapticManager = HapticManager.shared
    
    let keychain = Keychain()
    
    var timer: Timer?
    
    // MARK: - INTIALIZER
    
    init() {
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
//            // self 키워드 옵셔널 바인딩하기
//            guard let self = self else { return }
//            // 다음 상점 로테이션까지 남은 초(sec)가 0 이상이라면
//            if self.rotationWeaponSkinsRemainingSeconds > 0 {
//                self.rotationWeaponSkinsRemainingSeconds -= 1
//            }
//        })
    }
    
    // MARK: - FUNCTIONS
    
    @MainActor
    func login(username: String, password: String) async {
        do {
            // 로딩 버튼 보이게 하기
            withAnimation(.spring()) { self.isLoadingLogin = true }
            
            // ID와 패스워드로 로그인이 가능한지 확인하기
            let _ = try await oauthManager.fetchAuthCookies().get()
            let _ = try await oauthManager.fetchAccessToken(username: username, password: password).get()
            // 불러온 사용자 고유 정보를 키체인에 저장하기
            let _ = try await self.getReAuthTokens().get()
            
            withAnimation(.spring()) {
                // 로그인에 성공하면 성공 여부 수정하기
                self.isLoggedIn = true
                // 로그인에 성공하면 로딩 버튼 가리기
                self.isLoadingLogin = false
            }
        // 이중 인증이 필요하다면
        } catch OAuthError.needMultifactor(let email) {
            // 인증 이메일을 뷰에 표시하기
            self.multifactorAuthEmail = email
            // 이중 인증 화면 보이게 하기
            self.isPresentMultifactorAuthView = true
            // 로그인에 성공하면 로딩 버튼 가리기
            withAnimation(.spring()) { self.isLoadingLogin = false }
        // HTTP 통신에 실패한다면
        } catch OAuthError.statusCodeError {
            // 에러 메시지 출력하기
            self.loginErrorText = "서버에 연결하는 데 문제가 발생하였습니다."
            // 에러 햅틱 피드백 전달하기
            hapticManager.notify(.error)
            // 로그인에 성공하면 로딩 버튼 가리기
            withAnimation(.spring()) { self.isLoadingLogin = false }
            // 로그인 버튼에 흔들기 애니메이션 적용하기
            withAnimation(.spring()) { self.loginButtonShakeAnimation += 1.0 }
        // 토큰을 발급받을 수 없다면
        } catch OAuthError.noTokenError {
            // 에러 메시지 출력하기
            self.loginErrorText = "계정이름과 비밀번호가 일치하지 않습니다."
            // 에러 햅틱 피드백 전달하기
            hapticManager.notify(.error)
            // 로그인에 성공하면 로딩 버튼 가리기
            withAnimation(.spring()) { self.isLoadingLogin = false }
            // 로그인 버튼에 흔들기 애니메이션 적용하기
            withAnimation(.spring()) { self.loginButtonShakeAnimation += 1.0 }
        } catch {
            // 에러 햅틱 피드백 전달하기
            hapticManager.notify(.error)
            // 로그인에 성공하면 로딩 버튼 가리기
            withAnimation(.spring()) { self.isLoadingLogin = false }
            // 로그인 버튼에 흔들기 애니메이션 적용하기
            withAnimation(.spring()) { self.loginButtonShakeAnimation += 1.0 }
        }
    }
    
    @MainActor
    func login(authenticationCode code: String) async {
        do {
            // 이중 인증 코드로 로그인이 가능한지 확인하기
            let _ = try await oauthManager.fetchMultifactorAuth(authenticationCode: code).get()
            // 불러온 사용자 고유 정보를 키체인에 저장하기
            let _ = try await self.getReAuthTokens().get()
            // 로그인에 성공하면 성공 여부 수정하기
            self.isLoggedIn = true
        } catch {
            print(error)
            // 로그인에 실패하면 예외 처리하기
        }
    }
    
    func logout() {
        // 새로운 세션 할당하기
        oauthManager.urlSession = URLSession(configuration: .ephemeral)
        resourceManager.urlSession = URLSession.shared
        
        // 쿠키 정보 및 사용자 고유 정보 삭제하기
        try? keychain.removeAll()
        
        // 로그인 여부 및 사용자 정보 삭제하기
        self.isLoggedIn = false
        self.accessTokenExpiryDate = 0.0
        
        // 커스탬 탭 선택 초기화하기
        self.selectedCustomTab = .shop
        // 불러온 상점 데이터 삭제하기
        self.storeRotationWeaponSkins = .init()
        // 런치 스크린 표시 여부 수정하기
        self.isPresentLaunchScreenView = true
    }
    
    private func getReAuthTokens() async -> Result<ReAuthTokens, OAuthError> {
        // ⭐️ 최초 로그인을 하면 사용자 고유 정보를 불러온 후, 키체인에 저장함.
        // ⭐️ 이후 HTTP 통신을 위해 사용자 고유 정보가 필요하다면 키체인에 저장된 데이터를 불러와 사용함.
        // ⭐️ 만약 토큰이 만료된다면 새롭게 사용자 고유 정보를 불러온 후, 키체인에 저장함.
        // ⭐️ 이를 통해, 앱의 로딩 속도를 비약적으로 상승시킬 수 있었음.
        
        // 키체인에 저장된 사용자 고유 정보가 있다면
        if let accessToken = try? keychain.get(Keychains.accessToken),
           let riotEntitlement = try? keychain.get(Keychains.riotEntitlement),
           let puuid = try? keychain.get(Keychains.puuid) {
            // 현재 날짜 불러오기
            let currentDate = Date().timeIntervalSinceReferenceDate            
            // 토큰이 만료되었다면
            if currentDate > accessTokenExpiryDate {
                do {
                    // 새롭게 접근 토큰 등 사용자 고유 정보 불러오기
                    let reAuthTokens = try await self.fetchReAuthTokens().get()
                    // 저장된 사용자 고유 정보 반환하기
                    return .success(reAuthTokens)
                } catch {
                    // 토큰 정보 불러오기에 실패하면 예외 던지기
                    return .failure(.noTokenError)
                }
            }
            
            let reAuthTokens = ReAuthTokens(
                accessToken: accessToken,
                riotEntitlement: riotEntitlement,
                puuid: puuid
            )
            // 저장된 사용자 고유 정보 반환하기
            return .success(reAuthTokens)
            
        // 키체인에 저장된 사용자 고유 정보가 없다면
        } else {
            do {
                // 새롭게 접근 토큰 등 사용자 고유 정보 불러오기
                let reAuthTokens = try await self.fetchReAuthTokens().get()
                // 저장된 사용자 고유 정보 반환하기
                return .success(reAuthTokens)
            } catch {
                // 토큰 정보 불러오기에 실패하면 예외 던지기
                return .failure(.noTokenError)
            }
        }
    }
    
    @MainActor
    func fetchReAuthTokens() async throws -> Result<ReAuthTokens, OAuthError> {
        do {
            // 새롭게 접근 토큰 등 사용자 고유 정보 불러오기
            let accessToken: String = try await oauthManager.fetchReAuthCookies().get()
            let riotEntitlement: String = try await oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
            let puuid: String = try await oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
            // 불러온 사용자 고유 정보를 키체인에 저장하기
            keychain[Keychains.accessToken] = accessToken
            keychain[Keychains.riotEntitlement] = riotEntitlement
            keychain[Keychains.puuid] = puuid
            // 토큰 만료 시간을 UserDefaults에 저장하기
            accessTokenExpiryDate = Date().addingTimeInterval(3600.0).timeIntervalSinceReferenceDate
            
            let reAuthTokens = ReAuthTokens(
                accessToken: accessToken,
                riotEntitlement: riotEntitlement,
                puuid: puuid
            )
            // 저장된 사용자 고유 정보 반환하기
            return .success(reAuthTokens)
        } catch {
            // 토큰 정보 불러오기에 실패하면 예외 던지기
            return .failure(.noTokenError)
        }
    }
    
    @MainActor
    func downloadValorantData(reload: Bool = false) async {
        do {
            // ⭐️ 새로운 스킨 데이터가 삭제되는(덮어씌워지는) 와중에 뷰에서는 삭제된 데이터에 접근하고 있기 때문에
            // ⭐️ 'Realm object has been deleted or invalidated' 에러가 발생함. 이를 막기 위해 다운로드 동안 뷰에 표시할 데이터를 삭제함.
            self.storeRotationWeaponSkins.weaponSkins = []
            // 발로란트 버전 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadValorantVersion()
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
    private func downloadValorantVersion() async throws {
        // 발로란트 버전 데이터 다운로드받기
        let valorantVersion = try await resourceManager.fetchValorantVersion().get()
        // 발로란트 버전 데이터를 Realm에 저장하기
        self.saveStoreData(valorantVersion)
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
        let reAuthTokens = try await self.getReAuthTokens().get()
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
    func checkValorantVersion() async {
        do {
            // DB에 저장되어 있는 (구)버전 데이터 불러오기
            guard let oldVersion = realmManager.read(of: Version.self).first else { return }
            // 서버에 저장되어 있는 (신)버전 데이터 불러오기
            let newVersion = try await resourceManager.fetchValorantVersion().get()
            // 버전을 비교한 결과 서로 다르다면
            if oldVersion.client?.riotClientVersion != newVersion.client?.riotClientVersion ||
               oldVersion.client?.riotClientBuild != newVersion.client?.riotClientBuild ||
               oldVersion.client?.buildDate != newVersion.client?.buildDate
            {
                // 다운로드 화면이 보이게 하기
                self.isPresentDownloadView = true
            }
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    @MainActor
    func fetchPlayerID() async {
        do {
            // 접근 토큰, 등록 정보 및 PUUID값 가져오기
            let reAuthTokens = try await self.getReAuthTokens().get()
            // 닉네임, 태그 정보 다운로드하기
            let playerId = try await resourceManager.fetchPlayerID(
                accessToken: reAuthTokens.accessToken,
                riotEntitlement: reAuthTokens.riotEntitlement,
                puuid: reAuthTokens.puuid
            ).get()
            // 결과 업데이트하기
            self.gameName = playerId.gameName
            self.tagLine = playerId.tagLine
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    @MainActor
    func fetchStoreRotationWeaponSkins() async {
        
        // 현재 날짜 불러오기
        let currentDate = Date().timeIntervalSinceReferenceDate
        print("현재 닐짜: \(Date(timeIntervalSinceReferenceDate: currentDate))")
        print("다음 갱신 날짜: \(Date(timeIntervalSinceReferenceDate: rotatedWeaponSkinsExpiryDate))")
        
        
        // Realm에 저장된 로테이션 스킨 데이터 불러오기
        let rotatedWeaponSkins = realmManager.read(of: RotatedWeaponSkins.self)
        // Realm에 저장된 로테이션 스킨 데이터가 있다면
        if !rotatedWeaponSkins.isEmpty {
            print("스킨 데이터 있음")
            // 현재 날짜 불러오기
            let currentDate = Date().timeIntervalSinceReferenceDate
            // 로테이션 갱신 시간이 지났다면
            if currentDate > rotatedWeaponSkinsExpiryDate {
                print("스킨 데이터 갱신 필요!")
                // 로테이션 스킨 데이터 초기화하기
                self.storeRotationWeaponSkins = .init()
                do {
                    // 접근 토큰 등 사용자 고유 정보 가져오기
                    let reAuthTokens = try await self.getReAuthTokens().get()
                    // 새롭게 로테이션 스킨 데이터 불러오기
                    let rotatedWeaponSkins = try await resourceManager.fetchStorefront(
                        accessToken: reAuthTokens.accessToken,
                        riotEntitlement: reAuthTokens.riotEntitlement,
                        puuid: reAuthTokens.puuid
                    ).get().skinsPanelLayout
                    // 로테이션 갱신 시간을 UserDefaults에 저장하기
                    self.rotatedWeaponSkinsExpiryDate = Date().addingTimeInterval(
                        Double(rotatedWeaponSkins.singleItemOffersRemainingDurationInSeconds)
                    ).timeIntervalSinceReferenceDate
                    // Realm에 새로운 로테이션 스킨 데이터 저장하기 (스킨의 첫 번째 레벨의 UUID)
                    for uuid in rotatedWeaponSkins.singleItemOffers {
                        let rotatedWeaponSkins = RotatedWeaponSkins(value: ["uuid": "\(uuid)"])
                    }
                } catch {
                    return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                }
            }
        // Realm에 로테이션 스킨 데이터가 없다면
        } else {
            print("스킨 데이터 없음!")
            do {
                // 접근 토큰 등 사용자 고유 정보 가져오기
                let reAuthTokens = try await self.getReAuthTokens().get()
                // 새롭게 로테이션 스킨 데이터 불러오기
                let rotatedWeaponSkins = try await resourceManager.fetchStorefront(
                    accessToken: reAuthTokens.accessToken,
                    riotEntitlement: reAuthTokens.riotEntitlement,
                    puuid: reAuthTokens.puuid
                ).get().skinsPanelLayout
                // 로테이션 갱신 시간을 UserDefaults에 저장하기
                self.rotatedWeaponSkinsExpiryDate = Date().addingTimeInterval(
                    Double(rotatedWeaponSkins.singleItemOffersRemainingDurationInSeconds)
                ).timeIntervalSinceReferenceDate
                // Realm에 새로운 로테이션 스킨 데이터 저장하기 (스킨의 첫 번째 레벨의 UUID)
                for uuid in rotatedWeaponSkins.singleItemOffers {
                    let rotatedWeaponSkins = RotatedWeaponSkins(value: ["uuid": "\(uuid)"])
                    realmManager.create(rotatedWeaponSkins)
                }
            } catch {
                return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
            }
        }
        
        print("스킨 필터링 시작!")
        // 스킨과 가격 정보를 저장할 배열 변수 선언하기
        var storeRotationWeaponSkins: StoreRotationWeaponkins = StoreRotationWeaponkins()
        // Realm으로부터 로테이션 스킨 데이터 불러오기
        let weaponSkinUUIDs = realmManager.read(of: RotatedWeaponSkins.self)
        // Realm으로부터 전체 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.skins else { return }
        // Realm으로부터 가격 데이터 불러오기
        guard let prices = realmManager.read(of: StorePrices.self).first?.offers else { return }
        
        
        // 상점 로테이션 스킨 필터링하기
        for weaponSkinUUID in weaponSkinUUIDs {
            // 스킨 데이터를 저장할 변수 선언하기
            var filteredSkin: Skin?
            // 가격 데이터를 저장할 변수 선언하기
            var filteredPrice: Int?
            // 스킨 데이터 필터링하기
            if let firstSkinIndex = skins.firstIndex(where: {
                $0.levels.first?.uuid == weaponSkinUUID.uuid }) {
                filteredSkin = skins[firstSkinIndex]
            }
            // 가격 데이터 필터링하기
            if let firstPriceIndex = prices.firstIndex(where: {
                $0.offerID == weaponSkinUUID.uuid }) {
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
    }
    
}
