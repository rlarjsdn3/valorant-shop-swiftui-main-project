//
//  OAuthView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/21.
//

import SwiftUI

struct OAuthView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    // MARK: - BODY
    
    var body: some View {
        NavigationStack {
            LoginView()
                .navigationDestination(isPresented: $loginViewModel.isPresentDataDownloadView) {
                    DataDownloadView(of: .download)
                        .navigationBarBackButtonHidden()
                }
                .navigationBarBackButtonHidden()
        }
    }
    
}

// MARK: - PREVIEW

struct OAuthView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthView()
            .environmentObject(LoginViewModel())
    }
}
