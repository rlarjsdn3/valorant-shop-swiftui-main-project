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
                }
                .fontWeight(.bold)
                .padding(.horizontal)
                
                VStack(spacing: -16) {
                    ForEach(viewModel.storeSkins.skinInfos) { skinInfo in
                        SkinCell(skinInfo)
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
