//
//  BundleView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI
//import Combine

struct BundleMarketView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - PROPERTIES
    
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.storeBundles, id: \.uuid) { bundle in
                    VStack(spacing: 1) {
                        
                        VStack(spacing: 11) {
                            HStack {
                                Text("\(viewModel.storeSkinsRemainingTime)") // ❗️임시 코드
                                
                                Spacer()
                            }
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            
                            AsyncImage(
                                url: URL(string: ResourceURL.displayIcon(of: ImageType.bundles, uuid: bundle.uuid)),
                                transaction: .init()
                            ) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(15)
                                case .failure(_):
                                    EmptyView()
                                case .empty:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                HStack {
                                    HStack(spacing: 5) {
                                        Image("VP")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        Text("\(bundle.bundleDiscountedPrice)")
                                            .foregroundColor(Color.primary)
                                    }
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal, 10)
                                .background(Color.systemBackground, in: Capsule())
                                .padding(5)
                            }
                            .clipped()
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: -16) {
                            ForEach(bundle.skinInfos) { skinInfo in
                                SkinCell(skinInfo)
                            }
                        }
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

// MARK: - PREBIEW

struct BundleView_Previews: PreviewProvider {
    static var previews: some View {
        BundleMarketView()
            .environmentObject(ViewModel())
    }
}
