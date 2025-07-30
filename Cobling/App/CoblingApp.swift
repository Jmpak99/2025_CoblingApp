//
//  CoblingApp.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//


import SwiftUI

@main
struct CoblingApp: App {
    @StateObject var appState = AppState()
    @StateObject var tabBarViewModel = TabBarViewModel()

    init() {
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
                .environmentObject(tabBarViewModel)
        }
    }
}
