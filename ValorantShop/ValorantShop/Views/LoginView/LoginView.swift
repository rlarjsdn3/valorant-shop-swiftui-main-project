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
    
    // MARK: - BODY
    
    var body: some View {
        VStack {
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
            
            Button("ReAuth") {
                Task {
                    await viewModel.reAuth()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("fetch RiotVersion") {
                Task {
                    await viewModel.fetchRiotVersion()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("fetch Wallet") {
                Task {
                    await viewModel.fetchWallet()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("fetch WeaponSkins") {
                Task {
                    await viewModel.fetchWeaponSkins()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("fetch WeaponPrices") {
                Task {
                    await viewModel.fetchWeaponPrices()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("로그아웃") {
                Task {
                    await viewModel.logout()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - PREVIEW

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(ViewModel())
    }
}
