//
//  AppDelegate.swift
//  Cobling
//
//  Created by 박종민 on 8/8/25.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Preview에서는 Firebase/푸시 초기화 생략
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }

        // Firebase 초기화
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // 알림 델리게이트 연결
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // 알림 권한 요청
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, err in
            print("🔔 Notification permission granted:", granted,
                  "error:", err?.localizedDescription ?? "nil")

            // 권한 요청 완료 후 메인 스레드에서 APNs 등록
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        // 여기서 바로 registerForRemoteNotifications()를 호출하던 코드는 제거
        // 이유:
        // 권한 요청 콜백 안에서 등록하도록 하면 흐름이 더 명확하고 안전합니다.

        return true
    }
    
    // APNs 디바이스 토큰 등록 성공
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        // Firebase Messaging에 APNs 토큰 전달
        Messaging.messaging().apnsToken = deviceToken
        print("✅ APNs device token registered")

        // APNs token 등록 후 FCM token 재요청
        // 이유:
        // "No APNS token specified before fetching FCM Token" 문제 방지
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ APNs 등록 후 FCM token 재요청 실패:", error.localizedDescription)
                return
            }

            guard let token = token, !token.isEmpty else {
                print("❌ APNs 등록 후 FCM token이 비어있음")
                return
            }

            print("✅ APNs 등록 후 FCM Token:", token)

            // AuthViewModel로 전달
            NotificationCenter.default.post(name: .didReceiveFcmToken, object: token)
        }
    }

    // APNs 디바이스 토큰 등록 실패
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications:", error.localizedDescription)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    /// 앱이 켜져있을 때(포그라운드)도 배너/사운드 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    /// 알림 탭했을 때(필요하면 나중에 딥링크 처리)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // 여기서 response.notification.request.content.userInfo 로 라우팅 처리 가능
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {

    /// FCM 토큰 수신(이게 찍히면 푸시 준비 완료)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 FCM Token:", fcmToken ?? "nil")

        // AuthViewModel로 FCM token 전달
        guard let fcmToken = fcmToken, !fcmToken.isEmpty else { return }
        NotificationCenter.default.post(name: .didReceiveFcmToken, object: fcmToken)
    }
}
