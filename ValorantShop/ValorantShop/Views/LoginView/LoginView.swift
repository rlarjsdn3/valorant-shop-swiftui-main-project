//
//  LoginView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var inputUsername: String = ""
    @State private var inputPassword: String = ""
    
    @State private var isPresenetDownloadView: Bool = false
    
    // MARK: - BODY
    
    var body: some View {
        VStack {
            Text("Valorant Shop")
                .font(.custom(Fonts.valorantFont, size: 40))
                .foregroundColor(Color.valorantThemeColor)
            
            Group {
                TextField("아이디", text: $inputUsername)
                SecureField("패스워드", text: $inputPassword)
            }
            .textFieldStyle(.roundedBorder)
            
            Button("로그인") {
                Task {
                    await viewModel.login(
                        username: inputUsername,
                        password: inputPassword
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("로그아웃") {
                viewModel.logout()
            }
            .buttonStyle(.borderedProminent)
            
            Button("데이터 다운로드") {
                isPresenetDownloadView = true
            }
            .buttonStyle(.borderedProminent)
            
            Button("오늘의 상점") {
                Task {
                    await viewModel.getStoreRotationWeaponSkins()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(isPresented: $isPresenetDownloadView) {
            DownloadView()
        }
        .sheet(isPresented: $viewModel.isPresentMultifactorAuthView) {
            MultifactorAuthView()
        }
    }
}

// MARK: - PREVIEW

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(ViewModel())
    }
}
