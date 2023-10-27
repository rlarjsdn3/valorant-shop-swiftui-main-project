//
//  HapticManager.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import UIKit

final class HapticManager {
    
    // MARK: - SINGLETON
    
    static let shared = HapticManager()
    private init() { }
    
    // MARK: - FUNCTIONS
    
    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    func notify(_ feedbackStyle: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackStyle)
    }
}
