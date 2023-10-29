//
//  SettingsViewModel.swift
//  ValorantShop
//
//  Created by 김건우 on 10/29/23.
//

import Foundation
import Kingfisher

// MARK: - VIEW MODEL

final class SettingsViewModel: NSObject, ObservableObject {
    
    // MARK: - WRAPPER PROPERTIES
    
    // For ImageCache
    @Published var diskCacheSize: String = "0.0"
    
    // MARK: - PROPERTIES
    
    let imageCache = ImageCache.default
    
    let realmManager = RealmManager.shared
    
    // MARK: - FUNCTIONS
    
    func calculateDiskCache() {
        imageCache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                let mb = Float(size) / 1024.0 / 1024.0
                let formatter = NumberFormatter()
                formatter.minimumFractionDigits = 1
                // ✏️ 업-캐스팅을 하므로 as?, as!와 같은 키워드는 안 써도 됨.
                self.diskCacheSize = formatter.string(from: mb as NSNumber) ?? "0.0"
            case .failure:
                self.diskCacheSize = "0.0"
            }
        }
    }
    
    func clearDiskCache() {
        imageCache.clearDiskCache {
            self.diskCacheSize = "0.0"
        }
    }
    
    func getClientVersion() -> String {
        let version = realmManager.read(of: Version.self)
        if let riotClientVersion = version.first?.client?.riotClientVersion {
            let version = riotClientVersion.split(separator: "-")[1]
            return String(version)
        }
        return "-"
    }
    
}
