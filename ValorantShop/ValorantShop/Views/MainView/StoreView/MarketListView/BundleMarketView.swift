//
//  BundleView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI
import Shimmer

struct BundleMarketView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - PROPERTIES
    
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            VStack(spacing: 45) {
                ForEach(Array(zip(viewModel.storeBundles.indices, viewModel.storeBundles)), id: \.0) { index, bundle in
                    VStack(spacing: 20) {
                        
                        VStack(spacing: 11) {
                            HStack {
                                Text("\(viewModel.storeBundlesReminingTime[index])") // ❗️임시 코드
                                
                                Spacer()
                            }
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            
                            AsyncImage(
                                url: URL(string: ResourceURL.displayIcon(of: ImageType.bundles, uuid: bundle.uuid)),
                                transaction: .init(animation: .spring())
                            ) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .frame(height: 180)
                                        .cornerRadius(15)
                                case .failure(_):
                                    Color.systemBackground
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(15)
                                        .shimmering()
                                case .empty:
                                    Color.systemBackground
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(15)
                                        .shimmering()
                                @unknown default:
                                    Color.systemBackground
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(15)
                                        .shimmering()
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
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 20) {
                            ForEach(bundle.skinInfos) { skinInfo in
                                SkinCell(skinInfo)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .background(Color.secondarySystemBackground)
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
