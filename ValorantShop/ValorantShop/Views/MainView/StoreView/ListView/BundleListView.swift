//
//  BundleView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI
import Shimmer

struct BundleListView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    
    // MARK: - PROPERTIES
    
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            VStack(spacing: 45) {
                ForEach(Array(zip(resourceViewModel.storeBundles.indices, resourceViewModel.storeBundles)), id: \.0) { index, bundle in
                    VStack(spacing: 20) {
                        
                        VStack(spacing: 11) {
                            HStack {
                                Text("\(resourceViewModel.storeBundlesReminingTime[index])")
                                
                                Spacer()
                            }
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            
                            kingFisherImage(of: ImageType.bundles, uuid: bundle.uuid)
                                .resizable()
                                .frame(height: 180)
                                .cornerRadius(15)
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

struct BundleListView_Previews: PreviewProvider {
    static var previews: some View {
        BundleListView()
            .environmentObject(ResourceViewModel())
    }
}
