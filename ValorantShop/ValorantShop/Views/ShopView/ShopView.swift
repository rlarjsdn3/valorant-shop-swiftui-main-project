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
    
    // MARK: - BODY
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.storeRotationWeaponSkins, id: \.skin.uuid) { weaponSkin in
                    VStack {
                        loadImage(of: ImageType.weaponSkins, uuid: weaponSkin.skin.uuid)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 150)
                        Text(weaponSkin.skin.displayName)
                        Text("\(weaponSkin.price)")
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
