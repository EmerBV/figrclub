//
//  NavigationView+Extensions.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 31/7/25.
//

import SwiftUI

extension NavigationView {
    func figrNavigationStyle() -> some View {
        self
            .navigationBarTitleDisplayMode(.large)
            .accentColor(.figrPrimary)
    }
}
