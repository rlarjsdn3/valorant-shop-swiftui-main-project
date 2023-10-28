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
    //case bonus
    
    var tabName: String {
        switch self {
        case .skin:
            return "스킨"
        case .bundle:
            return "번들"
        //case .bonus:
        //    return "야시장"
        }
    }
}

// MARK: - VIEW

struct StoreView: View {
    
    // MARK: - PROPERTIES
    
    let hapticManager = HapticManager.shared
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    
    @Namespace var namespace: Namespace.ID
    
    // MARK: - BODY
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 18) {
                    ForEach(StoreTabType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                appViewModel.selectedStoreTab = type
                            }
                            hapticManager.play(.rigid)
                        } label: {
                            Text(type.tabName)
                                .font(.title)
                                .fontWeight(appViewModel.selectedStoreTab == type ? .bold : .light)
                                .foregroundColor(Color.primary)
                                .overlay {
                                    if appViewModel.selectedStoreTab == type {
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
                            switch appViewModel.selectedStoreTab {
                            case .skin:
                                await resourceViewModel.reloadPlayerData(of: .skin)
                            case .bundle:
                                await resourceViewModel.reloadPlayerData(of: .bundle)
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
                            .rotationEffect(Angle(degrees: resourceViewModel.refreshButtonRotateAnimation ? 360 : 0))
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
                .padding(.bottom, 15)
                .padding(.horizontal)
                .background(
                    Color.systemBackground
                        .ignoresSafeArea()
                )
                .overlay(alignment: .bottom) {
                    Divider()
                }
                
                switch appViewModel.selectedStoreTab {
                case .skin:
                    SkinListView()
                case .bundle:
                    BundleListView()
                //case .bonus:
                //    BonusListView()
                }
            }
        }
    }
}

// MARK: - PREVIEW

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
            .environmentObject(ResourceViewModel())
    }
}
