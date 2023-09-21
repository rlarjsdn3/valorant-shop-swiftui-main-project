//
//  MultifactorAuthView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/18.
//

import SwiftUI
import Combine

struct MultifactorAuthView: View {
    
    // MARK: - FOCUS
    
    private enum FocusField {
        case code
    }
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // For TextField
    @State private var inputCode: String = ""
    @FocusState private var focusField: FocusField?
    
    // For Animation
    @State private var materialAnimation: Bool = false
    @State private var codeBoxAnimation: Bool = false
    
    // MARK: - PROPERTIES
    
    let codeLimit: Int = 6
    
    // MARK: - BODY
    
    var body: some View {
        ZStack {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .opacity(materialAnimation ? 1 : 0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            dismissKeyboard()
                            viewModel.isPresentMultifactorAuthView = false
                            viewModel.multifactorErrorText = ""
                        }
                    }
            
            VStack(alignment: .leading) {
                Text("Login Code")
                    .font(.custom(Fonts.valorantFont, size: 40))
                
                Text("로그인 인증 코드가 포함된 메시지가 \(viewModel.multifactorAuthEmail)로 전송되었습니다. 계속하려면 코드를 입력하십시오.")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                
                TextField("", text: $inputCode)
                    .padding()
                    .multilineTextAlignment(.center)
                    .font(.system(.title2, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .onReceive(Just(inputCode)) { _ in
                        if inputCode.count > codeLimit {
                            inputCode = String(inputCode.prefix(codeLimit))
                        }
                    }
                    .keyboardType(.numberPad)
                    .offset(x: 2)
                    .focused($focusField, equals: .code)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1.0)
                            .foregroundColor(Color.secondary)
                    }
                    .modifier(ShakeEffect(animatableData: viewModel.codeBoxShakeAnimation))
                
                Text("\(viewModel.multifactorErrorText)")
                    .font(.caption)
                    .foregroundColor(Color.valorant)
                    .frame(height: 10)
                    .foregroundColor(Color.valorant)
            }
            .onChange(of: inputCode) { input in
                if input.count == 6 {
                    Task {
                        await viewModel.login(authenticationCode: inputCode)
                    }
                }
            }
            .onChange(of: viewModel.codeBoxShakeAnimation) { _ in
                inputCode = ""
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.isLoadingMultifactor {
                    ProgressView()
                        .padding(7)
                }
            }
            .padding(.horizontal)
            .padding(.top, 30)
            .padding(.bottom, 15)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 15))
            .offset(y: codeBoxAnimation ? -(screenSize.height * 0.2) : -screenSize.height)
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                materialAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring()) {
                        focusField = .code
                        codeBoxAnimation = true
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - PREVIEW

struct MultifactorAuthView_Previews: PreviewProvider {
    static var previews: some View {
        MultifactorAuthView()
            .environmentObject(ViewModel())
            .previewLayout(.sizeThatFits)
    }
}
