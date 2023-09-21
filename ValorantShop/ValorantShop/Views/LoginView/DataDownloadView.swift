//
//  DownloadView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/17.
//

import SwiftUI

struct DataDownloadView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - BODY
    
    var body: some View {
        VStack {
            ProgressView(value: Float(viewModel.totalDownloadedImageCount) / Float(viewModel.totalImageCountToDownload))
                .progressViewStyle(.linear)
            
            Text("\(viewModel.totalDownloadedImageCount) / \(viewModel.totalImageCountToDownload)")
                .font(.title)
            
            Button("다운로드 시작") {
                Task(priority: .high) {
                    await viewModel.downloadValorantData(reload: true)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - PREVIEW

struct DataDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        DataDownloadView()
            .environmentObject(ViewModel())
    }
}
