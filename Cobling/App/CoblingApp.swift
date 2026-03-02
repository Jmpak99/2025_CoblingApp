//
//  CoblingApp.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//


import SwiftUI

@main
struct CoblingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var appState = AppState()
    @StateObject var tabBarViewModel = TabBarViewModel()
    @StateObject var authViewModel = AuthViewModel()

    init() {
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
                .environmentObject(tabBarViewModel)
                .environmentObject(authViewModel)
        }
    }
}


