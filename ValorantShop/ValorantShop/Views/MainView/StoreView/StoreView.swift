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
        NavigationStack {
            List {
                ForEach(viewModel.storeRotationWeaponSkins.weaponSkins, id: \.skin.uuid) { weaponSkin in
                    VStack {
                        if let uuid = weaponSkin.skin.chromas.first?.uuid {
                            loadImage(of: ImageType.weaponSkins, uuid: uuid)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 150)
                        }
                        Text(weaponSkin.skin.displayName)
                        Text("\(weaponSkin.price)")
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
                    viewModel.rotatedWeaponSkinsExpiryDate = 717119999.0
                }
            }
        }
    }
}

// MARK: - PREVIEW

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
            .environmentObject(ViewModel())
    }
}
