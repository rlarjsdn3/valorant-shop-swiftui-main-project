//
//  DBUpdateView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/25.
//

import SwiftUI

struct DataManagementView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    // MARK: - COMPUTED PROPERTIES
    
    var lastUpdateCheckDateString: String {
        let lastUpdateCheckDate: Date = Date(timeIntervalSinceReferenceDate: resourceViewModel.lastUpdateCheckDate)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일(E) HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: lastUpdateCheckDate)
    }
    
    // MARK: - BODY
    
    var body: some View {
        List {
            Section {
                rowLabel(
                    "캐시 크기",
                    subText: "\(settingsViewModel.diskCacheSize)MB",
                    systemName: "memorychip",
                    accentColor: Color.green
                )
                
                Button("캐시 비우기") {
                    settingsViewModel.clearDiskCache()
                }
            } header: {
                Text("캐시")
            } footer: {
                Text("애플리케이션은 스킨 썸네일을 빠르게 표시하기 위해 자주 로드하는 이미지를 캐시에 저장합니다.\n\n이 작업은 자동으로 수행되며, 임의로 켜거나 끌 수 없습니다. 애플리케이션은 이미지 로드 주기를 분석해 자동으로 캐시를 비웁니다.\n\n임의로 전체 캐시를 비우게 되면 일시적으로 이미지를 로드하는 속도가 느려질 수 있습니다.")
            }

            
            Section {
                
                rowLabel("버전", subText: settingsViewModel.getClientVersion())
                
                Button("업데이트 확인") {
                    Task {
                        await resourceViewModel.checkValorantVersion()
                    }
                }
            } header: {
                Text("업데이트")
            } footer: {
                Text("최근 업데이트 확인: \(lastUpdateCheckDateString)\n\n애플리케이션은 발로란트의 스킨 정보를 올바르게 표시하기 위해 데이터베이스가 최신 상태를 유지하여야 합니다. 애플리케이션은 주기적으로 업데이트를 확인하며, 미업데이트 시 애플리케이션 이용이 제한됩니다. ")
            }
        }
        .onAppear {
            settingsViewModel.calculateDiskCache()
        }
    }
    
    @ViewBuilder
    func rowLabel(_ text: String, subText: String? = nil, systemName name: String? = nil, accentColor color: Color? = nil) -> some View {
        HStack {
            if let systemName = name,
               let accentColor = color {
                Image(systemName: systemName)
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color.white)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 10))
            }
            
            Text("\(text)")
            
            Spacer()
            
            if let subText = subText {
                Text("\(subText)")
                    .foregroundColor(Color.secondary)
            }
        }
    }
    
}

// MARK: - PREVIEW

struct DBUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        DataManagementView()
            .environmentObject(ResourceViewModel())
            .environmentObject(SettingsViewModel())
    }
}
