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

// MARK: - ENUM

enum ExpiryDateTye {
    case token
    case skin
    case bundle
    case bonus
}

enum ReloadDataType {
    case skin
    case bndle
    case bonus
}

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
    @AppStorage(UserDefaults.lastUpdateCheckDate) var lastUpdateCheckDate: Double = 0.0
    @AppStorage(UserDefaults.accessTokenExpiryDate) var accessTokenExpiryDate: Double = 0.0
    @AppStorage(UserDefaults.rotatedWeaponSkinsRenewalDate) var rotatedWeaponSkinsExpiryDate: Double = 0.0
    
    // MARK: - WRAPPER PROPERTIES
    
    // For LaunchScreen
    @Published var isPresentLoadingScreenView: Bool = true
    
    // For Login
    @Published var isLoadingLogin: Bool = false
    @Published var loginErrorText: String = ""
    @Published var loginButtonShakeAnimation: CGFloat = 0.0
    
    // For MultifactorAuth
    @Published var isLoadingMultifactor: Bool = false
    @Published var isPresentMultifactorAuthView: Bool = false
    @Published var multifactorAuthEmail: String = ""
    @Published var multifactorErrorText: String = ""
    @Published var codeBoxShakeAnimation: CGFloat = 0.0
    
    // For CustomTab
    @Published var selectedCustomTab: CustomTabType = .shop
    
    // For Downlaod Data
    @Published var isLoadingDataDownloading: Bool = false
    @Published var isPresentDataDownloadView: Bool = false
    @Published var isPresentDataUpdateView: Bool = false
    @Published var downloadingErrorText: String = ""
    @Published var downloadButtonShakeAnimation: CGFloat = 0.0
    
    
    @Published var totalImagesToDownload: Int = 0
    @Published var imagesDownloadedCount: Int = 0
    
    // For PlayerID
    @Published var gameName: String = ""
    @Published var tagLine: String = ""
    
    // For PlayerWallet
    @Published var rp: Int = 0
    @Published var vp: Int = 0
    @Published var kp: Int = 0
    
    // For StoreData
    @Published var storeRotationWeaponSkins: StoreRotationWeaponkins = .init()
    @Published var storeRotationWeaponSkinsRemainingSeconds: String = ""
    
    // For StoreView
    @Published var selectedStoreTab: StoreTabType = .skin
    @Published var refreshButtonRotateAnimation: Bool = false
    
    // MARK: - PROPERTIES
    
    let oauthManager = OAuthManager.shared
    let realmManager = RealmManager.shared
    let resourceManager = ResourceManager.shared
    let hapticManager = HapticManager.shared
    
    let keychain = Keychain()
    
    weak var timer: Timer?
    let calendar = Calendar.current
    
    // MARK: - INTIALIZER
    
    init() {
        // 현재 날짜 불러오기
        let currentDate = Date()
        // 로테이션 스킨 갱신 날짜 불러오기
        let rotatedWeaponSkinsRenewalDate = Date(timeIntervalSinceReferenceDate: rotatedWeaponSkinsExpiryDate)
        // 현재 날짜부터 갱신 날짜까지 날짜 요소(시/분/초) 차이 구하기
        self.storeRotationWeaponSkinsRemainingSeconds = self.remainingTimeString(from: currentDate, to: rotatedWeaponSkinsRenewalDate)
        
        // 시간을 흐르게 하면서 스킨 데이터 새로고침 확인하기
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true,
            block: updateRotationWeaponSkinsRemainingTime(_:)
        )
    }
    
    // MARK: - LOGIN
    
    @MainActor
    func login(username: String, password: String) async {
        // 로그아웃으로 캐시와 세션 초기화하기
        self.logout()
        
        // 계정이름과 비밀번호가 입력되었는지 확인하기
        guard !username.isEmpty, !password.isEmpty else {
            // 에러 햅틱 피드백 전달하기
            hapticManager.notify(.error)
            // 에러 메시지 출력하기
            self.loginErrorText = "계정이름과 비밀번호를 입력해주세요."
            // 로그인 버튼에 흔들기 애니메이션 적용하기
            withAnimation(.spring()) { self.loginButtonShakeAnimation += 1.0 }
            return
        }
        
        do {
            // 로딩 버튼 보이게 하기
            withAnimation(.spring()) { self.isLoadingLogin = true }
            
            // ID와 패스워드로 로그인이 가능한지 확인하기
            let _ = try await oauthManager.fetchAuthCookies().get()
            let _ = try await oauthManager.fetchAccessToken(username: username, password: password).get()
            // 불러온 사용자 고유 정보를 키체인에 저장하기
            let _ = try await self.getReAuthTokens().get()
            
            withAnimation(.spring()) {
                // 로그인에 성공하면 로딩 버튼 가리기
                self.isLoadingLogin = false
                // 데이터 다운로드를 이미 했다면
                if isDataDownloaded {
                    // 로그인에 성공하면 성공 여부 수정하기
                    self.isLoggedIn = true
                // 데이터 다운로드를 해야 한다면
                } else {
                    // 다운로드 화면 보이게 하기
                    self.isPresentDataDownloadView = true
                }
            }
        // 이중 인증이 필요하다면
        } catch OAuthError.needMultifactor(let email) {
            // 인증 이메일을 뷰에 표시하기
            self.multifactorAuthEmail = email
            // 이중 인증 화면 보이게 하기
            withAnimation(.spring()) { self.isPresentMultifactorAuthView = true }
        // HTTP 통신에 실패한다면
        } catch OAuthError.networkError, OAuthError.statusCodeError {
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
            // 로딩 보이게 하기
            withAnimation(.spring()) { self.isLoadingMultifactor = true }
            
            // 이중 인증 코드로 로그인이 가능한지 확인하기
            let _ = try await oauthManager.fetchMultifactorAuth(authenticationCode: code).get()
            // 불러온 사용자 고유 정보를 키체인에 저장하기
            let _ = try await self.getReAuthTokens().get()
            
            withAnimation(.spring()) {
                // 로그인에 성공하면 로딩 버튼 가리기
                self.isLoadingLogin = false
                // 이중 인증 로딩 가리기
                self.isLoadingMultifactor = false
                // 이중 인증 화면 안 보이게 하기
                self.isPresentMultifactorAuthView = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.spring()) {
                        // 데이터 다운로드를 이미 했다면
                        if self.isDataDownloaded {
                            // 로그인에 성공하면 성공 여부 수정하기
                            self.isLoggedIn = true
                        // 데이터 다운로드를 해야 한다면
                        } else {
                            // 다운로드 화면 보이게 하기
                            self.isPresentDataDownloadView = true
                        }
                    }
                }
            }
        } catch {
            // 에러 햅틱 피드백 전달하기
            hapticManager.notify(.error)
            // 이중 인증 로딩 가리기
            withAnimation(.spring()) { self.isLoadingMultifactor = false }
            // 텍스트 필드에 흔들기 애니메이션 적용하기
            withAnimation(.spring()) { self.codeBoxShakeAnimation += 1.0 }
            // 에러 메시지 출력하기
            self.multifactorErrorText = "로그인 코드가 일치하지 않습니다."
            
        }
    }
    
    // MARK: - LOGOUT
    
    func logout() {
        // 새로운 세션 할당하기
        oauthManager.urlSession = URLSession(configuration: .ephemeral)
        resourceManager.urlSession = URLSession.shared
        
        // 쿠키 정보 및 사용자 고유 정보 삭제하기
        try? keychain.removeAll()
        
        // 로그인 여부 및 사용자 정보 삭제하기
        self.isLoggedIn = false
        self.accessTokenExpiryDate = 0.0
        self.rotatedWeaponSkinsExpiryDate = 0.0
        self.realmManager.deleteAll(of: PlayerID.self)
        self.realmManager.deleteAll(of: PlayerWallet.self)
        self.realmManager.deleteAll(of: RotatedWeaponSkins.self)
        
        // 커스탬 탭 선택 초기화하기
        self.selectedCustomTab = .shop
        // 불러온 상점 데이터 삭제하기
        self.storeRotationWeaponSkins = .init()
        // 런치 스크린 표시 여부 수정하기
        self.isPresentLoadingScreenView = true
    }
    
    // MARK: - REAUTH TOKENS
    
    private func getReAuthTokens() async -> Result<ReAuthTokens, OAuthError> {
        // ⭐️ 최초 로그인을 하면 사용자 고유 정보를 불러온 후, 키체인에 저장함.
        // ⭐️ 이후 HTTP 통신을 위해 사용자 고유 정보가 필요하다면 키체인에 저장된 데이터를 불러와 사용함.
        // ⭐️ 만약 토큰이 만료된다면 새롭게 사용자 고유 정보를 불러온 후, 키체인에 저장함.
        // ⭐️ 이를 통해, 앱의 로딩 속도를 비약적으로 상승시킬 수 있었음.
        
        // 키체인에 저장된 사용자 고유 정보가 있다면
        if let accessToken = try? keychain.get(Keychains.accessToken),
           let riotEntitlement = try? keychain.get(Keychains.riotEntitlement),
           let puuid = try? keychain.get(Keychains.puuid) {
            // 토큰이 만료되었다면
            if self.isExpired(of: .token) {
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
    
    // MARK: - DOWNLOAD DATA
    
    @MainActor
    func downloadValorantData(update: Bool = false) async {
        do {
            // 로딩 버튼 보이게 하기
            withAnimation(.spring()) { self.isLoadingDataDownloading = true }
            //
            self.totalImagesToDownload = 3
            // ⭐️ 새로운 스킨 데이터가 삭제되는(덮어씌워지는) 와중에 뷰에서는 삭제된 데이터에 접근하고 있기 때문에
            // ⭐️ 'Realm object has been deleted or invalidated' 에러가 발생함. 이를 막기 위해 다운로드 동안 뷰에 표시할 데이터를 삭제함.
            self.storeRotationWeaponSkins.weaponSkins = []
            // 발로란트 버전 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadValorantVersion(); self.imagesDownloadedCount += 1
            // 무기 스킨 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadWeaponSkinsData(); self.imagesDownloadedCount += 1
            // 가격 정보 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadStorePricesData(); self.imagesDownloadedCount += 1
            // 스킨 이미지 데이터 다운로드받고, 로컬 Document 폴더에 저장하기
            try await self.downloadWeaponSkinImages()
            // 스킨 데이터를 업데이트하면
            // ✏️ 최초 다운로드를 끝내면 onAppear로 자동으로 스킨 데이터를 불러올 수 있는 반면에,
            // ✏️ 데이터 업데이트를 하면 스킨 데이터를 갱신할 수 있는 수단이 전무하기 때문에 명시적으로 호출함.
            if update {
                // 로테이션 스킨 데이터 불러오기
                await self.getStoreRotationWeaponSkins()
                // + 번들 스킨 데이터 불러오기
                // + 야시장 스킨 데이터 불러오기
            }
            
            withAnimation(.spring()) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.spring()) {
                        // 로그인에 성공하면 성공 여부 수정하기
                        self.isLoggedIn = true
                        // 다운로드를 모두 마치면 성공 여부 수정하기
                        self.isDataDownloaded = true
                        // 로딩 버튼 가리기
                        self.isLoadingDataDownloading = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        // 다운로드 화면을 가리기
                        self.isPresentDataDownloadView = false
                        // ✏️ false로 수정해주지 않으면 상점 화면에서 다운로드 시트가 나타남.
                        // ✏️ 0.75초 지연하는 이유는 팝 내비게이션 스택 애니메이션이 보이게 하지 않기 위함.
                    }
                }
            }
        } catch {
            withAnimation(.spring()) {
                // 로딩 버튼 가리기
                self.isLoadingDataDownloading = false
                // 다운로드 버튼에 흔들기 애니메이션 적용하기
                self.downloadButtonShakeAnimation += 1.0
            }
            // 에러 햅틱 피드백 전달하기
            hapticManager.notify(.error)
            // 에러 메시지 출력하기
            self.downloadingErrorText = "서버에 연결하는 데 문제가 발생하였습니다."
        }
    }
    
    @MainActor
    private func downloadValorantVersion() async throws {
        // 발로란트 버전 데이터 다운로드받기
        let valorantVersion = try await resourceManager.fetchValorantVersion().get()
        // 발로란트 버전 데이터를 Realm에 저장하기
        self.overwriteRealmObject(valorantVersion)
    }
    
    @MainActor
    private func downloadWeaponSkinsData() async throws {
        // 무기 스킨 데이터 다운로드받기
        let weaponSkins = try await resourceManager.fetchWeaponSkins().get()
        // 무기 스킨 데이터를 Realm에 저장하기
        self.overwriteRealmObject(weaponSkins)
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
        self.overwriteRealmObject(storePrices)
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
        self.totalImagesToDownload = notDownloadedImages.count
        
        // 이미지를 다운로드해 Documents 폴더에 저장하기
        for notDownloadedImage in notDownloadedImages {
            // 다운로드한 이미지 데이터를 저장하는 변수 선언하기
            var imageData: Data
            // 다운로드 한 이미지 개수 증가시키기
            self.imagesDownloadedCount += 1
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
    
    // MARK: - CHECK VERSION
    
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
                // ⭐️ 링크 에러는 아니지만 편의를 위해 임시로 링크 에러를 던짐.
                throw ResourceError.urlError
                // ✏️ 새로운 버전 데이터는 다운로드 화면에서 한꺼번에 다운 받음.
            }
            // 최근 업데이트 확인 갱신하기
            self.lastUpdateCheckDate = Date().timeIntervalSinceReferenceDate
        // 버전을 비교한 결과 서로 다르다면
        } catch ResourceError.urlError {
            // 업데이트 화면이 보이게 하기
            self.isPresentDataUpdateView = true
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    // MARK: - GET PLAYER DATA
    
    @MainActor
    func reloadPlayerData(of type: ReloadDataType) async {
        // 로딩 애니메이션 시작하기
        withAnimation(.spring(dampingFraction: 0.3)) { self.refreshButtonRotateAnimation = true }
        // 사용자 지갑 데이터 불러오기
        await getPlayerWallet(reload: true)
        // 어느 데이터를 불러올지 확인하기
        switch type {
        case .skin:
            await self.getStoreRotationWeaponSkins(reload: true)
        case .bndle:
            fallthrough // 임시
        case .bonus:
            break // 임시
        }
        // 로딩 애니메이션 끝내기
        self.refreshButtonRotateAnimation = false
    }
    
    @MainActor
    func getPlayerID(reload: Bool = false) async {
        // Realm에 저장된 사용자ID 데이터 불러오기
        var playerID = realmManager.read(of: PlayerID.self)
        // 강제로 다시 불러오지 안는다면
        if !reload {
            // Realm에 저장된 로테이션 스킨 데이터가 있다면
            if !playerID.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .skin) {
                    do {
                        // 사용자ID 데이터를 불러와 Realm에 저장하기
                        try await self.fetchPlayerID()
                    } catch {
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                }
            // Realm에 저장된 로테이션 스킨 데이터가 없다면
            } else {
                do {
                    // 사용자ID 데이터를 불러와 Realm에 저장하기
                    try await self.fetchPlayerID()
                } catch {
                    return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                }
            }
            // Realm에 저장된 사용자ID 데이터 다시 불러오기
            playerID = realmManager.read(of: PlayerID.self)
        // 강제로 다시 불러온다면
        } else {
            do {
                try await self.fetchPlayerID()
            } catch {
                return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
            }
            // Realm에 저장된 사용자ID 데이터 다시 불러오기
            playerID = realmManager.read(of: PlayerID.self)
        }
        
        // 사용자 닉네임 불러오기
        guard let gameName = playerID.first?.gameName else { return }
        // 사용자 태그 불러오기
        guard let tagLine = playerID.first?.tagLine else { return }
        // 결과 업데이트
        self.gameName = gameName
        self.tagLine = tagLine
    }
    
    @MainActor
    private func fetchPlayerID() async throws {
        // Realm에 저장되어 있는 기존 사용자ID 데이터 삭제하기
        realmManager.deleteAll(of: RotatedWeaponSkins.self)
        // 접근 토큰 등 사용자 고유 정보 가져오기
        let reAuthTokens = try await self.getReAuthTokens().get()
        // 닉네임, 태그 정보 다운로드하기
        let id = try await resourceManager.fetchPlayerID(
            accessToken: reAuthTokens.accessToken,
            riotEntitlement: reAuthTokens.riotEntitlement,
            puuid: reAuthTokens.puuid
        ).get()
        // Realm에 새로운 사용자ID 데이터 저장하기
        realmManager.create(id)
    }
    
    @MainActor
    func getPlayerWallet(reload: Bool = false) async {
        // Realm에 저장된 사용자 지갑 데이터 불러오기
        var playerWallet = realmManager.read(of: PlayerWallet.self)
        // 강제로 다시 불러오지 안는다면
        if !reload {
            // Realm에 저장된 사용자 지갑 데이터가 없다면
            if playerWallet.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .skin) {
                    do {
                        // 사용자 지갑 데이터를 불러와 Realm에 저장하기
                        try await self.fetchPlayerWallet()
                    } catch {
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                // Realm에 저장된 로테이션 스킨 데이터가 없다면
                } else {
                    do {
                        // 사용자 지갑 데이터를 불러와 Realm에 저장하기
                        try await self.fetchPlayerWallet()
                    } catch {
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                }
                // Realm에 저장된 사용자ID 데이터 다시 불러오기
                playerWallet = realmManager.read(of: PlayerWallet.self)
            }
        // 강제로 다시 불러온다면
        } else {
            do {
                // 사용자 지갑 데이터를 불러와 Realm에 저장하기
                try await self.fetchPlayerWallet()
            } catch {
                return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
            }
            // Realm에 저장된 사용자 지갑 데이터 다시 불러오기
            playerWallet = realmManager.read(of: PlayerWallet.self)
        }
        
        // 발로란트 포인트(VP) 불러오기
        guard let vp = playerWallet.first?.balances?.vp else { return }
        // 레디어나이트 포인트(RP) 불러오기
        guard let rp = playerWallet.first?.balances?.rp else { return }
        // 킹덤 포인트(KP) 불러오기
        guard let kp = playerWallet.first?.balances?.kp else { return }
        
        // 결과 업데이트
        self.vp = vp
        self.rp = rp
        self.kp = kp
    }
    
    @MainActor
    private func fetchPlayerWallet() async throws {
        // Realm에 저장되어 있는 기존 사용자 지갑 데이터 삭제하기
        realmManager.deleteAll(of: PlayerWallet.self)
        // 접근 토큰 등 사용자 고유 정보 가져오기
        let reAuthTokens = try await self.getReAuthTokens().get()
        // 사용자 지갑 정보 다운로드하기
        let wallet = try await resourceManager.fetchUserWallet(
            accessToken: reAuthTokens.accessToken,
            riotEntitlement: reAuthTokens.riotEntitlement,
            puuid: reAuthTokens.puuid
        ).get()
        // Realm에 새로운 사용자 지갑 데이터 저장하기
        realmManager.create(wallet)
    }
    
    @MainActor
    func getStoreRotationWeaponSkins(reload: Bool = false) async {
        // Realm에 저장된 로테이션 스킨 데이터 불러오기
        let rotatedWeaponSkins = realmManager.read(of: RotatedWeaponSkins.self)
        // 강제로 다시 불러오지 안는다면
        if !reload {
            // Realm에 저장된 로테이션 스킨 데이터가 있다면
            if !rotatedWeaponSkins.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .skin) {
                    do {
                        // 로테이션 스킨 데이터를 불러와 Realm에 저장하기
                        try await self.fetchStoreRotationWeaponSkins()
                    } catch {
                        self.isPresentLoadingScreenView = false
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                }
            // Realm에 로테이션 스킨 데이터가 없다면
            } else {
                do {
                    // 로테이션 스킨 데이터를 불러와 Realm에 저장하기
                    try await self.fetchStoreRotationWeaponSkins()
                } catch {
                    self.isPresentLoadingScreenView = false
                    return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                }
            }
        // 강제로 다시 불러온다면
        } else {
            do {
                // 로테이션 스킨 데이터를 불러와 Realm에 저장하기
                try await self.fetchStoreRotationWeaponSkins()
            } catch {
                self.isPresentLoadingScreenView = false
                return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
            }
        }
        
        // 스킨과 가격 정보를 저장할 배열 변수 선언하기
        var storeRotationWeaponSkins: StoreRotationWeaponkins = StoreRotationWeaponkins()
        // Realm으로부터 로테이션 스킨 데이터 불러오기
        let weaponSkinUUIDs = realmManager.read(of: RotatedWeaponSkins.self)
        // Realm으로부터 전체 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.skins else {
            self.isPresentLoadingScreenView = false
            return
        }
        // Realm으로부터 가격 데이터 불러오기
        guard let prices = realmManager.read(of: StorePrices.self).first?.offers else {
            self.isPresentLoadingScreenView = false
            return
        }
        
        
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
            self.isPresentLoadingScreenView = false
        }
    }
    
    @MainActor
    private func fetchStoreRotationWeaponSkins() async throws {
        // Realm에 저장되어 있는 기존 로테이션 스킨 데이터 삭제하기
        realmManager.deleteAll(of: RotatedWeaponSkins.self)
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
    }
    
    private func isExpired(of type: ExpiryDateTye) -> Bool {
        // 현재 날짜 불러오기
        let currentDate = Date().timeIntervalSinceReferenceDate
        // 체크해야 할 갱신 시간 체크하기
        switch type {
        case .token:
            // 토큰 갱신 시간이 지났다면
            return currentDate > accessTokenExpiryDate ? true : false
        case .skin:
            // 로테이션 갱신 시간이 지났다면
            return currentDate > rotatedWeaponSkinsExpiryDate ? true : false
        case .bundle:
            return false // + 임시
        case .bonus:
            return false // + 임시
        }
    }
    
    // MARK: - REALM CRUD
    
    private func overwriteRealmObject<T: Object>(_ object: T) {
        // 데이터를 저장하기 전, 기존 데이터 삭제하기
        realmManager.deleteAll(of: T.self)
        // 새로운 데이터 저장하기
        realmManager.create(object)
    }
    
    // MARK: - TIMER
    
    @objc func updateRotationWeaponSkinsRemainingTime(_ timer: Timer? = nil) {
        // 로그인이 되어 있으면
        if self.isLoggedIn {
            // 현재 날짜 불러오기
            let currentDate = Date()
            // 로테이션 스킨 갱신 날짜 불러오기
            let rotatedWeaponSkinsRenewalDate = Date(timeIntervalSinceReferenceDate: rotatedWeaponSkinsExpiryDate)
            
            // 로테이션 스킨 갱신 날짜에 다다르면
            if currentDate > rotatedWeaponSkinsRenewalDate && self.isLoggedIn {
                // 사용자ID, 사용자 지갑, 로테이션 스킨 데이터 강제 갱신하기 (새로고침)
                Task {
                    await self.getPlayerID(reload: true)
                    await self.getPlayerWallet(reload: true)
                    await self.getStoreRotationWeaponSkins(reload: true)
                    // ✏️ 로그인이 되어 있지 않은 상태에서 호출된다면 예외가 발생하게 됨.
                    // ✏️ 앱이 켜져 있는 동안 로테이션 스킨 갱신 날짜에 다다르는 경우, 자동으로 갱신시키기 위해 위 코드를 구현함.
                }
            }
            
            // 결과 업데이트하기
            self.storeRotationWeaponSkinsRemainingSeconds = self.remainingTimeString(from: currentDate, to: rotatedWeaponSkinsRenewalDate)
        }
    }
    
    // MARK: - ETC
    
    private func remainingTimeString(from date1: Date, to date2: Date) -> String {
        // 현재 날짜부터 갱신 날짜까지 날짜 요소(시/분/초) 차이 구하기
        let dateComponents = self.calendar.dateComponents(
            [.hour, .minute, .second],
            from: date1,
            to: date2
        )
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        let second = dateComponents.second ?? 0
        
        // 남은 시간 문자열 출력을 위한 숫자 포맷 설정하기
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        // 각 날짜 요소를 숫자 포맷으로 변환하기
        let formattedHour = formatter.string(for: hour) ?? "00"
        let formattedMinute = formatter.string(for: minute) ?? "00"
        let formattedSecond = formatter.string(for: second) ?? "00"
        // 결과 반환하기
        return "\(formattedHour):\(formattedMinute):\(formattedSecond)"
    }
    
}


// MARK: - DEVELOPER MENU

extension ViewModel {
    
    func logoutForDeveloper() {
        self.logout()
    }
    
    func DeleteAllApplicationDataForDeveloper() {
        self.logoutForDeveloper()
        realmManager.deleteAll()
        self.isDataDownloaded = false
    }
    
}
