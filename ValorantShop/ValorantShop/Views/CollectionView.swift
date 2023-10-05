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

// MARK: - VIEW=

struct CollectionView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    @Namespace var namespace: Namespace.ID
    
    // MARK: - BODY
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 18) {
                    ForEach(CollectionTabType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedCollectionTab = type
                            }
                        } label: {
                            Text(type.tabName)
                                .font(.title)
                                .fontWeight(viewModel.selectedCollectionTab == type ? .bold : .light)
                                .foregroundColor(Color.primary)
                                .overlay {
                                    if viewModel.selectedCollectionTab == type {
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
                
                switch viewModel.selectedCollectionTab {
                case .collection:
                    SkinListView()
                case .owned:
                    BundleListView()
                }
            }
        }
    }
}

struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView()
            .environmentObject(ViewModel())
    }
}
