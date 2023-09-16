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
    
    private func decode<T: Decodable>(of type: T.Type, _ data: Data) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}
