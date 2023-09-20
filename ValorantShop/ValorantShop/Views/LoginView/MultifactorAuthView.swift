//
//  MultifactorAuthView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/18.
//

import SwiftUI

struct MultifactorAuthView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var inputAuthenticationCode: String = ""
    
    // MARK: - BODY
    
    var body: some View {
        VStack {
            Text("Login Code")
                .font(.custom(Fonts.valorantFont, size: 40))
            
            Text("로그인 인증 코드가 포함된 메시지가 \(viewModel.multifactorAuthEmail)로 전송되었습니다. 계속하려면 코드를 입력하십시오.")
            
            TextField("로그인 코드", text: $inputAuthenticationCode)
                .textFieldStyle(.roundedBorder)
            
            Button("확인") {
                Task {
                    await viewModel.login(authenticationCode: inputAuthenticationCode)
                }
            }
        }
        .padding()
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
