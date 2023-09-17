//
//  OAuthManager.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import Foundation
import KeychainAccess

// MARK: - ERROR

enum OAuthError: Error {
    case urlError
    case statusCodeError
    case needMultifactor
    case encodeError
    case decodeErorr
    case noTokenError
}

// MARK: - HTTP BODY

struct AuthCookiesBody: Encodable {
    let client_id: String = "play-valorant-web-prod"
    let nonce: String = "1"
    let redirect_uri: String = "https://playvalorant.com/opt_in"
    let response_type: String = "token id_token"
}

struct AuthRequestBody: Encodable {
    let type: String = "auth"
    let username: String
    let password: String
}

// MARK: - HTTP RESPONSE

struct AuthRequestResponse: Decodable {
    let type: String?
    let response: Response?
}

struct Response: Decodable {
    let parameters: URI?
}

struct URI: Decodable {
    let uri: String?
}

struct EntitlementResponse: Decodable {
    let entitlementToken: String?
    
    enum CodingKeys: String, CodingKey {
        case entitlementToken = "entitlements_token"
    }
}

struct PlayerInfoResponse: Decodable {
    let uuid: String
    
    enum CodingKeys: String, CodingKey {
        case uuid = "sub"
    }
}
    
// MARK: - MANAGER

final class OAuthManager {
    
    // MARK: - SINGLETON
    static let shared: OAuthManager = OAuthManager()
    private init() { }
    
    // MARK: - PROPERTIES
    
    let keychain: Keychain = Keychain()
    // 캐시・쿠키 등 자격 증명을 디스크에 기록하지 않는 URLSession 설정
    let urlSession: URLSession = URLSession(configuration: .ephemeral)
    
    // MARK: - FUNCTIONS
    
    @discardableResult
    func fetchAuthCookies() async -> Result<Bool, OAuthError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: OAuthURL.auth) else { return .failure(.urlError) }
        // HTTP Body 만들기
        let authCookiesBody = AuthCookiesBody()
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = self.encode(authCookiesBody)
        
        // 비동기 HTTP 통신하기
        let (_, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            return .failure(.statusCodeError)
        }
        
        // 결과 반환하기
        return .success(true)
    }
    
    @discardableResult
    func fetchReAuthCookies() async -> Result<String, OAuthError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: OAuthURL.reAuth) else { return .failure(.urlError) }
        // HTTP Body 만들기
        let reAuthCookiesBody = AuthCookiesBody()
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = self.encode(reAuthCookiesBody)
        // 키체인으로부터 SSID를 가져와 쿠키로 설정하기
        guard let ssid = keychain["SSID"] else {
            return .failure(.noTokenError)
        }
        self.setCookie(ssid, key: "ssid")
        
        // 비동기 HTTP 통신하기
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let authRequestResponse = decode(of: AuthRequestResponse.self, data),
              let uri = authRequestResponse.response?.parameters?.uri else {
            print("파싱 에러")
            return .failure(.decodeErorr)
        }
        // 리다이렉트된 URI에서 Access Token 추출하기
        let tokenPattern: String = #"access_token=((?:[a-zA-Z]|\d|\.|-|_)*).*id_token=((?:[a-zA-Z]|\d|\.|-|_)*).*expires_in=(\d*)"#
        guard let range = uri.range(of: tokenPattern, options: .regularExpression) else {
            print("정규표현식 에러")
            return .failure(.noTokenError)
        }
        let accessToken = String(uri[range].split(separator: "&")[0].split(separator: "=")[1])
        
        // 결과 반환하기
        return .success(accessToken)
        
    }
    
    @discardableResult
    func fetchAccessToken(username: String, password: String) async -> Result<String, OAuthError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: OAuthURL.auth) else { return .failure(.urlError) }
        // HTTP BODY 만들기
        let authRequestBody = AuthRequestBody(
            username: username,
            password: password
        )
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = self.encode(authRequestBody)
        
        // 비동기 HTTP 통신하기
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let authRequestResponse = decode(of: AuthRequestResponse.self, data),
              let uri = authRequestResponse.response?.parameters?.uri else {
            print("파싱 에러")
            return .failure(.decodeErorr)
        }
        
        // 리다이렉트된 URI에서 Access Token 추출하기
        let tokenPattern: String = #"access_token=((?:[a-zA-Z]|\d|\.|-|_)*).*id_token=((?:[a-zA-Z]|\d|\.|-|_)*).*expires_in=(\d*)"#
        guard let range = uri.range(of: tokenPattern, options: .regularExpression) else {
            print("정규 표현식 에러")
            return .failure(.noTokenError)
        }
        let accessToken = String(uri[range].split(separator: "&")[0].split(separator: "=")[1])
        print(accessToken) // ...
        // ReAuth를 위해 SSID와 TDID값을 키체인에 저장하기
        saveSSIDToKeyChain(httpResponse)
        
        // 결과 반환하기
        return .success(accessToken)
    }
    
    func fetchRiotEntitlement(accessToken token: String) async -> Result<String, OAuthError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: OAuthURL.entitlement) else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 비동기 HTTP 통신하기
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let entitlementResponse = self.decode(of: EntitlementResponse.self, data),
              let riotEntitlement = entitlementResponse.entitlementToken else {
            return .failure(.decodeErorr)
        }
        
        // 결과 반환하기
        return .success(riotEntitlement)
    }
    
    func fetchRiotAccountPUUID(accessToken token: String) async -> Result<String, OAuthError> {
        // For Debug
        print(#function)
        
        // URL 만들기
        guard let url = URL(string: OAuthURL.userInfo) else { return .failure(.urlError) }
        // URL Request 만들기
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 비동기 HTTP 통신하기
        let (data, response) = try! await urlSession.data(for: urlRequest)
        // 상태 코드가 올바른지 확인하기
        guard let httpResponse = (response as? HTTPURLResponse),
              (200..<300) ~= httpResponse.statusCode else {
            print("상태 코드 에러")
            return .failure(.statusCodeError)
        }
        // 받아온 데이터를 파싱하기
        guard let playerInfoResponse = self.decode(of: PlayerInfoResponse.self, data) else {
            print("파싱 에러")
            return .failure(.decodeErorr)
        }
        print("puuid = \(playerInfoResponse.uuid)")
        
        // 결과 반환하기
        return .success(playerInfoResponse.uuid)
    }
    
    private func saveSSIDToKeyChain(_ httpResponse: HTTPURLResponse) {
        // For Dubug
        print(#function)
        
        // ReAuth를 위해 SSID와 TDID값을 키체인에 저장하기
        guard let setCookie = (httpResponse.allHeaderFields["Set-Cookie"] as? String) else {
            return
        }
        
        let cookiePattern: String = #"ssid=((?:[a-zA-Z]|\d|\.|-|_)*)"#
        guard let range = setCookie.range(of: cookiePattern, options: .regularExpression) else {
            return
        }
        let ssid = String(setCookie[range].split(separator: "=")[1])
        keychain["SSID"] = ssid
    }
    
    private func setCookie(_ value: String, key: String) {
        // For Debug
        print(#function)
        
        // 쿠키 설정하기
        urlSession.configuration.httpCookieStorage?.setCookie(
            HTTPCookie(properties: [
                .name: key,
                .value: value,
                .path: "/",
                .domain: "auth.riotgames.com"
            ])!
        )
        
    }
    
    private func encode<T: Encodable>(_ data: T) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(data)
    }
    
    private func decode<T: Decodable>(of type: T.Type, _ data: Data) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
}
