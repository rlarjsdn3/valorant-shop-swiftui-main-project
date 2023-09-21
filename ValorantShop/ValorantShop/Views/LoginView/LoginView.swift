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
    
    // For TextField
    @State private var inputUsername: String = ""
    @State private var inputPassword: String = ""
    
    // For Animation
    @State private var keyboardAnimation: Bool = false
    @State private var mainTextAnimation: Bool = false
    @State private var loginTextAnimation: Bool = false
    @State private var userNameTextFieldAnimation: Bool = false
    @State private var passwordTextFieldAnimation: Bool = false
    @State private var loginButtonAnimation: Bool = false
    @State private var helpButtonAnimation: Bool = false
    
    // MARK: - BODY
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            
            Text("로그인")
                .font(.title3)
                .fontWeight(.bold)
                .offset(y: loginTextAnimation ? 0 : screenSize.height)
            
            Group {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(Color.secondary)
                    TextField("계정이름", text: $inputUsername)
                    if !inputUsername.isEmpty {
                        Button {
                            inputUsername = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.secondary)
                        }
                    }
                }
                .frame(height: 55)
                .padding(.horizontal)
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(lineWidth: 1)
                        .foregroundColor(Color.secondary)
                }
                .offset(y: userNameTextFieldAnimation ? 0 : screenSize.height)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(Color.secondary)
                    SecureField("비밀번호", text: $inputPassword)
                    if !inputPassword.isEmpty {
                        Button {
                            inputPassword = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.secondary)
                        }
                    }
                }
                .frame(height: 55)
                .padding(.horizontal)
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(lineWidth: 1)
                        .foregroundColor(Color.secondary)
                }
                .offset(y: passwordTextFieldAnimation ? 0 : screenSize.height)
            }
            
            Text("\(viewModel.loginErrorText)")
                .font(.caption)
                .foregroundColor(Color.valorant)
                .frame(height: 10)
                .opacity(viewModel.loginErrorText.isEmpty ? 0.0 : 1.0)
                .offset(y: passwordTextFieldAnimation ? 0 : screenSize.height)
            
            Button {
                self.dismissKeyboard()
                Task {
                    await viewModel.login(
                        username: inputUsername,
                        password: inputPassword
                    )
                }
            } label: {
                Group {
                    if viewModel.isLoadingLogin {
                        ProgressView()
                    } else {
                        Text("로그인")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 53)
                .background(Color.valorant, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(.top, 1)
            .offset(y: loginButtonAnimation ? 0 : screenSize.height)
            .modifier(ShakeEffect(animatableData: viewModel.loginButtonShakeAnimation))
            
            Spacer()
        }
        .background {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.dismissKeyboard()
                }
        }
        .overlay(alignment: .top) {
            VStack {
                Text("Valorant")
                Text("Store")
            }
            .font(.custom(Fonts.valorantFont, size: 50))
            .padding(.top, 100)
            .offset(y: mainTextAnimation ? 0 : -screenSize.height)
        }
        .overlay(alignment: .bottom) {
            HStack {
                Link(destination: URL(string: "https://recovery.riotgames.com/ko")!) {
                    Text("로그인이 안되시나요?")
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                .opacity(helpButtonAnimation ? 1 : 0)
                
                Button("다운로드") {
                    viewModel.isPresentDownloadView = true
                }
            }
        }
        .padding(20)
        .sheet(isPresented: $viewModel.isPresentMultifactorAuthView) {
            MultifactorAuthView()
        }
        .sheet(isPresented: $viewModel.isPresentDownloadView) {
            DownloadView()
        }
        .onAppear {
            viewModel.loginErrorText = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring()) {
                    mainTextAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring()) {
                        loginTextAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.spring()) {
                            userNameTextFieldAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.spring()) {
                                passwordTextFieldAnimation = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring()) {
                                    loginButtonAnimation = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.spring()) {
                                        helpButtonAnimation = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)) { _ in
            withAnimation(.spring()) {
                mainTextAnimation = false
                keyboardAnimation = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)) { _ in
            withAnimation(.spring()) {
                mainTextAnimation = true
                keyboardAnimation = false
            }
        }
        .offset(y: keyboardAnimation ? -(screenSize.height * 0.1) : 0)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - PREVIEW

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(ViewModel())
    }
}
