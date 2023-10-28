//
//  DownloadView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/17.
//

import SwiftUI

// MARK: - ENUM

enum DataDownloadViewType {
    case update
    case download
}

struct DataDownloadView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    @State private var isDownloading: Bool = false
    
    // MARK: - PROPERTIES
    
    let type: DataDownloadViewType
    
    let titleText: String
    let descriptionText: String
    let buttonLabel: String
    
    // MARK: - COMPUTED PROPERTIES
    
    var progressString: String {
        let downloadedImages: Int = loginViewModel.downloadedImages
        let imagesToDownload: Int = loginViewModel.imagesToDownload
        
        var progressString: String = ""
        if downloadedImages != 0 && imagesToDownload != 0 {
            if downloadedImages >= imagesToDownload {
                progressString = "\(imagesToDownload)/\(imagesToDownload)"
            } else {
                progressString = "\(downloadedImages)/\(imagesToDownload)"
            }
        }
        return progressString
    }
    
    var progressPercentage: Double {
        let downloadedImages = Double(loginViewModel.downloadedImages)
        let imagesToDownload = Double(loginViewModel.imagesToDownload)
        let progressPercentage = downloadedImages / imagesToDownload
        return progressPercentage >= 1.0 ? 1.0 : progressPercentage
    }
    
    var progressPercentageValue: String {
        return progressPercentage.isNaN ? "" : "\(Int(progressPercentage * 100.0))%"
    }
    
    // MARK: - INTILAIZER
    
    init(of type: DataDownloadViewType) {
        self.type = type
        
        switch type {
        case .update:
            titleText = "Updating..."
            descriptionText = "앱을 이용하기 위해 발로란트 상점 데이터를 최신 버전으로 업데이트해야 합니다."
            buttonLabel = "업데이트"
        case .download:
            titleText = "Downloading..."
            descriptionText = "앱을 이용하기 위해 발로란트 상점 데이터를 먼저 다운로드해야 합니다. 이 작업은 몇 분 정도 소요됩니다."
            buttonLabel = "다운로드"
        }
    }
    
    // MARK: - BODY
    
    var body: some View {
        VStack {
            
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(.title2, weight: .bold))
                        .foregroundColor(Color.primary)
                }
                .opacity(type == .download ? 1 : 0)
                .disabled(type == .download ? false : true)
                
                Spacer()
            }
            .padding()
            .opacity(loginViewModel.isLoadingDataDownloading ? 0 : 1)
            .disabled(loginViewModel.isLoadingDataDownloading)
            
            VStack(alignment: .leading) {
                Text("Data")
                    .font(.custom(Fonts.valorant, size: 50))
                Text("\(titleText)")
                    .font(.custom(Fonts.valorant, size: 35))
                
                Text("\(descriptionText)")
                    .foregroundColor(Color.secondary)
                    .padding(.top, 1)
                
                Text("\(loginViewModel.downloadingErrorText)")
                    .foregroundColor(Color.valorant)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
            
            VStack {
                HStack {
                    Text(progressPercentageValue)
                    
                    Spacer()
                    
                    Text(progressString)
                }
                .font(.subheadline)
                .foregroundColor(Color.secondary)
                
                ProgressView(value: progressPercentage)
                    .tint(Color.valorant)
                    .progressViewStyle(.linear)
                
            }
            .padding()
            
            Button {
                Task(priority: .high) {
                    switch type {
                    case .update:
                        await loginViewModel.downloadValorantData(update: true)
                    case .download:
                        await loginViewModel.downloadValorantData()
                    }
                }
            } label: {
                Group {
                    if loginViewModel.isLoadingDataDownloading {
                        ProgressView()
                    } else {
                        Text("\(buttonLabel)")
                    }
                }
                .font(.system(.title2, weight: .bold))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.valorant, in: RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal)
                .padding(.vertical, hasBezel ? 20 : 0)
            }
            .modifier(ShakeEffect(animatableData: loginViewModel.downloadButtonShakeAnimation))
            .disabled(loginViewModel.isLoadingDataDownloading)
        }
        .onDisappear {
            loginViewModel.downloadingErrorText = ""
            loginViewModel.imagesToDownload = 0
            loginViewModel.downloadedImages = 0
        }
    }
}

// MARK: - PREVIEW

struct DataDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DataDownloadView(of: .download)
                .environmentObject(LoginViewModel())
        }
    }
}
