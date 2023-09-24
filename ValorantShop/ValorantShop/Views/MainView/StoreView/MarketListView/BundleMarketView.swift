//
//  BundleView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI

struct BundleMarketView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - PROPERTIES
    
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.storeBundles, id: \.uuid) { bundle in
                let url = URL(string: "https://media.valorant-api.com/bundles/\(bundle.uuid)/displayicon.png")
                AsyncImage(
                    url: url,
                    transaction: .init()
                ) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure(_):
                        EmptyView()
                    case .empty:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
                
                ForEach(bundle.skinInfos) { skinInfo in
                    Text("\(skinInfo.skin.displayName)")
                    Text("\(skinInfo.price.basePrice)")
                    Text("\(skinInfo.price.discountedPrice ?? -999)")
                }
            }
        }
    }
}

// MARK: - PREBIEW

struct BundleView_Previews: PreviewProvider {
    static var previews: some View {
        BundleMarketView()
            .environmentObject(ViewModel())
    }
}
