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
    
    var path1: String {
        switch self {
        case .weaponSkins:
            fallthrough
        case .weaponSkinChromas:
            fallthrough
        case .weaponSkinSwatchs:
            return "weaponskinchromas"
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

struct WalletResponse: Codable {
    let balances: Balance

    enum CodingKeys: String, CodingKey {
        case balances = "Balances"
    }
}

struct Balance: Codable {
    let vp: Int
    let rp: Int
    let kp: Int
    
    enum CodingKeys: String, CodingKey {
        case vp = "85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741"
        case rp = "e59aa87c-4cbf-517a-5983-6e81511be9b7"
        case kp = "85ca954a-41f2-ce94-9b45-8ca3dd39a00d"
    }
}

struct StorefrontResponse: Codable {
    let skinsPanelLayout: SkinsPanelLayout
    
    enum CodingKeys: String, CodingKey {
        case skinsPanelLayout = "SkinsPanelLayout"
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

// MARK: - MANAGER

final class ResourceManager {
    
    // MARK: - SINGLETONE
    static let shared = ResourceManager()
    private init() { }
    
    // MARK: - PROPERTIES
    
    var urlSession = URLSession.shared
    
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
        guard let riotVersion = decode(of: Version.self, data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(riotVersion)
    }
    
    func fetchUserWallet(accessToken: String, riotEntitlement: String, puuid: String) async -> Result<WalletResponse, ResourceError> {
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
        guard let walletResponse = decode(of: WalletResponse.self, data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(walletResponse)
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
        guard let storefrontResponse = decode(of: StorefrontResponse.self, data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(storefrontResponse)
        
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
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러: \(#function)")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let weaponSkins = decode(of: WeaponSkins.self, data) else {
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
        guard let weaponPrices = decode(of: StorePrices.self, data) else {
            print("파싱 에러: \(#function)")
            return .failure(.parsingError)
        }
        
        // 결과 반환하기
        return .success(weaponPrices)
    }
    
    func fetchSkinImageData(of type: ImageType, uuid: String) async -> Result<Data, ResourceError> {
        // For Debug
        print(#function)
        
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
    
    private func decode<T: Decodable>(of type: T.Type, _ data: Data) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}
