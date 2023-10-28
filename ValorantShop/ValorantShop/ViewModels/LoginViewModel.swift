//
//  LoginViewModel.swift
//  ValorantShop
//
//  Created by 김건우 on 10/28/23.
//

import SwiftUI
import Foundation
import RealmSwift
import KeychainAccess
import Kingfisher

// MARK: - DELEGATE

protocol LoginViewModelDelegate: NSObject {
    func getReAuthTokens() async -> Result<ReAuthTokens, OAuthError>
    func presentDataUpdateView()
}

// MARK: - VIEW MODEL

final class LoginViewModel: NSObject, ObservableObject {
    
    // MARK: - USER DEFAULTS
    
    @AppStorage(UserDefaultsKeys.isLoggedIn) var isLoggedIn: Bool = false
    @AppStorage(UserDefaultsKeys.isDataDownloaded) var isDataDownloaded: Bool = false
    @AppStorage(UserDefaultsKeys.accessTokenExpiryDate) var accessTokenExpiryDate: Double = Double.infinity
    
    // MARK: - WRAPPER PROPERTIES
    
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
    
    // For Downlaod Data
    @Published var isLoadingDataDownloading: Bool = false
    @Published var isPresentDataDownloadView: Bool = false
    @Published var isPresentDataUpdateView: Bool = false
    @Published var downloadingErrorText: String = ""
    @Published var downloadButtonShakeAnimation: CGFloat = 0.0
    
    @Published var filesToDownload: Int = 0
    @Published var downloadedfiles: Int = 0
    
    // MARK: - PROPERTIES
    
    let keychain = Keychain()
    
    let oauthManager = OAuthManager.shared
    let realmManager = RealmManager.shared
    let resourceManager = ResourceManager.shared
    let hapticManager = HapticManager.shared
    
    // Delegate
    weak var resourceDelegate: ResourceViewModelDelegate?
    weak var appDelegate: AppViewModelDelegate?
    
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
                        // 로그인에 성공하면 로딩 버튼 가리기
                        self.isLoadingLogin = false
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
        resourceManager.urlSession = URLSession(configuration: .default)
        
        // 로그인 여부 및 사용자 정보 삭제하기
        withAnimation(.spring()) { self.isLoggedIn = false }
        
        // 사용자 고유 정보 및 스킨 데이터 삭제하기
        self.resourceDelegate?.clearAllResource()
        
        // 불러온 상점 데이터 삭제하기
        //self.storeSkins = StoreSkin(renewalDate: Date())
        // 불러온 번들 데이터 삭제하기
        //self.storeBundles = StoreBundles()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 탭 선택 초기화하기
            self.appDelegate?.resetSelectedTab()
            // 런치 스크린 표시 여부 수정하기
            self.resourceDelegate?.dismissLoadingView(of: .view)
            // ✏️ 로그아웃 시, 화면이 어색하게 바뀌는 걸 방지하고자 1초 딜레이를 둠.
        }
    }
    
    // MARK: - REAUTH TOKENS
    
    @MainActor
    func getReAuthTokens() async -> Result<ReAuthTokens, OAuthError> {
        // ⭐️ 최초 로그인을 하면 사용자 고유 정보를 불러온 후, 키체인에 저장함.
        // ⭐️ 이후 HTTP 통신을 위해 사용자 고유 정보가 필요하다면 키체인에 저장된 데이터를 불러와 사용함.
        // ⭐️ 만약 토큰이 만료된다면 새롭게 사용자 고유 정보를 불러온 후, 키체인에 저장함.
        // ⭐️ 이를 통해, 앱의 로딩 속도를 비약적으로 상승시킬 수 있었음.
        
        // 키체인에 저장된 사용자 고유 정보가 있다면
        if let accessToken = try? keychain.get(KeychainKeys.accessToken),
           let riotEntitlement = try? keychain.get(KeychainKeys.riotEntitlement),
           let puuid = try? keychain.get(KeychainKeys.puuid) {
            // 토큰이 만료되었다면
            if self.isExpiredToken {
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
    private func fetchReAuthTokens() async throws -> Result<ReAuthTokens, OAuthError> {
        do {
            // 새롭게 접근 토큰 등 사용자 고유 정보 불러오기
            let accessToken: String = try await oauthManager.fetchReAuthCookies().get()
            let riotEntitlement: String = try await oauthManager.fetchRiotEntitlement(accessToken: accessToken).get()
            let puuid: String = try await oauthManager.fetchRiotAccountPUUID(accessToken: accessToken).get()
            // 불러온 사용자 고유 정보를 키체인에 저장하기
            keychain[KeychainKeys.accessToken] = accessToken
            keychain[KeychainKeys.riotEntitlement] = riotEntitlement
            keychain[KeychainKeys.puuid] = puuid
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
            self.filesToDownload = 3
            // ⭐️ 새로운 스킨 데이터가 삭제되는(덮어씌워지는) 와중에 뷰에서는 삭제된 데이터에 접근하고 있기 때문에
            // ⭐️ 'Realm object has been deleted or invalidated' 에러가 발생함. 이를 막기 위해 다운로드 동안 뷰에 표시할 데이터를 삭제함.
            self.resourceDelegate?.clearStorefront()
            // 무기 스킨 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadBundlesData(); self.downloadedfiles += 1
            // 무기 스킨 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadWeaponSkinsData(); self.downloadedfiles += 1
            // 가격 정보 데이터 다운로드받고, Realm에 저장하기
            try await self.downloadStorePricesData(); self.downloadedfiles += 1
            // 스킨 이미지 데이터 다운로드받고, 로컬 Document 폴더에 저장하기
            //try await self.downloadWeaponSkinImages()
            // ✏️ 스킨 데이터를 업데이트하면
            // 앱을 켜면 onAppear로 자동으로 스킨 데이터를 불러올 수 있는 반면에,
            // 데이터 업데이트를 하면 스킨 데이터를 갱신할 수 있는 수단이 전무하기 때문에 명시적으로 호출함.
            if update {
                // 상점 스킨 데이터 불러오기
                await self.resourceDelegate?.getStorefront(forceLoad: true)
            }
            
            withAnimation(.spring()) {
                // 로그인에 성공하면 성공 여부 수정하기
                self.isLoggedIn = true
                // 다운로드를 모두 마치면 성공 여부 수정하기
                self.isDataDownloaded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring()) {
                    Task {
                        // 발로란트 버전 데이터 다운로드받고, Realm에 저장하기
                        try await self.downloadValorantVersion()
                    }
                    
                    // 로딩 버튼 가리기
                    self.isLoadingDataDownloading = false
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
        realmManager.overwrite(valorantVersion)
    }
    
    @MainActor
    private func downloadBundlesData() async throws {
        // 무기 스킨 데이터 다운로드받기
        let bundles = try await resourceManager.fetchBundles().get()
        // 무기 스킨 데이터를 Realm에 저장하기
        realmManager.overwrite(bundles)
    }
    
    @MainActor
    private func downloadWeaponSkinsData() async throws {
        // 무기 스킨 데이터 다운로드받기
        let weaponSkins = try await resourceManager.fetchWeaponSkins().get()
        // 무기 스킨 데이터를 Realm에 저장하기
        realmManager.overwrite(weaponSkins)
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
        realmManager.overwrite(storePrices)
    }
    
}

// MARK: - EXTENSIONS

extension LoginViewModel: LoginViewModelDelegate {
    
    func presentDataUpdateView() {
        self.isPresentDataUpdateView = true
    }
    
}

extension LoginViewModel {
    
    var isExpiredToken: Bool {
        // 현재 날짜 불러오기
        let currentDate = Date().timeIntervalSinceReferenceDate
        // 토큰 갱신 시간 체크하기
        return Date().timeIntervalSinceReferenceDate > accessTokenExpiryDate ? true : false
    }
    
}
