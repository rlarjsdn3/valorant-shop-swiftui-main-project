//
//  LoadingView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/25.
//

import SwiftUI

struct LoadingView: View {
    
    // MARK: - BODY
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(2.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemBackground)
    }
}

// MARK: - PREVIEW

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
