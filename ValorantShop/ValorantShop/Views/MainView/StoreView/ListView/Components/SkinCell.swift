//
//  SkinCell.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/25.
//

import SwiftUI

struct SkinCell: View {
    
    var skinInfo: SkinInfo
    
    init(_ skinInfo: SkinInfo) {
        self.skinInfo = skinInfo
    }
    
    var body: some View {
        NavigationLink {
            SkinDetailView(skinInfo)
                .navigationBarBackButtonHidden()
        } label: {
            VStack {
                if let uuid = skinInfo.skin.chromas.first?.uuid {
                    kingFisherImage(of: ImageType.weaponSkins, uuid: uuid)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .rotationEffect(Angle(degrees: 45))
                }
            }
            .frame(height: 150)
            .overlay(alignment: .bottomLeading) {
                Text("\(skinInfo.skin.displayName)")
                    .font(.headline)
                    .frame(maxWidth: screenSize.width / 3.0, alignment: .leading)
                    .offset(y: 5)
            }
            .overlay(alignment: .topTrailing) {
                HStack {
                    HStack(spacing: 5) {
                        Image("VP")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .offset(y: 1)
                        Text("\(skinInfo.price.basePrice)")
                    }
                    if let rankLogoName = skinInfo.skin.contentTier?.rankLogoName {
                        Image(rankLogoName)
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }
                .offset(y: -5)
            }
            .padding()
            .overlay {
                if let hightlightColor = skinInfo.skin.contentTier?.hightlightColor {
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(
                            hightlightColor,
                            style: .init(lineWidth: 1),
                            antialiased: true
                        )
                }
            }
            .background(Color.systemBackground, in: RoundedRectangle(cornerRadius: 15))
            .clipped()
        }
        .buttonStyle(.plain)
    }
    
}
