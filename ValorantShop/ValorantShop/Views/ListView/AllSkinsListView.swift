//
//  AllSkinsView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/10/05.
//

import SwiftUI

struct AllSkinsListView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    
    // MARK: - COMPUTED PROPERTIES
    
    var sortedCollections: [SkinInfo] {
        // 정렬된 스킨 데이터를 저장하는 배열 선언하기
        var sortedCollections: [SkinInfo] = []
        // 정렬 기준 확인하기
        if resourceViewModel.isAscendingOrder {
            sortedCollections = resourceViewModel.collections.sorted(by: { $0.skin.displayName < $1.skin.displayName })
        } else {
            sortedCollections = resourceViewModel.collections.sorted(by: { $0.skin.displayName > $1.skin.displayName })
        }
        // 결과 반환하기
        return sortedCollections
    }
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(sortedCollections) { skinInfo in
                    SkinCell(skinInfo)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: UIColor.secondarySystemBackground))
    }
}

struct AllSkinsListView_Previews: PreviewProvider {
    static var previews: some View {
        AllSkinsListView()
            .environmentObject(ResourceViewModel())
    }
}
