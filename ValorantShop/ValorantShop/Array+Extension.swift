//
//  Dictionary+Extension.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/24.
//

import Foundation

// ⭐️ 배열을 UserDefaults에 저장하게 하기
extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
