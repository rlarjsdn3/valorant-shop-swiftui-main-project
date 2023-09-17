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
    
    @Binding var selectedCustomTab: CustomTabType
    
    // MARK: - INTIALIZER
    
    init(_ selectedCustomTab: Binding<CustomTabType>) {
        self._selectedCustomTab = selectedCustomTab
    }
    
    // MARK: - BODY
    
    var body: some View {
        HStack {
            ForEach(CustomTabType.allCases) { type in
                Spacer()
                
                Button {
                    haptics.play(.soft)
                    selectedCustomTab = type
                } label: {
                    Image(systemName: type.imageName)
                        .fontWeight(.bold)
                        .foregroundColor(type == selectedCustomTab ? Color.valorantThemeColor : Color.black)
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
        CustomTabView(.constant(.shop))
    }
}
