//
//  DBUpdateView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/25.
//

import SwiftUI

struct DBUpdateView: View {
    
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
        List {
            Section {
                Button("업데이트 확인") {
                    Task {
                        await viewModel.checkValorantVersion()
                    }
                }
            } header: {
                Text("업데이트")
            } footer: {
                Text("최근 업데이트 확인: \(lastUpdateCheckDateString)\n\n애플리케이션이 발로란트의 스킨 정보를 올바르게 표시하기 위해 DB가 최신 상태를 유지하여야 합니다. 애플리케이션은 주기적으로 업데이트를 확인하며, 미업데이트 시 애플리케이션 이용이 제한됩니다. ")
            }
        }
    }
}

// MARK: - PREVIEW

struct DBUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        DBUpdateView()
            .environmentObject(ViewModel())
    }
}
