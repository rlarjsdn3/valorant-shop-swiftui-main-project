//
//  ShopView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import SwiftUI

struct StoreView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - PROPERTIES
    
    
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            VStack(spacing: -20) {
                ForEach(viewModel.storeRotationWeaponSkins.weaponSkins, id: \.skin.uuid) { weaponSkin in
                    if let uuid = weaponSkin.skin.chromas.first?.uuid {
                        VStack {
                            loadImage(of: ImageType.weaponSkins, uuid: uuid)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 150)
                                .rotationEffect(Angle(degrees: 45))
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottomLeading) {
                            Text(weaponSkin.skin.displayName)
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
                                    Text("\(weaponSkin.price)")
                                }
                                if let rankLogoName = weaponSkin.skin.contentTierUUID?.rankLogoName {
                                    Image(rankLogoName)
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .offset(y: -5)
                        }
                        .padding()
                        .overlay {
                            if let hightlightColor = weaponSkin.skin.contentTierUUID?.hightlightColor {
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
                }
            }
            
            Text("\(viewModel.storeRotationWeaponSkinsRemainingSeconds)")
            
            Text("vp: \(viewModel.vp)")
            Text("rp: \(viewModel.rp)")
            Text("kp: \(viewModel.kp)")
            
            Button("리로드") {
                Task {
                    await viewModel.getPlayerWallet(reload: true)
                    await viewModel.getStoreRotationWeaponSkins(reload: true)
                }
            }
            
            Button("시간 되돌리기") {
                viewModel.timer?.invalidate()
                viewModel.rotatedWeaponSkinsExpiryDate = 717119999.0
            }
        }
        .background(Color(uiColor: UIColor.secondarySystemBackground))
    }
}

// MARK: - PREVIEW

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
            .environmentObject(ViewModel())
    }
}
