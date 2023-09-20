//
//  ShopView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import SwiftUI

struct ShopView: View {
    
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
                
                Text("\(viewModel.rotationWeaponSkinsRemainingSeconds.description)")
                
                Button("리로드") {
                    Task {
                        await viewModel.fetchStoreRotationWeaponSkins()
                    }
                }
            }
        }
    }
}

// MARK: - PREVIEW

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
            .environmentObject(ViewModel())
    }
}
