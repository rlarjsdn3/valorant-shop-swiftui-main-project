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
        formatter.dateFormat = "M월 d일(E) H:m"
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
                    Button("로그아웃") {
                        viewModel.logout()
                    }
                }
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
