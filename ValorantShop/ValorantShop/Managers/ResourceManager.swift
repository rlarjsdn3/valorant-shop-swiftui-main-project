//
//  ResourceManager.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/16.
//

import Foundation

// MARK: - ENUM

enum ImageType: String {
    case weaponSkins
    case weaponSkinChromas
    case weaponSkinSwatchs
    case bundles
    
    var path1: String {
        switch self {
        case .weaponSkins:
            fallthrough
        case .weaponSkinChromas:
            fallthrough
        case .weaponSkinSwatchs:
            return "weaponskinchromas"
        case .bundles:
            return "bundles"
        }
    }
    
    var path2: String {
        switch self {
        case .weaponSkins:
            return "fullrender"
        case .weaponSkinChromas:
            return "fullrender"
        case .weaponSkinSwatchs:
            return "swatch"
        case .bundles:
            return "displayicon"
        }
    }
    
    var prefixFileName: String {
        switch self {
        case .weaponSkins:
            return "thumbnail"
        case .weaponSkinChromas:
            return "chroma"
        case .weaponSkinSwatchs:
            return "swatch"
        case .bundles: // Not Use.
            return "bundle"
        }
    }
}

// MARK: - ERROR

enum ResourceError: Error {
    case urlError
    case networkError
    case statusCodeError
    case parsingError
}

// MARK: - HTTP RESPONSE

struct StorefrontResponse: Codable {
    let featuredBundle: FeaturedBundle
    let skinsPanelLayout: SkinsPanelLayout
    
    enum CodingKeys: String, CodingKey {
        case featuredBundle = "FeaturedBundle"
        case skinsPanelLayout = "SkinsPanelLayout"
    }
}

struct FeaturedBundle: Codable {
    let bundles: [Bundle]
    let bundleRemainingDurationInSeconds: Int

    enum CodingKeys: String, CodingKey {
        case bundles = "Bundles"
        case bundleRemainingDurationInSeconds = "BundleRemainingDurationInSeconds"
    }
}

struct Bundle: Codable {
    let uuid: String
    let items: [Item]
    let totalBasePrice: TotalBundleCost?
    let totalDiscountedPrice: TotalBundleCost?
    let totalDiscountPercent: Double
    let durationRemainingInSeconds: Int
    let wholeSaleOnly: Bool

    enum CodingKeys: String, CodingKey {
        case uuid = "DataAssetID"
        case items = "Items"
        case totalBasePrice = "TotalBaseCost"
        case totalDiscountedPrice = "TotalDiscountedCost"
        case totalDiscountPercent = "TotalDiscountPercent"
        case durationRemainingInSeconds = "DurationRemainingInSeconds"
        case wholeSaleOnly = "WholesaleOnly"
    }
}

struct Item: Codable {
    let item: ItemUUID
    let basePrice: Int
    let discountedPrice: Int

    enum CodingKeys: String, CodingKey {
        case item = "Item"
        case basePrice = "BasePrice"
        case discountedPrice = "DiscountedPrice"
    }
}

struct ItemUUID: Codable {
    let typeId: String
    let uuid: String

    enum CodingKeys: String, CodingKey {
        case typeId = "ItemTypeID"
        case uuid = "ItemID"
    }
}

struct TotalBundleCost: Codable {
    let vp: Int

    enum CodingKeys: String, CodingKey {
        case vp = "85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741"
    }
}

struct SkinsPanelLayout: Codable {
    let singleItemOffers: [String]
    let singleItemOffersRemainingDurationInSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case singleItemOffers = "SingleItemOffers"
        case singleItemOffersRemainingDurationInSeconds = "SingleItemOffersRemainingDurationInSeconds"
    }
}

// MARK: - Welcome
struct OwnedItemsResponse: Codable {
    let itemTypeID: String
    let entitlements: [Entitlement]

    enum CodingKeys: String, CodingKey {
        case itemTypeID = "ItemTypeID"
        case entitlements = "Entitlements"
    }
}

// MARK: - Entitlement
struct Entitlement: Codable {
    let typeID, itemID: String

    enum CodingKeys: String, CodingKey {
        case typeID = "TypeID"
        case itemID = "ItemID"
    }
}


// MARK: - MANAGER

final class ResourceManager {
    
    // MARK: - SINGLETONE
    static let shared = ResourceManager()
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 50
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - PROPERTIES
    
    var urlSession: URLSession
    
    // MARK: - FUNCTIONS
    
    func fetchValorantVersion() async -> Result<Version, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.version) else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let version = decode(of: Version.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(version)
    }
    
    func fetchPlayerID(accessToken: String, riotEntitlement: String, puuid: String) async throws -> Result<PlayerID, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.playerId) else { return .failure(.urlError) }
        // HTTP Body 만들기
        let playerIDBody = [puuid]
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("\(riotEntitlement)", forHTTPHeaderField: "X-Riot-Entitlements-JWT")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = self.encode(playerIDBody)
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let playerID = self.decode(of: [PlayerID].self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        // 첫 번째 데이터 추출하기
        guard let playerID = playerID.first else {
            print("유저 정보 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(playerID)
    }
    
    func fetchUserWallet(accessToken: String, riotEntitlement: String, puuid: String) async -> Result<PlayerWallet, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.wallet + "\(puuid)") else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("\(riotEntitlement)", forHTTPHeaderField: "X-Riot-Entitlements-JWT")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let playerWallet = self.decode(of: PlayerWallet.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(playerWallet)
    }
    
    func fetchStorefront(accessToken: String, riotEntitlement: String, puuid: String) async -> Result<StorefrontResponse, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.storefront + "\(puuid)") else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("\(riotEntitlement)", forHTTPHeaderField: "X-Riot-Entitlements-JWT")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let storefrontResponse = self.decode(of: StorefrontResponse.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(storefrontResponse)
        
    }
    
    func fetchOwnedItems(accessToken: String, riotEntitlement: String, puuid: String) async -> Result<OwnedItemsResponse, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.ownedItems(puuid: puuid)) else { return .failure(.urlError) }
        // URL Reqeust 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("\(riotEntitlement)", forHTTPHeaderField: "X-Riot-Entitlements-JWT")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let ownedItemsResponse = self.decode(of: OwnedItemsResponse.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }

        // 결과 반환하기
        return .success(ownedItemsResponse)
    }
    
    func fetchBundles() async -> Result<Bundles, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 설정하기
        guard var urlComponent = URLComponents(string: ResourceURL.bundles) else { return .failure(.urlError) }
        urlComponent.queryItems = [
            URLQueryItem(name: "language", value: "ko-KR")
        ]
        // URL 만들기
        guard let url = URL(string: urlComponent.url!.description) else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let bundles = self.decode(of: Bundles.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(bundles)
    }
    
    func fetchWeaponSkins() async -> Result<WeaponSkins, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 설정하기
        guard var urlComponent = URLComponents(string: ResourceURL.skins) else { return .failure(.urlError) }
        urlComponent.queryItems = [
            URLQueryItem(name: "language", value: "ko-KR")
        ]
        // URL 만들기
        guard let url = URL(string: urlComponent.url!.description) else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let weaponSkins = self.decode(of: WeaponSkins.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(weaponSkins)
    }
    
    func fetchStorePrices(accessToken: String, riotEntitlement: String) async -> Result<StorePrices, ResourceError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.prices) else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("\(riotEntitlement)", forHTTPHeaderField: "X-Riot-Entitlements-JWT")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(for: urlRequest) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let weaponPrices = self.decode(of: StorePrices.self, from: data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(weaponPrices)
    }
    
    func fetchSkinImageData(of type: ImageType, uuid: String) async -> Result<Data, ResourceError> {
        // For Debug
        print(#function)
        urlSession.configuration.httpMaximumConnectionsPerHost = 50
        
        // URL 만들기
        guard let url = URL(string: ResourceURL.displayIcon(of: type, uuid: uuid)) else { return .failure(.urlError) }
        
        // 비동기 HTTP 통신하기
        guard let (data, response) = try? await urlSession.data(from: url) else {
            print("네트워크 에러: \(#function)")
            return .failure(.networkError)
        }
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        
        // 결과 반환하기
        return .success(data)
    }
    
    // MARK: - ENCODE
    
    private func encode<T: Encodable>(_ data: T) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(data)
    }
    
    // MARK: - DECODE
    
    private func decode<T: Decodable>(of type: T.Type, from data: Data) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}
