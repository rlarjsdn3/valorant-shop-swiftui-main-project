//
//  CollectionView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/13.
//

import SwiftUI

// MARK: - ENUM

enum CollectionTabType: CaseIterable {
    case collection
    case owned
    
    var tabName: String {
        switch self {
        case .collection:
            return "컬렉션"
        case .owned:
            return "내스킨"
        }
    }
}

// MARK: - VIEW

struct CollectionView: View {
    
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
                    ForEach(CollectionTabType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                appViewModel.selectedCollectionTab = type
                            }
                            hapticManager.play(.rigid)
                        } label: {
                            Text(type.tabName)
                                .font(.title)
                                .fontWeight(appViewModel.selectedCollectionTab == type ? .bold : .light)
                                .foregroundColor(Color.primary)
                                .overlay {
                                    if appViewModel.selectedCollectionTab == type {
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
                        withAnimation(.spring()) {
                            resourceViewModel.isAscendingOrder.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .resizable()
                            .scaledToFit()
                            .font(.title)
                            .foregroundColor(Color.primary)
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(resourceViewModel.isAscendingOrder ? 0 : 180))
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
                
                switch appViewModel.selectedCollectionTab {
                case .collection:
                    AllSkinsListView()
                case .owned:
                    OwnedSkinsListView()
                }
            }
        }
    }
}

// MARK: - PREVIEW

struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView()
            .environmentObject(AppViewModel())
            .environmentObject(ResourceViewModel())
    }
}
