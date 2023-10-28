//
//  AppViewModel.swift
//  ValorantShop
//
//  Created by 김건우 on 10/29/23.
//

import Foundation

// MARK: - DELEGATE

protocol AppViewModelDelegate: NSObject {
    func resetSelectedTab()
}

// MARK: - VIEW MODEL

final class AppViewModel: NSObject, ObservableObject {
    
    // MARK: - WRAPPER PROPERTIES
    
    // For SelectedTab
    @Published var selectedCustomTab: CustomTabType = .shop
    @Published var selectedStoreTab: StoreTabType = .skin
    @Published var selectedCollectionTab: CollectionTabType = .collection
 
}

// MARK: - EXTESNIONS

extension AppViewModel: AppViewModelDelegate {
    
    func resetSelectedTab() {
        self.selectedCustomTab = .shop
        self.selectedStoreTab = .skin
        self.selectedCollectionTab = .collection
    }
    
}


