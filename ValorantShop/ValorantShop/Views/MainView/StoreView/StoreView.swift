//
//  ShopView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import SwiftUI

// MARK: - ENUM

enum StoreTabType: CaseIterable {
    case skin
    case bundle
    case bonus
    
    var tabName: String {
        switch self {
        case .skin:
            return "스킨"
        case .bundle:
            return "번들"
        case .bonus:
            return "야시장"
        }
    }
}

struct StoreView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    @Namespace var namespace: Namespace.ID
    
    // MARK: - BODY
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                ForEach(StoreTabType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedStoreTab = type
                        }
                    } label: {
                        Text(type.tabName)
                            .font(.title)
                            .fontWeight(viewModel.selectedStoreTab == type ? .bold : .light)
                            .foregroundColor(Color.primary)
                            .overlay {
                                if viewModel.selectedStoreTab == type {
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(height: 1.5)
                                        .offset(y: 18)
                                        .matchedGeometryEffect(id: "Tab", in: namespace)
                                }
                            }
                    }
                }
                
                Spacer()
                
                Button {
                    Task {
                        switch viewModel.selectedStoreTab {
                        case .skin:
                            await viewModel.reloadPlayerData(of: .skin)
                        case .bundle:
                            print("d")
                        case .bonus:
                            print("d")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .font(.title)
                        .foregroundColor(Color.primary)
                        .frame(width: 30, height: 30)
                        .offset(y: -3)
                        .rotationEffect(Angle(degrees: viewModel.refreshButtonRotateAnimation ? 360 : 0))
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                Color.systemBackground
                    .ignoresSafeArea()
            )
            .overlay(alignment: .bottom) {
                Divider()
            }
            
            ScrollView {
                VStack(spacing: -5) {
                    HStack {
                        Text("\(viewModel.storeRotationWeaponSkinsRemainingSeconds)")
                        
                        Spacer()
                        
                        Image("VP")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .offset(y: 1)
                        
                        Text("\(viewModel.vp)")
                    }
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    
                    VStack(spacing: -16) {
                        ForEach(viewModel.storeRotationWeaponSkins.weaponSkins, id: \.skin.uuid) { weaponSkin in
                            VStack {
                                if let uuid = weaponSkin.skin.chromas.first?.uuid {
                                    loadImage(of: ImageType.weaponSkins, uuid: uuid)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 150)
                                        .rotationEffect(Angle(degrees: 45))
                                }
                            }
                            .frame(height: 150)
                            .overlay(alignment: .bottomLeading) {
                                Text(weaponSkin.skin.displayName)
                                    .font(.headline)
                                    .frame(maxWidth: screenSize.width / 3.0, alignment: .leading)
                                    .offset(y: 5)
                            }
                            .overlay(alignment: .topTrailing) {
                                HStack {
                                    HStack(spacing: 5) {
                                        Image("VP")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .offset(y: 1)
                                        Text("\(weaponSkin.price)")
                                    }
                                    if let rankLogoName = weaponSkin.skin.contentTierUUID?.rankLogoName {
                                        Image(rankLogoName)
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                .offset(y: -5)
                            }
                            .padding()
                            .overlay {
                                if let hightlightColor = weaponSkin.skin.contentTierUUID?.hightlightColor {
                                    RoundedRectangle(cornerRadius: 15)
                                        .strokeBorder(
                                            hightlightColor,
                                            style: .init(lineWidth: 1),
                                            antialiased: true
                                        )
                                }
                            }
                            .background(Color(uiColor: UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 15))
                            .clipped()
                            .padding()
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
}

// MARK: - PREVIEW

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
            .environmentObject(ViewModel())
    }
}
