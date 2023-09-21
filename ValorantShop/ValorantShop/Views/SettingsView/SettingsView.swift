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
                    Button("데이터 다운로드", role: .destructive) {
                        viewModel.isPresentDataDownloadView = true
                    }
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
            DataDownloadView()
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
