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
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - PROPERTIES
    
    let type: DataDownloadViewType
    
    let titleText: String
    let descriptionText: String
    let buttonLabel: String
    
    // MARK: - COMPUTED PROPERTIES
    
    var progressString: String {
        let downloadedImages: Int = viewModel.imagesDownloadedCount
        let imagesToDownload: Int = viewModel.totalImagesToDownload
        
        var progressString: String = ""
        if downloadedImages != 0 && imagesToDownload != 0 {
            progressString = "\(downloadedImages)/\(imagesToDownload)"
        }
        return progressString
    }
    
    var progressPercentage: Double {
        let downloadedImages = Double(viewModel.imagesDownloadedCount)
        let imagesToDownload = Double(viewModel.totalImagesToDownload)
        let progressPercentage = (downloadedImages / imagesToDownload) * 100.0
        return progressPercentage
    }
    
    var progressPercentageValue: String {
        return progressPercentage.isNaN ? "" : "\(String(format: "%.1f", progressPercentage))%"
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
        // For Test
        VStack {
            
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(.title2, weight: .bold))
                        .foregroundColor(Color.primary)
                }
                
                Spacer()
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Data")
                    .font(.custom(Fonts.valorantFont, size: 50))
                Text("\(titleText)")
                    .font(.custom(Fonts.valorantFont, size: 35))
                
                Text("\(descriptionText)")
                    .foregroundColor(Color.secondary)
                    .padding(.top, 1)
                
                Text("\(viewModel.downloadingErrorText)")
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
                Task {
                    await viewModel.downloadValorantData()
                }
            } label: {
                Group {
                    if viewModel.isLoadingDataDownloading {
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
            .modifier(ShakeEffect(animatableData: viewModel.downloadButtonShakeAnimation))
        }
        .onDisappear {
            viewModel.downloadingErrorText = ""
            viewModel.totalImagesToDownload = 0
            viewModel.imagesDownloadedCount = 0
        }
    }
}

// MARK: - PREVIEW

struct DataDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DataDownloadView(of: .download)
                .environmentObject(ViewModel())
        }
    }
}
