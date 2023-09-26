//
//  SkinDetailView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/26.
//

import SwiftUI

struct SkinDetailView: View {
    
    // MARK: - PROPERTIES
    
    var skinInfo: SkinInfo
    
    // MARK: - INITALIZER
    
    init(_ skinInfo: SkinInfo) {
        self.skinInfo = skinInfo
    }
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            Text(skinInfo.skin.displayName)
        }
    }
}

// MARK: - PREVIEW

struct SkinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SkinDetailView(Previews.skinInfo)
    }
}
