//
//  ResourceManager.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/16.
//

import Foundation

// MARK: - ERROR

enum ResourceError: Error {
    case urlError
    case statusCodeError
    case decodeError
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

// MARK: - MANAGER

final class ResourceManager {
    
    // MARK: - SINGLETONE
    static let shared = ResourceManager()
    private init() { }
    
    // MARK: - PROPERTIES
    
    let urlSession = URLSession.shared
    
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
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let riotVersion = decode(of: Version.self, data) else {
            return .failure(.decodeError)
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
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let walletResponse = decode(of: WalletResponse.self, data) else {
            print("파싱 에러")
            return .failure(.decodeError)
        }
        
        // 결과 반환하기
        return .success(walletResponse)
    }
    
    private func decode<T: Decodable>(of type: T.Type, _ data: Data) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}
