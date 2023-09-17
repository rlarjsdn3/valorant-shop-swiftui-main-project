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
                ForEach(viewModel.storeRotationWeaponSkins.weaponSkins, id: \.skin.uuid) { weaponSkin in
                    VStack {
                        loadImage(of: ImageType.weaponSkins, uuid: weaponSkin.skin.uuid)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 150)
                        Text(weaponSkin.skin.displayName)
                        Text("\(weaponSkin.price)")
                    }
                }
                
                Text("\(viewModel.rotationWeaponSkinsRemainingSeconds)")
            }
        }
        .onAppear {
            for family: String in UIFont.familyNames {
                            print(family)
                            for names : String in UIFont.fontNames(forFamilyName: family){
                                print("=== \(names)")
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
