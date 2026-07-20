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
	static var isRunningForPreviews: Bool {
		ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
	}
	
	class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
		
		static var orientationLock = UIInterfaceOrientationMask.all //By default you want all your views to rotate freely
		
		func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
			guard !Napha_Training_AppApp.isRunningForPreviews else { return true }
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
			if Napha_Training_AppApp.isRunningForPreviews {
				ContentView()
			} else {
				SplashScreen()
			}
		}
	}
}
