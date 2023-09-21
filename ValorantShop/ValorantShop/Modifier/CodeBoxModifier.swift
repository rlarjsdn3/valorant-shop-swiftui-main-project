//
//  CodeBoxModifier.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/21.
//

import SwiftUI
import Combine

extension View {
    func codeBox(inputCode: Binding<String>) -> some View {
        modifier(CodeBoxModifier(inputCode: inputCode))
    }
}

struct CodeBoxModifier: ViewModifier {
    
    // MARK: - WRAPPER PROPERTIES
    
    @Binding var inputCode: String
    
    // MARK: - PROPERTIES
    
    let textLimit: Int = 1
    
    // MARK: - BODY
    
    func body(content: Content) -> some View {
        content
    }
}
