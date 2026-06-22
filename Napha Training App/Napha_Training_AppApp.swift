//
//  Napha_Training_AppApp.swift
//  Napha Training App
//
//  Created by Kui Jun on 24/5/24.
//

import SwiftUI
import UserNotifications

@main

struct Napha_Training_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
            
        static var orientationLock = UIInterfaceOrientationMask.all //By default you want all your views to rotate freely

        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            UNUserNotificationCenter.current().delegate = self
            NotificationCoordinator.configureCategories()
            // Request permission proactively so notifications can be scheduled later.
            NotificationCoordinator.requestAuthorization()
            return true
        }

        func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            return AppDelegate.orientationLock
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            NotificationCoordinator.handle(response: response)
            completionHandler()
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner, .sound])
        }
    }
    var body: some Scene {
        WindowGroup {
            SplashScreen()
        }
    }
}
