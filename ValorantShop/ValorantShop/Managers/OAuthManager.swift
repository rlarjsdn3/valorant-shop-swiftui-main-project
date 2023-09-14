//
//  OAuthManager.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import Foundation

// MARK: - HTTP BODY

struct AuthCookiesBody: Encodable {
    let client_id: String = "play-valorant-web-prod"
    let nonce: String = "1"
    let redirect_uri: String = "https://playvalorant.com/opt_in"
    let reponse_type: String = "token id_token"
    let scope: String = "account openid"
}

struct AuthRequestBody: Encodable {
    let type: String = "auth"
    let username: String
    let password: String
}

final class OAuthManager {
    
    // MARK: - SINGLETON
    static let shared: OAuthManager = OAuthManager()
    private init() { }
    
    // MARK: - PROPERTIES
    
    var urlSession: URLSession {
        // 캐시・쿠키 등 자격 증명을 디스크에 기록하지 않는 URLSession 설정
        return URLSession(configuration: .ephemeral)
    }
    
    // MARK: - FUNCTIONS
    
    @discardableResult
    func getAuthCookies() async -> Bool {
        // URL 만들기
        guard let url = URL(string: OAuthURL.auth) else { return false }
        // HTTP Body 만들기
        let authCookiesBody = AuthCookiesBody()
        // URLRequest 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = encode(authCookiesBody)
        // 비동기 HTTP 통신하기
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              (200..<300) ~= statusCode else {
            return false
        }
        // For Debug
        dump(data)
        // 결과 반환하기
        return true
    }
    
    private func encode<T: Encodable>(_ data: T) -> Data {
        let encoder = JSONEncoder()
        return try! encoder.encode(data)
    }
    
}
