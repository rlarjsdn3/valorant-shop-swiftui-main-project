//
//  Color+Extension.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI

extension Color {
    
    static var systemBackground: Color {
        Color(uiColor: UIColor.systemBackground)
    }
    
    static var secondarySystemBackground: Color {
        Color(uiColor: UIColor.secondarySystemBackground)
    }
    
    static var valorant: Color {
        Color(red: 235.0 / 255.0, green: 86.0 / 255.0, blue: 91.0 / 255.0)
    }
    
    static var selectEdition: Color {
        Color(red: 90.0 / 255.0, green: 159.0 / 255.0, blue: 226.0 / 255.0)
    }
    
    static var deulxeEdition: Color {
        Color(red: 0 / 255.0, green: 149.0 / 255.0, blue: 135.0 / 255.0)
    }
    
    static var premiumEdition: Color {
        Color(red: 209.0  / 255.0, green: 84.0 / 255.0, blue: 141.0 / 255.0)
    }
    
    static var exclusiveEdition: Color {
        Color(red: 245.0 / 255.0, green: 149.0 / 255.0, blue: 91.0 / 255.0)
    }
    
    static var ultraEdition: Color {
        Color(red: 250.0 / 255.0, green: 214.0 / 255.0, blue: 99.0 / 255.0)
    }
    
}
