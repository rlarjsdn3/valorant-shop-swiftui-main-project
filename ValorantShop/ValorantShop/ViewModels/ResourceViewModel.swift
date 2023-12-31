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
import Kingfisher

// MARK: - ENUM

enum ExpiryDateTye {
    case token
    case skin
    case bundle
}

enum ReloadDataType {
    case skin
    case bundle
}

enum LoadingViewType {
    case view
    case skinsTimer
    case bundlesTimer
}

// MARK: - MODELS

struct ReAuthTokens {
    let accessToken: String
    let riotEntitlement: String
    let puuid: String
}

// ⭐️ 모든 스킨 관련 데이터를 취합 후, 화면에 출력함.
struct StoreBundle {
    let uuid: String
    let bundleBsePrice: Int
    let bundleDiscountedPrice: Int
    let bundleDiscountedPercent: Double
    let wholeSaleOnly: Bool
    let renewalDate: Date
    var skinInfos: [SkinInfo] = []
}

struct StoreSkin {
    let renewalDate: Date
    var skinInfos: [SkinInfo] = []
}

struct SkinInfo: Identifiable {
    let id: UUID = UUID()
    let skin: Skin
    let price: Price
}

struct Price {
    let basePrice: Int
    let discountedPrice: Int?
    
    init(basePrice: Int, discountedPrice: Int? = nil) {
        self.basePrice = basePrice
        self.discountedPrice = discountedPrice
    }
}

// MARK: - DELEGATE

protocol ResourceViewModelDelegate: NSObject {
    func getStorefront(forceLoad: Bool) async
    func clearStorefront()
    func clearAllResource()
    func dismissLoadingView(of type: LoadingViewType)
}

// MARK: - VIEW MODEL

final class ResourceViewModel: NSObject, ObservableObject {
    
    // MARK: - USER DEFAULTS
    
    @AppStorage(UserDefaultsKeys.isLoggedIn) var isLoggedIn: Bool = false
    @AppStorage(UserDefaultsKeys.isDataDownloaded) var isDataDownloaded: Bool = false
    @AppStorage(UserDefaultsKeys.lastUpdateCheckDate) var lastUpdateCheckDate: Double = Double.infinity
    @AppStorage(UserDefaultsKeys.accessTokenExpiryDate) var accessTokenExpiryDate: Double = Double.infinity
    
    // MARK: - WRAPPER PROPERTIES
    
    // For LaunchScreen
    @Published var isPresentLoadingScreenViewFromView: Bool = true
    @Published var isPresentLoadingScreenViewFromSkinsTimer: Bool = true
    @Published var isPresentLoadingScreenViewFromBundlesTimer: Bool = true
    
    // For PlayerID
    @Published var gameName: String = ""
    @Published var tagLine: String = ""
    
    // For PlayerWallet
    @Published var rp: Int = 0
    @Published var vp: Int = 0
    @Published var kp: Int = 0
    
    // For Collection
    @Published var collections: [SkinInfo] = []
    @Published var ownedWeaponSkins: [SkinInfo] = []
    
    // For StoreData
    @Published var storeSkins: StoreSkin = StoreSkin(renewalDate: Date())
    @Published var storeSkinsRenewalDate: Date = Date(timeIntervalSinceReferenceDate: Double.infinity)
    @Published var storeSkinsRemainingTime: String = ""
    
    @Published var storeBundles: [StoreBundle] = []
    @Published var storeBundlesRenewalDate: [Date] = []
    @Published var storeBundlesReminingTime: [String] = []
    
    // For StoreView
    @Published var refreshButtonRotateAnimation: Bool = false
    
    // For CollectionView
    @Published var isAscendingOrder: Bool = true
    
    // MARK: - PROPERTIES
    
    let keychain = Keychain()
    let imageCache = ImageCache.default
    
    let oauthManager = OAuthManager.shared
    let realmManager = RealmManager.shared
    let resourceManager = ResourceManager.shared
    let hapticManager = HapticManager.shared
    
    // For Timer
    weak var storeSkinsTimer: Timer?
    weak var storeBundlesTimer: Timer?
    let calendar = Calendar.current

    var isIntialGettingStoreSkinsData: Bool = false
    var isAutoReloadedStoreSkinsData: Bool = false
    var isIntialGettingStoreBundlesData: Bool = false
    var isAutoReloadedStoreBundlesData: Bool = false
    
    // Delegate
    weak var loginDelegate: LoginViewModelDelegate?
    
    // MARK: - INTIALIZER
    
    override init() {
        // 이미지 캐시 설정하기
        imageCache.memoryStorage.config.expiration = .seconds(300)
        imageCache.memoryStorage.config.countLimit = 256
        imageCache.memoryStorage.config.totalCostLimit = 128 * 1024 * 1024 // 128MB
        imageCache.memoryStorage.config.keepWhenEnteringBackground = true
        
        imageCache.diskStorage.config.expiration = .days(3)
        imageCache.diskStorage.config.sizeLimit = 512 * 1024 * 1024 // 512MB
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
            self.loginDelegate?.presentDataUpdateView()
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
    }
    
    // MARK: - LOAD PLAYER DATA
    
    @MainActor
    func loadPlayerData() async {
        // ❗️ Task로 감싸주지 않는다면, 직렬(Serial)로 수행되는 것처럼 보임.
        
        // 사용자 ID 등 기본적인 정보 불러오기
        // ⭐️ 사용자ID 등 기본적인 정보는 언제 바뀔지 모르니 항상 불러옴.
        await self.getPlayerID(forceLoad: true)
        await self.getPlayerWallet(forceLoad: true)
        
        // 컬렉션 정보 불러오기
        self.getCollection()
        await self.getOwnedWeaponSkins()
        
        // 최신 버전의 데이터가 존재하는지 확인하기
        await self.checkValorantVersion()
        
        // 로테이션 스킨 갱신 날짜 불러오기
        if let renewalDate = realmManager.read(of: StoreSkinsList.self).first?.renewalDate {
            self.storeSkinsRenewalDate = renewalDate
        }
        // 번들 스킨 갱신 날짜 불러오기
        self.storeBundlesRenewalDate = []
        let storeBundles = realmManager.read(of: StoreBundlesList.self)
        for bundle in storeBundles {
            self.storeBundlesRenewalDate.append(bundle.renewalDate)
        }
        
        // 현재 날짜 불러오기
        let currentDate = Date()
        // 로테이션 스킨을 갱신할 필요가 없다면
        if currentDate < self.storeSkinsRenewalDate {
            // Realm에서 데이터 가져오기
            await self.getStoreSkins()
        } else {
            // 서버에서 데이터 가져오기
            await self.getStoreSkins(forceLoad: true)
        }
        
        // 번들 갱신이 필요한지 확인하는 변수 선언하기
        var needRenewalBundles: Bool = false
        // 각 번들을 순회해보며
        for renewalDate in self.storeBundlesRenewalDate {
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
            // Realm에서 데이터 가져오기
            await self.getStoreBundles()
        // 번들 스킨을 갱신할 필요가 있다면
        } else {
            // 서버에서 데이터 가져오기
            await self.getStoreBundles(forceLoad: true)
        }
        
        // 타이머 작동시키기
        self.storeSkinsTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true,
            block: updateStoreSkinsRemainingTime(_:)
        )
        self.storeBundlesTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true,
            block: updateStoreBundlesRemainingTime(_:)
        )
        
        // ✏️ 팝 내비게이션 스택 애니메이션이 보이게 하지 않기 위해 0.25초 딜레이를 둠.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring()) {
                // 로딩 스크린 가리기
                self.isPresentLoadingScreenViewFromView = false
            }
            
            // 다운로드 화면을 가리기
            self.loginDelegate?.dismissDataDownloadView()
        }
    }
    
    @MainActor
    func reloadPlayerData(of type: ReloadDataType) async {
        // 로딩 애니메이션 시작하기
        withAnimation(.spring(dampingFraction: 0.3)) { self.refreshButtonRotateAnimation = true }
        // 사용자ID 등 기본적인 정보 불러오기
        // ❗️ Task로 감싸주지 않는다면, 직렬(Serial)로 수행되는 것처럼 보임.
        await getPlayerID(forceLoad: true)
        await getPlayerWallet(forceLoad: true)
        // 어느 데이터를 불러올지 확인하기
        switch type {
        case .skin:
            await self.getStoreSkins(forceLoad: true)
        case .bundle:
            await self.getStoreBundles(forceLoad: true)
        }
        await getOwnedWeaponSkins()
        // 로딩 애니메이션 끝내기
        self.refreshButtonRotateAnimation = false
    }
    
    // MARK: - GET PLAYER DATA
    
    @MainActor
    func getPlayerID(forceLoad: Bool = false) async {
        // Realm에 저장된 사용자ID 데이터 불러오기
        var playerID = realmManager.read(of: PlayerID.self)
        // 강제로 다시 불러오지 안는다면
        if !forceLoad {
            // Realm에 저장된 로테이션 스킨 데이터가 있다면
            if !playerID.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .skin) {
                    do {
                        // 사용자ID 데이터를 불러와 Realm에 저장하기
                        if let playerID = try await self.fetchPlayerID() {
                            realmManager.overwrite(playerID)
                        }
                    } catch {
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                }
            // Realm에 저장된 로테이션 스킨 데이터가 없다면
            } else {
                do {
                    // 사용자ID 데이터를 불러와 Realm에 저장하기
                    if let playerID = try await self.fetchPlayerID() {
                        realmManager.overwrite(playerID)
                    }
                } catch {
                    return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                }
            }
            // Realm에 저장된 사용자ID 데이터 다시 불러오기
            playerID = realmManager.read(of: PlayerID.self)
        // 강제로 다시 불러온다면
        } else {
            do {
                if let playerID = try await self.fetchPlayerID() {
                    realmManager.overwrite(playerID)
                }
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
    private func fetchPlayerID() async throws -> PlayerID? {
        // playerID를 저장하는 변수 선언하기
        var playerID: PlayerID?
        // 접근 토큰 등 사용자 고유 정보 가져오기
        let reAuthTokens = try await self.loginDelegate?.getReAuthTokens().get()
        // 닉네임, 태그 정보 다운로드하기
        if let tokens = reAuthTokens {
            playerID = try await resourceManager.fetchPlayerID(
                accessToken: tokens.accessToken,
                riotEntitlement: tokens.riotEntitlement,
                puuid: tokens.puuid
            ).get()
            return playerID
        }
        return nil
    }
    
    @MainActor
    func getPlayerWallet(forceLoad: Bool = false) async {
        // Realm에 저장된 사용자 지갑 데이터 불러오기
        var playerWallet = realmManager.read(of: PlayerWallet.self)
        // 강제로 다시 불러오지 안는다면
        if !forceLoad {
            // Realm에 저장된 사용자 지갑 데이터가 없다면
            if playerWallet.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .skin) {
                    do {
                        // 사용자 지갑 데이터를 불러와 Realm에 저장하기
                        if let playerWallet = try await self.fetchPlayerWallet() {
                            realmManager.overwrite(playerWallet)
                        }
                    } catch {
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                // Realm에 저장된 로테이션 스킨 데이터가 없다면
                } else {
                    do {
                        // 사용자 지갑 데이터를 불러와 Realm에 저장하기
                        if let playerWallet = try await self.fetchPlayerWallet() {
                            realmManager.overwrite(playerWallet)
                        }
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
                if let playerWallet = try await self.fetchPlayerWallet() {
                    realmManager.overwrite(playerWallet)
                }
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
    private func fetchPlayerWallet() async throws -> PlayerWallet? {
        // Wallet를 저장하는 변수 선언하기
        var wallet: PlayerWallet?
        // 접근 토큰 등 사용자 고유 정보 가져오기
        let reAuthTokens = try await self.loginDelegate?.getReAuthTokens().get()
        // 사용자 지갑 정보 다운로드하기
        if let tokens = reAuthTokens {
            wallet = try await resourceManager.fetchUserWallet(
                accessToken: tokens.accessToken,
                riotEntitlement: tokens.riotEntitlement,
                puuid: tokens.puuid
            ).get()
            return wallet
        }
        return nil
    }
    
    // MARK: - GET STORE DATA - SKINS
    
    @MainActor
    func getStoreSkins(forceLoad: Bool = false) async {
        // Realm에 저장된 로테이션 스킨 데이터 불러오기
        let skins = realmManager.read(of: StoreSkinsList.self)
        // 강제로 다시 불러오지 안는다면
        if !forceLoad {
            // Realm에 저장된 로테이션 스킨 데이터가 있다면
            if !skins.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .skin) {
                    do {
                        // 로테이션 스킨 데이터를 불러와 Realm에 저장하기
                        if let storeSkinsList = try await self.fetchStoreSkins() {
                            realmManager.overwrite(storeSkinsList)
                        }
                    } catch {
                        withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                }
            // Realm에 로테이션 스킨 데이터가 없다면
            } else {
                do {
                    // 로테이션 스킨 데이터를 불러와 Realm에 저장하기
                    if let storeSkinsList = try await self.fetchStoreSkins() {
                        realmManager.overwrite(storeSkinsList)
                    }
                } catch {
                    withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
                    return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                }
            }
        // 강제로 다시 불러온다면
        } else {
            do {
                // 로테이션 스킨 데이터를 불러와 Realm에 저장하기
                if let storeSkinsList = try await self.fetchStoreSkins() {
                    realmManager.overwrite(storeSkinsList)
                }
            } catch {
                withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
                return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
            }
        }
        
        // Realm으로부터 로테이션 스킨 데이터 불러오기
        guard let storeSkinsList = realmManager.read(of: StoreSkinsList.self).first else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // Realm으로부터 전체 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.weaponSkins else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // Realm으로부터 가격 데이터 불러오기
        guard let prices = realmManager.read(of: StorePrices.self).first?.offers else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // 스킨과 가격 정보를 저장할 배열 변수 선언하기
        var storeSkins: StoreSkin = StoreSkin(renewalDate: storeSkinsList.renewalDate)
        
        // 상점 로테이션 스킨 갱신 날짜 변경하기
        self.storeSkinsRenewalDate = storeSkinsList.renewalDate
        
        // 상점 로테이션 스킨 필터링하기
        for itemInfo in storeSkinsList.itemInfos {
            // 스킨 데이터를 저장할 변수 선언하기
            var filteredSkin: Skin?
            // 가격 데이터를 저장할 변수 선언하기
            var filteredBasePrice: Int?
            // 스킨 데이터 필터링하기
            if let firstSkinIndex = skins.firstIndex(where: {
                $0.levels.first?.uuid == itemInfo.uuid }) {
                filteredSkin = skins[firstSkinIndex]
            }
            // 가격 데이터 필터링하기
            if let firstBasePriceIndex = prices.firstIndex(where: {
                $0.offerID == itemInfo.uuid }) {
                filteredBasePrice = prices[firstBasePriceIndex].cost?.vp
            }
            
            // 필터링한 스킨과 가격 데이터 옵셔널 바인딩하기
            guard let skin = filteredSkin,
                  let basePrice = filteredBasePrice else {
                continue
            }
            let price = Price(basePrice: basePrice)
            let skinInfo = SkinInfo(skin: skin, price: price)
            storeSkins.skinInfos.append(skinInfo)
        }
        
        // 결과 업데이트하기
        self.storeSkins = storeSkins
    }
    
    private func fetchStoreSkins() async throws -> StoreSkinsList? {
        // 로테이션 상점 데이터를 정상적으로 받아왔다면
        if let skinsPanelLayout = try? await self.fetchSkinsPanelLayout() {
            // 화면에 출력하기 쉬운 형태로 데이터 가공하기
            return transformSkinsPanelLayoutToStoreSkinsList(skinsPanelLayout)
        }
        return nil
    }
    
    @MainActor
    private func fetchSkinsPanelLayout() async throws -> SkinsPanelLayout? {
        // 로테이션 스킨 데이터를 저장하는 변수 선언하기
        var skinsPanelLayouts: SkinsPanelLayout?
        // 접근 토큰 등 사용자 고유 정보 가져오기
        let reAuthTokens = try await self.loginDelegate?.getReAuthTokens().get()
        // 새롭게 로테이션 스킨 데이터 불러오기
        if let tokens = reAuthTokens {
            skinsPanelLayouts = try await resourceManager.fetchStorefront(
                accessToken: tokens.accessToken,
                riotEntitlement: tokens.riotEntitlement,
                puuid: tokens.puuid
            ).get().skinsPanelLayout
            return skinsPanelLayouts
        }
        return nil
    }
    
    private func transformSkinsPanelLayoutToStoreSkinsList(_ skinsPanelLayouts: SkinsPanelLayout) -> StoreSkinsList {
        // Realm에 새로운 로테이션 스킨 데이터 저장하기
        let storeSkinsList: StoreSkinsList = StoreSkinsList()
        // 로테이션 스킨 갱신 날짜 저장하기
        storeSkinsList.renewalDate = Date().addingTimeInterval(
            Double(skinsPanelLayouts.singleItemOffersRemainingDurationInSeconds)
        )
        for uuid in skinsPanelLayouts.singleItemOffers {
            // 첫 번째 레벨의 UUID 저장하기
            let rotationSkinInfo = RotationSkinInfo()
            rotationSkinInfo.uuid = uuid
            storeSkinsList.itemInfos.append(rotationSkinInfo)
        }
        
        return storeSkinsList
    }
    
    
    // MARK: - GET STORE DATA - BUNDLE
    
    @MainActor
    func getStoreBundles(forceLoad: Bool = false) async {
        // Realm에 저장된 로테이션 스킨 데이터 불러오기
        let bundles = realmManager.read(of: StoreBundlesList.self)
        // 강제로 다시 불러오지 안는다면
        if !forceLoad {
            // Realm에 저장된 번들 스킨 데이터가 있다면
            if !bundles.isEmpty {
                // 로테이션 갱신 시간이 지났다면
                if self.isExpired(of: .bundle) {
                    do {
                        // 번들 스킨 데이터를 불러와 Realm에 저장하기
                        if let bundlesList = try await self.fetchStoreBundles() {
                            realmManager.overwrite(bundlesList)
                        }
                    } catch {
                        withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
                        return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                    }
                }
            // Realm에 번들 스킨 데이터가 없다면
            } else {
                do {
                    // 번들 스킨 데이터를 불러와 Realm에 저장하기
                    if let bundlesList = try await self.fetchStoreBundles() {
                        realmManager.overwrite(bundlesList)
                    }
                } catch {
                    withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
                    return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
                }
            }
        // 강제로 다시 불러온다면
        } else {
            do {
                // 번들 스킨 데이터를 불러와 Realm에 저장하기
                if let bundlesList = try await self.fetchStoreBundles() {
                    realmManager.overwrite(bundlesList)
                }
            } catch {
                withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
                return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
            }
        }
        
        // Realm으로부터 로테이션 스킨 데이터 불러오기
        let storeBundlesList = realmManager.read(of: StoreBundlesList.self)
        
        self.storeBundlesRenewalDate = []
        for storeBundle in storeBundlesList {
            self.storeBundlesRenewalDate.append(storeBundle.renewalDate)
        }
        
        // Realm으로부터 전체 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.weaponSkins else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // Realm으로부터 가격 데이터 불러오기
        //guard let prices = realmManager.read(of: StorePrices.self).first?.offers else {
        //    self.isPresentLoadingScreenView = false
        //    return
        //}
        
        // 번들 정보를 저장할 변수 선언하기
        var storeBundles: [StoreBundle] = []
        // 번들 스킨 필터링하기
        for bundle in storeBundlesList {
            // 기초적인 번들 정보 기입하기
            var storeBundle = StoreBundle(
                uuid: bundle.uuid,
                bundleBsePrice: bundle.basePrice,
                bundleDiscountedPrice: bundle.discountedPrice,
                bundleDiscountedPercent: bundle.discountedPercent,
                wholeSaleOnly: bundle.wholeSaleOnly,
                renewalDate: bundle.renewalDate
            )
            
            for itemInfo in bundle.itemInfos {
                // 스킨 데이터를 저장할 변수 선언하기
                var filteredSkin: Skin?
                // 가격 데이터를 저장할 변수 선언하기
                //var filteredBasePrice: Int?
                // 스킨 데이터 필터링하기
                if let firstSkinIndex = skins.firstIndex(where: {
                    $0.levels.first?.uuid == itemInfo.uuid }) {
                    filteredSkin = skins[firstSkinIndex]
                }
                // 가격 데이터 필터링하기
                //if let firstBasePriceIndex = prices.firstIndex(where: {
                //    $0.offerID == itemInfo.uuid }) {
                //    filteredBasePrice = prices[firstBasePriceIndex].cost?.vp
                //}
                
                // 필터링한 스킨과 가격 데이터 옵셔널 바인딩하기
                guard let skin = filteredSkin
                     /* let basePrice = filteredBasePrice */ else {
                    continue
                }
                let price = Price(
                    basePrice: itemInfo.basePrice,
                    discountedPrice: itemInfo.discountedPrice
                )
                let skinInfo = SkinInfo(skin: skin, price: price)
                storeBundle.skinInfos.append(skinInfo)
            }
            
            storeBundles.append(storeBundle)
        }
        
        // 결과 업데이트하기
        self.storeBundles = storeBundles
    }
    
    private func fetchStoreBundles() async throws -> StoreBundlesList? {
        // 로테이션 상점 데이터를 정상적으로 받아왔다면
        if let featureBundles = try? await self.fetchFeatureBundle() {
            // 화면에 출력하기 쉬운 형태로 데이터 가공하기
            return transformFeatureBundleToStoreBundlesList(featureBundles)
        }
        return nil
    }
    
    @MainActor
    func fetchFeatureBundle() async throws -> FeaturedBundle? {
        // 번들 스킨 데이터를 저장하는 변수 선언하기
        var featureBundles: FeaturedBundle?
        // 접근 토큰 등 사용자 고유 정보 가져오기
        let reAuthTokens = try await self.loginDelegate?.getReAuthTokens().get()
        // 새롭게 번들 스킨 데이터 불러오기
        if let tokens = reAuthTokens {
            featureBundles = try await resourceManager.fetchStorefront(
                accessToken: tokens.accessToken,
                riotEntitlement: tokens.riotEntitlement,
                puuid: tokens.puuid
            ).get().featuredBundle
            return featureBundles
        }
        return nil
    }
    
    private func transformFeatureBundleToStoreBundlesList(_ featureBundles: FeaturedBundle) -> StoreBundlesList {
        // 번들 스킨 정보를 담은 변수 선언하기
        let storeBundlesList = StoreBundlesList()
        // 개별 스킨 정보를 하나씩 순회하며
        for bundle in featureBundles.bundles {
            // Realm에 번들 스킨 데이터 저장하기
            storeBundlesList.uuid = bundle.uuid
            storeBundlesList.basePrice = bundle.totalBasePrice?.vp ?? 0
            storeBundlesList.discountedPrice = bundle.totalDiscountedPrice?.vp ?? 0
            storeBundlesList.discountedPercent = bundle.totalDiscountPercent
            // 번들 갱신 시간을 Realm에 저장하기
            storeBundlesList.renewalDate = Date().addingTimeInterval(
                Double(bundle.durationRemainingInSeconds)
            )
            
            for item in bundle.items {
                let bundleSkinInfo = BundleSkinInfo()
                
                // 아이템이 무기 스킨이 아니라면 (배너, 총기 장식 등이라면)
                guard item.item.typeId == "e7c63390-eda7-46e0-bb7a-a6abdacd2433" else {
                    // Realm에 저장하지 않기
                    continue
                }
                
                bundleSkinInfo.uuid = item.item.uuid
                bundleSkinInfo.basePrice = item.basePrice
                bundleSkinInfo.discountedPrice = item.discountedPrice
                storeBundlesList.itemInfos.append(bundleSkinInfo)
            }
        }
        return storeBundlesList
    }
    
    // MARK: - GET COLLECTION
    
    func getCollection() {
        // Realm으로부터 전체 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.weaponSkins else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // Realm으로부터 가격 데이터 불러오기
        guard let prices = realmManager.read(of: StorePrices.self).first?.offers else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // 스킨 컬렉션을 저장할 배열 변수 선언하기
        var collections: [SkinInfo] = []
        
        // 상점 로테이션 스킨 필터링하기
        for skin in skins {
            // 가격 데이터를 저장할 변수 선언하기
            var filteredBasePrice: Int?
            // 가격 데이터 필터링하기
            if let firstBasePriceIndex = prices.firstIndex(where: {
                $0.offerID == skin.levels.first?.uuid }) {
                filteredBasePrice = prices[firstBasePriceIndex].cost?.vp
            }
            
            // 필터링한 스킨과 가격 데이터 옵셔널 바인딩하기
            guard let basePrice = filteredBasePrice else {
                continue
            }
            let price = Price(basePrice: basePrice)
            let skinInfo = SkinInfo(skin: skin, price: price)
            collections.append(skinInfo)
        }
        
        // 컬렉션 정렬하기
        collections.sort {
            $0.skin.displayName < $1.skin.displayName
        }
        
        // 결과 업데이트하기
        self.collections = collections
    }
    
    @MainActor
    func getOwnedWeaponSkins() async {
        // 내가 가진 스킨 컬렉션을 저장할 배열 변수 선언하기
        var ownedItems: [Entitlement] = []
        
        do {
            // 접근 토큰 등 사용자 고유 정보 가져오기
            let reAuthTokens = try await self.loginDelegate?.getReAuthTokens().get()
            // 새롭게 번들 스킨 데이터 불러오기
            if let tokens = reAuthTokens {
                ownedItems = try await resourceManager.fetchOwnedItems(
                    accessToken: tokens.accessToken,
                    riotEntitlement: tokens.riotEntitlement,
                    puuid: tokens.puuid
                ).get().entitlements
            }
        } catch {
            return // 다운로드에 실패하면 수행할 예외 처리 코드 작성하기
        }
        
        // Realm으로부터 전체 스킨 데이터 불러오기
        guard let skins = realmManager.read(of: WeaponSkins.self).first?.weaponSkins else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // Realm으로부터 가격 데이터 불러오기
        guard let prices = realmManager.read(of: StorePrices.self).first?.offers else {
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
            return
        }
        // 스킨 컬렉션을 저장할 배열 변수 선언하기
        var ownedWeaponSkins: [SkinInfo] = []
        
        // 상점 로테이션 스킨 필터링하기
        for item in ownedItems {
            // 스킨 데이터를 저장할 변수 선언하기
            var filteredSkin: Skin?
            // 가격 데이터를 저장할 변수 선언하기
            var filteredBasePrice: Int?
            // 스킨 데이터 필터링하기
            if let firstSkinIndex = skins.firstIndex(where: {
                $0.levels.first?.uuid == item.itemID }) {
                filteredSkin = skins[firstSkinIndex]
            }
            // 가격 데이터 필터링하기
            if let firstBasePriceIndex = prices.firstIndex(where: {
                $0.offerID == item.itemID }) {
                filteredBasePrice = prices[firstBasePriceIndex].cost?.vp
            }
            
            // 필터링한 스킨과 가격 데이터 옵셔널 바인딩하기
            guard let skin = filteredSkin,
                  let basePrice = filteredBasePrice else {
                continue
            }
            let price = Price(basePrice: basePrice)
            let skinInfo = SkinInfo(skin: skin, price: price)
            ownedWeaponSkins.append(skinInfo)
        }
        
        // 컬렉션 정렬하기
        ownedWeaponSkins.sort {
            $0.skin.displayName < $1.skin.displayName
        }
        
        // 결과 업데이트하기
        self.ownedWeaponSkins = ownedWeaponSkins
    }
    
    // MARK: - TIMER
    
    // ❓ Sendable의 의미가 뭐지?
    @Sendable
    @objc func updateStoreSkinsRemainingTime(_ timer: Timer? = nil) {
        // 현재 날짜 불러오기
        let currentDate = Date()
        // (앱 실행 중) 로테이션 스킨을 갱신할 필요가 있다면
        if currentDate > self.storeSkinsRenewalDate && self.isLoggedIn && !self.isAutoReloadedStoreSkinsData {
            print("Skin - 자동으로 리로드하기")
            // 서버에서 데이터 가져오기
            Task {
                await self.getPlayerID(forceLoad: true)
                await self.getPlayerWallet(forceLoad: true)
                await self.getStoreSkins(forceLoad: true)
            }
            // 재-실행을 막기 위해 변수로 표시하기
            self.isAutoReloadedStoreSkinsData = true
        }
        
        // 시간 업데이트하기
        self.storeSkinsRemainingTime = self.remainingSkinsTimeString(from: currentDate, to: self.storeSkinsRenewalDate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // 로딩 스크린 가리기
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromSkinsTimer = false }
        }
        
    }
    
    @Sendable
    @objc func updateStoreBundlesRemainingTime(_ timer: Timer? = nil) {
        // 현재 날짜 불러오기
        let currentDate = Date()
        // 각 번들을 순회해보며
        for renewalDate in self.storeBundlesRenewalDate {
            // (앱 실행 중) 번들 스킨을 갱신할 필요가 있다면
            if currentDate > renewalDate && self.isLoggedIn && !self.isAutoReloadedStoreBundlesData {
                print("Skin - 자동으로 리로드하기")
                // 서버에서 데이터 가져오기
                Task {
                    await self.getPlayerID(forceLoad: true)
                    await self.getPlayerWallet(forceLoad: true)
                    await self.getStoreBundles(forceLoad: true)
                }
                // 재-실행을 막기 위해 변수로 표시하기
                self.isAutoReloadedStoreBundlesData = true
                // 루프 탈출하기
                break
            }
            
        }
        
        // 시간 업데이트하기
        self.storeBundlesReminingTime = []
        for renewalDate in storeBundlesRenewalDate {
            storeBundlesReminingTime.append(self.remainingBundlesTimeString(from: currentDate, to: renewalDate))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // 로딩 스크린 가리기
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromBundlesTimer = false }
        }
    }
    
    private func remainingSkinsTimeString(from date1: Date, to date2: Date) -> String {
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
    
    private func remainingBundlesTimeString(from date1: Date, to date2: Date) -> String {
        // 현재 날짜부터 갱신 날짜까지 날짜 요소(시/분/초) 차이 구하기
        let dateComponents = self.calendar.dateComponents(
            [.day, .hour, .minute, .second],
            from: date1,
            to: date2
        )
        let day = dateComponents.day ?? 0
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        let second = dateComponents.second ?? 0
        
        // 남은 시간 문자열 출력을 위한 숫자 포맷 설정하기
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        // 각 날짜 요소를 숫자 포맷으로 변환하기
        let formattedDay = formatter.string(for: day) ?? "00"
        let formattedHour = formatter.string(for: hour) ?? "00"
        let formattedMinute = formatter.string(for: minute) ?? "00"
        let formattedSecond = formatter.string(for: second) ?? "00"
        // 결과 반환하기
        return "\(formattedDay):\(formattedHour):\(formattedMinute):\(formattedSecond)"
    }
    
}

// MARK: - EXTESNIONS

extension ResourceViewModel: ResourceViewModelDelegate {
    
    @MainActor
    func getStorefront(forceLoad: Bool = false) async {
        await self.getStoreSkins(forceLoad: forceLoad)
        await self.getStoreBundles(forceLoad: forceLoad)
        
        self.getCollection()
        await self.getOwnedWeaponSkins()
    }
    
    func clearAllResource() {
        // 토큰 및 상점 만료 날짜 정보 지우기
        self.storeSkinsRenewalDate = Date(timeIntervalSinceReferenceDate: Double.infinity)
        self.accessTokenExpiryDate = Double.infinity
        
        // Realm에 저장된 스킨 데이터 지우기
        self.realmManager.deleteAll(of: PlayerID.self)
        self.realmManager.deleteAll(of: PlayerWallet.self)
        self.realmManager.deleteAll(of: StoreSkinsList.self)
        self.realmManager.deleteAll(of: StoreBundlesList.self)
        
        // 이미지 메모리・디스크 캐시 비우기
        imageCache.clearMemoryCache()
        imageCache.clearDiskCache()
        
        // 쿠키 정보 및 사용자 고유 정보 삭제하기
        try? keychain.removeAll()
        
        // 타이머 및 관련 변수 제거하기
        self.storeSkinsTimer?.invalidate()
        self.storeBundlesTimer?.invalidate()
        
        self.isIntialGettingStoreSkinsData = false
        self.isAutoReloadedStoreSkinsData = false
        self.isIntialGettingStoreBundlesData = false
        self.isAutoReloadedStoreBundlesData = false
    }
    
    func clearStorefront() {
        self.storeSkins.skinInfos = []
        self.storeBundles = []
        
        self.collections = []
        self.ownedWeaponSkins = []
    }
    
    func dismissLoadingView(of type: LoadingViewType) {
        switch type {
        case .view:
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromView = false }
        case .skinsTimer:
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromSkinsTimer = false }
        case .bundlesTimer:
            withAnimation(.spring()) { self.isPresentLoadingScreenViewFromBundlesTimer = false }
        }
    }
}

extension ResourceViewModel {
    
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
            fallthrough
        case .bundle:
            // 로테이션 갱신 시간이 지났다면
            // ⭐️ 번들 시간은 아니지만, 구현 편의를 위해 스킨 갱신 시간을 사용함.
            return currentDate > storeSkinsRenewalDate.timeIntervalSinceReferenceDate ? true : false
        }
    }
    
}
