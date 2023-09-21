//
//  LoginView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/14.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - TEXTFIELD FOCUS
    
    private enum LoginTextFieldFocus {
        case username
        case password
    }
    
    @FocusState private var focusField: LoginTextFieldFocus?
    
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
                    .focused($focusField, equals: LoginTextFieldFocus.username)
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
                        focusField = nil
                    }
                    .focused($focusField, equals: LoginTextFieldFocus.password)
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
                .opacity(viewModel.loginErrorText.isEmpty ? 0.0 : 1.0)
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
                .frame(height: 53)
                .background(Color.valorant, in: RoundedRectangle(cornerRadius: 15))
            }
            .padding(.top, 1)
            .offset(y: loginButtonAnimation ? 0 : screenSize.height)
            .modifier(ShakeEffect(animatableData: viewModel.loginButtonShakeAnimation))
            
            Spacer()
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
        .background {
            // ⭐️ 흰색 바탕의 뷰를 클릭하면 키보드가 사라지게 함.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
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
        .onChange(of: focusField, perform: { newValue in
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
        })
        .sheet(isPresented: $viewModel.isPresentMultifactorAuthView) {
            MultifactorAuthView()
        }
        // For Debug
        .overlay(alignment: .bottomTrailing) {
            Menu {
                Button("로그아웃") {
                    viewModel.logoutForDeveloper()
                }
                
                Button("모든 데이터 삭제하기") {
                    viewModel.DeleteAllApplicationDataForDeveloper()
                }
            } label: {
                Text("개발자")
            }
        }
        .sheet(isPresented: $viewModel.isPresentDownloadView) {
            DownloadView()
        }
        // ----------
        .offset(y: keyboardAnimation ? -(screenSize.height * 0.1) : 0)
        .padding(20)
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
