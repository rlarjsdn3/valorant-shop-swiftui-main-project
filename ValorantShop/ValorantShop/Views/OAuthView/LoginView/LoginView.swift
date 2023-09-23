//
//  LoginView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - FOCUS
    
    private enum FocusField {
        case username
        case password
    }
    
    @FocusState private var focusField: FocusField?
    
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
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
            
            VStack(alignment: .leading) {
                
                Spacer()
                
                Text("로그인")
                    .font(.system(.title2, weight: .bold))
                    .offset(y: loginTextAnimation ? 0 : screenSize.height)
                
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(Color.secondary)
                        TextField("계정이름", text: $inputUsername)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .password
                            }
                            .focused($focusField, equals: .username)
                            .textInputAutocapitalization(.never)
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
                            .submitLabel(.done)
                            .onSubmit {
                                dismissKeyboard()
                                Task {
                                    await viewModel.login(
                                        username: inputUsername,
                                        password: inputPassword
                                    )
                                }
                            }
                            .focused($focusField, equals: .password)
                            .textInputAutocapitalization(.never)
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
                    
                    
                    Text("\(viewModel.loginErrorText)")
                        .font(.caption)
                        .foregroundColor(Color.valorant)
                        .frame(height: 10)
                        .offset(y: passwordTextFieldAnimation ? 0 : screenSize.height)
                    
                    Button {
                        dismissKeyboard()
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
                                    .font(.system(.title2, weight: .bold))
                                    .foregroundColor(Color.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.valorant, in: RoundedRectangle(cornerRadius: 15))
                    }
                    .padding(.top, 1)
                    .offset(y: loginButtonAnimation ? 0 : screenSize.height)
                    .modifier(ShakeEffect(animatableData: viewModel.loginButtonShakeAnimation))
                    
                    Spacer()
                }
                .onAppear {
                    loginAnimation()
                }
                .onDisappear {
                    viewModel.loginErrorText = ""
                }
                .onChange(of: focusField) { newValue in
                    if newValue == .username || newValue == .password {
                        withAnimation(.spring()) {
                            mainTextAnimation = false
                            keyboardAnimation = true
                        }
                    } else if newValue == nil {
                        withAnimation(.spring()) {
                            mainTextAnimation = true
                            keyboardAnimation = false
                        }
                    }
                }
                .overlay(alignment: .top) {
                    VStack {
                        Text("Valorant")
                        Text("Store")
                    }
                    .font(.custom(Fonts.valorantFont, size: 50))
                    .padding(.top, screenSize.height * 0.1)
                    .offset(y: mainTextAnimation ? 0 : -screenSize.height)
                }
                .overlay(alignment: .bottom) {
                    Link(destination: URL(string: RiotURL.canNotLogin)!) {
                        Text("로그인이 안되시나요?")
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(helpButtonAnimation ? 1 : 0)
                }
                .padding(20)
                .offset(y: keyboardAnimation ? -(screenSize.height * 0.1) : 0)
        }
        .overlay {
            if viewModel.isPresentMultifactorAuthView {
                MultifactorAuthView()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - FUNCTION
    
    func loginAnimation() {
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
}

// MARK: - PREVIEW

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(ViewModel())
    }
}
