//
//  SettingsView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - COMPUTED PROPERTIES
    
    var lastUpdateCheckDateString: String {
        let lastUpdateCheckDate: Date = Date(timeIntervalSinceReferenceDate: viewModel.lastUpdateCheckDate)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일(E) HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: lastUpdateCheckDate)
    }
    
    // MARK: - BODY
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(viewModel.gameName)")
                    Text("#\(viewModel.tagLine)")
                } header: {
                    Text("사용자 정보")
                }
                
                Section {
                    Button("업데이트 확인") {
                        Task {
                            await viewModel.checkValorantVersion()
                        }
                    }
                } footer: {
                    Text("최근 업데이트 확인: \(lastUpdateCheckDateString)")
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button("로그아웃", role: .destructive) {
                            viewModel.logout()
                        }
                        Spacer()
                    }
                }
                
                // -- For Debug --
                Button("시간 되돌리기") {
                    viewModel.storeSkinsExpiryDate = Date()
                    viewModel.timer?.invalidate()
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
                // ---------------
            }
            .navigationTitle("설정")
        }
        .sheet(isPresented: $viewModel.isPresentDataDownloadView) {
            DataDownloadView(of: .update)
        }
    }
}

// MARK: - PREVIEW

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ViewModel())
    }
}
