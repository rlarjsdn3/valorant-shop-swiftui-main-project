//
//  SkinDetailView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/26.
//

import SwiftUI

struct SkinDetailView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - PROPERTIES
    
    var skinInfo: SkinInfo
    
    // MARK: - INITALIZER
    
    init(_ skinInfo: SkinInfo) {
        self.skinInfo = skinInfo
    }
    
    // MARK: - BODY
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(Color.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 18.8)
            .padding(.horizontal)
            .overlay {
                Text("스킨 세부 정보")
                    .font(.system(.title2, weight: .semibold))
            }
            .overlay(alignment: .bottom) {
                Divider()
            }
            .background(
                Color.systemBackground
                    .ignoresSafeArea()
            )
            
            ScrollView {
                if let uuid = skinInfo.skin.chromas.first?.uuid {
                    loadImage(of: .weaponSkins, uuid: uuid)
                        .resizable()
                        .scaledToFit()
                }
            }
            .background(Color.secondarySystemBackground)
            .scrollIndicators(.never)
        }
    }
}

// MARK: - PREVIEW

struct SkinDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SkinDetailView(PreviewsData.skinInfo)
    }
}
