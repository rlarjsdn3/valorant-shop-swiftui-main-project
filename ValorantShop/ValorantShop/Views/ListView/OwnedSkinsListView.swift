//
//  OwnedSkinsListView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/10/05.
//

import SwiftUI

struct OwnedSkinsListView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.ownedWeaponSkins) { skinInfo in
                    SkinCell(skinInfo)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.secondarySystemBackground))
        .scrollIndicators(.hidden)
    }
}

struct OwnedSkinsListView_Previews: PreviewProvider {
    static var previews: some View {
        OwnedSkinsListView()
    }
}
