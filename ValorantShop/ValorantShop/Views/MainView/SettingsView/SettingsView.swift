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
                    rowLabel(
                        "Riot ID",
                        subText: "\(viewModel.gameName)",
                        systemName: "person",
                        accentColor: Color.red
                    )
                    
                    rowLabel(
                        "Tag Line",
                        subText: "#\(viewModel.tagLine)",
                        systemName: "tag",
                        accentColor: Color.green
                    )
                } header: {
                    Text("계정 정보")
                }
                
                Section {
                    rowLabel(
                        "VP",
                        subText: "\(viewModel.vp)",
                        ImageName: "VP"
                    )
                    
                    rowLabel(
                        "RP",
                        subText: "\(viewModel.rp)",
                        ImageName: "RP"
                    )
                    
                    rowLabel(
                        "KP",
                        subText: "\(viewModel.kp)",
                        ImageName: "KP"
                    )
                }
                
                Section {
                    NavigationLink {
                        DataManagementView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("데이터 관리")
                    } label: {
                        rowLabel("데이터 관리", systemName: "externaldrive", accentColor: Color.gray)
                    }
                } header: {
                    Text("데이터 관리")
                }

                // - For Debug -----
                Section {
                    NavigationLink {
                        DebugView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("개발자")
                    } label: {
                        rowLabel("개발자", systemName: "hammer", accentColor: Color.blue)
                    }
                }
                // -----------------
                
                Section {
                    HStack {
                        Spacer()
                        Button("로그아웃", role: .destructive) {
                            viewModel.logout()
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("설정")
        }
        .sheet(isPresented: $viewModel.isPresentDataDownloadView) {
            DataDownloadView(of: .update)
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
            .environmentObject(ViewModel())
    }
}
