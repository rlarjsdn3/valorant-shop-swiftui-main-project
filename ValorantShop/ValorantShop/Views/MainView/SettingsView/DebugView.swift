//
//  DebugView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/25.
//

import SwiftUI

struct DebugView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - BODY
    
    var body: some View {
        List {
            // -- For Debug --
            Button("로테이션 시간 되돌리기") {
                let skin = viewModel.realmManager.read(of: StoreSkinsList.self)
                try! viewModel.realmManager.realm.write {
                    skin[0].renewalDate = Date().addingTimeInterval(-2 * 3600 * 24)
                }
                Task {
                    await viewModel.getStoreSkins()
                }
            }
            
            Button("번들 시간 되돌리기") {
                let skin = viewModel.realmManager.read(of: StoreBundlesList.self)
                try! viewModel.realmManager.realm.write {
                    skin[0].renewalDate = Date().addingTimeInterval(-2 * 3600 * 24)
                }
            }
            
            Button("스킨 데이터 삭제") {
                viewModel.realmManager.deleteAll(of: StoreSkinsList.self)
            }
            Button("토큰 만료 시간 초기화") {
                viewModel.accessTokenExpiryDate = 0.0
            }
            
            Button("번들 정보 가져오기") {
                Task {
                    await viewModel.getStoreBundles(forceLoad: true)
                }
            }
            
            Button("내가 가진 스킨 가져오기") {
                Task {
                    await viewModel.getOwnedWeaponSkins()
                }
            }
            // ---------------
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
            .environmentObject(ViewModel())
    }
}
