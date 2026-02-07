import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Notification Delegate (Foreground)

class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

// MARK: - App Entry Point

@main
struct ZenPlanerApp: App {
    @State private var themeManager = ThemeManager.shared
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    private let notificationDelegate = AppNotificationDelegate()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    DayView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environment(\.colorTheme, themeManager.currentTheme)
            .preferredColorScheme(themeManager.appearanceMode.colorScheme)
            .onAppear {
                UNUserNotificationCenter.current().delegate = notificationDelegate
            }
        }
        .modelContainer(for: [ZenTask.self, DailyReflection.self])
    }
}
