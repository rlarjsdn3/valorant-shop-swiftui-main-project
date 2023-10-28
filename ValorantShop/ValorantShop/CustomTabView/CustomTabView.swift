//
//  CustomTabView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/12.
//

import SwiftUI

// MARK: - ENUM

enum CustomTabType: String, CaseIterable {
    case shop
    case collection
    case settings
    
    var imageName: String {
        switch self {
        case .shop:
            return "cart"
        case .collection:
            return "list.dash"
        case .settings:
            return "gear"
        }
    }
}

extension CustomTabType: Identifiable {
    var id: String { self.rawValue }
}

// MARK: - VIEW

struct CustomTabView: View {
    
    // MARK: - PROPERTIES
    
    let haptics = HapticManager.shared

    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    // MARK: - BODY
    
    var body: some View {
        HStack {
            ForEach(CustomTabType.allCases) { type in
                Spacer()
                
                Button {
                    haptics.play(.medium)
                    loginViewModel.selectedCustomTab = type
                } label: {
                    Image(systemName: type.imageName)
                        .fontWeight(.bold)
                    // ✏️ Color.black로 한다면, 다크 모드가 원하는대로 적용되지 않음.
                        .foregroundColor(type == loginViewModel.selectedCustomTab ? Color.valorant : Color.primary)
                        .padding()
                }

                Spacer()
            }
        }
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - PREVIEW

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabView()
            .environmentObject(LoginViewModel())
    }
}
