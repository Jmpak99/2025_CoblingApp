//
//  AppDelegate.swift
//  Cobling
//
//  Created by 박종민 on 8/8/25.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        return true
    }
}
