//
//  SettingsView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    @EnvironmentObject var settingsViewmodel: SettingsViewModel
    
    @State private var isPresentLogoutDialog: Bool = false
    
    // MARK: - BODY
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    rowLabel(
                        "Riot ID",
                        subText: "\(resourceViewModel.gameName)",
                        systemName: "person",
                        accentColor: Color.red
                    )
                    
                    rowLabel(
                        "Tag Line",
                        subText: "#\(resourceViewModel.tagLine)",
                        systemName: "tag",
                        accentColor: Color.green
                    )
                } header: {
                    Text("계정 정보")
                }
                
                Section {
                    rowLabel(
                        "VP",
                        subText: "\(resourceViewModel.vp)",
                        ImageName: "VP"
                    )
                    
                    rowLabel(
                        "RP",
                        subText: "\(resourceViewModel.rp)",
                        ImageName: "RP"
                    )
                    
                    rowLabel(
                        "KP",
                        subText: "\(resourceViewModel.kp)",
                        ImageName: "KP"
                    )
                }
                
                Section {
                    NavigationLink {
                        DataManagementView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("데이터 관리")
                    } label: {
                        rowLabel("캐시 및 데이터 관리", systemName: "externaldrive", accentColor: Color.gray)
                    }
                } header: {
                    Text("문서 및 데이터")
                }

                Button("dd") {
                    resourceViewModel.storeSkinsRenewalDate = Date(timeIntervalSinceNow: -86400 * 2)
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button("로그아웃", role: .destructive) {
                            isPresentLogoutDialog = true
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("설정")
        }
        .confirmationDialog("", isPresented: $isPresentLogoutDialog) {
            Button("로그아웃", role: .destructive) {
                loginViewModel.logout()
            }
        } message: {
            Text("로그아웃하시겠습니까?")
        }

    }
    
    // MARK: - FUNCTIONS
    
    @ViewBuilder
    func rowLabel(_ text: String, subText: String? = nil, ImageName name: String? = nil) -> some View {
        HStack {
            if let imageName = name {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            
            Text("\(text)")
            
            Spacer()
            
            if let subText = subText {
                Text("\(subText)")
                    .foregroundColor(Color.secondary)
            }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(LoginViewModel())
            .environmentObject(ResourceViewModel())
            .environmentObject(SettingsViewModel())
    }
}
