//
//  SkinsView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI

struct SkinsMarketView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            VStack(spacing: -5) {
                HStack {
                    Text("\(viewModel.storeSkinsRemainingTime)")
                    
                    Spacer()
                    
                    Image("VP")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .offset(y: 1)
                    
                    Text("\(viewModel.vp)")
                }
                .fontWeight(.bold)
                .padding(.horizontal)
                
                VStack(spacing: -16) {
                    ForEach(viewModel.storeSkins.skinInfos) { skinInfo in
                        NavigationLink {
                            Text("ItemDetail View")
                        } label: {
                            VStack {
                                if let uuid = skinInfo.skin.chromas.first?.uuid {
                                    loadImage(of: ImageType.weaponSkins, uuid: uuid)
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
                            .background(Color(uiColor: UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 15))
                            .clipped()
                            .padding()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.secondarySystemBackground))
        .scrollIndicators(.hidden)
    }
}

// MARK: - PREVIEW

struct SkinsView_Previews: PreviewProvider {
    static var previews: some View {
        SkinsMarketView()
            .environmentObject(ViewModel())
    }
}
