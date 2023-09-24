//
//  BundleView.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/23.
//

import SwiftUI

struct BundleMarketView: View {
    var body: some View {
        Text("BundleMarket View")
            .font(.largeTitle)
            .fontWeight(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BundleView_Previews: PreviewProvider {
    static var previews: some View {
        BundleMarketView()
    }
}
