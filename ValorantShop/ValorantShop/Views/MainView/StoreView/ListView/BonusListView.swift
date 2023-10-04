//
//  BonusView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI

struct BonusListView: View {
    var body: some View {
        Text("NightMarket View")
            .font(.largeTitle)
            .fontWeight(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BonusStoreView_Previews: PreviewProvider {
    static var previews: some View {
        BonusListView()
    }
}
