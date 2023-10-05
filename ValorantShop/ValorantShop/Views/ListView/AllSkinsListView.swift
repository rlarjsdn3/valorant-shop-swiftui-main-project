//
//  AllSkinsView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/10/05.
//

import SwiftUI

struct AllSkinsListView: View {
    
    // MARK: - WRAPPER PROPERTIES
    
    @EnvironmentObject var viewModel: ViewModel
    
    // MARK: - BODY
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.collections) { skinInfo in
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
            .environmentObject(ViewModel())
    }
}
