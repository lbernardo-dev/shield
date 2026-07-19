import SwiftUI
import Combine

@MainActor
final class AppSessionCoordinator: ObservableObject {
    private let autoLockTimestampKey = "shield.autoLock.backgroundTimestamp"
    private static let userActivityTimestampKey = "shield.autoLock.lastActivity"
    private static var lastActivityWrite: TimeInterval = 0

    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: "shield.onboarded")
        }
    }

    @Published var isAuthenticated: Bool = false {
        didSet {
            if isAuthenticated {
                Self.markUserActivity(force: true)
            }
        }
    }

    private var inactivityCheckCancellable: AnyCancellable?
    private var currentScenePhase: ScenePhase = .active
    private let bypassAutoLockForAutomation: Bool

    init(userDefaults: UserDefaults = .standard) {
        bypassAutoLockForAutomation = ProcessInfo.processInfo.arguments.contains("-aso-screenshots")
        isOnboarded = userDefaults.bool(forKey: "shield.onboarded")

        if userDefaults.object(forKey: "shield.autoLock") == nil {
            userDefaults.set(1, forKey: "shield.autoLock")
        }

        Self.markUserActivity(force: true)
        startInactivityMonitoring()
    }

    static func markUserActivity(force: Bool = false) {
        let now = Date().timeIntervalSince1970
        if !force && now - lastActivityWrite < 1.0 {
            return
        }

        lastActivityWrite = now
        UserDefaults.standard.set(now, forKey: userActivityTimestampKey)
    }

    func completeSuccessfulUnlock() {
        isAuthenticated = true
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: autoLockTimestampKey)
        Self.markUserActivity(force: true)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        currentScenePhase = phase

        switch phase {
        case .active:
            applyAutoLockIfNeededOnResume()
            Self.markUserActivity(force: true)
        case .background:
            markBackgroundTimestampAndLockIfImmediate()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func markBackgroundTimestampAndLockIfImmediate() {
        guard !bypassAutoLockForAutomation else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: autoLockTimestampKey)

        guard isOnboarded, isAuthenticated else { return }
        if autoLockDelaySeconds == 0 {
            isAuthenticated = false
        }
    }

    private func applyAutoLockIfNeededOnResume() {
        guard !bypassAutoLockForAutomation else {
            Self.markUserActivity(force: true)
            return
        }
        guard isOnboarded, isAuthenticated else { return }
        guard let delay = autoLockDelaySeconds else { return }
        guard delay > 0 else {
            Self.markUserActivity(force: true)
            return
        }

        let backgroundTimestamp = UserDefaults.standard.double(forKey: autoLockTimestampKey)
        guard backgroundTimestamp > 0 else { return }

        let elapsed = Date().timeIntervalSince1970 - backgroundTimestamp
        if elapsed >= delay {
            isAuthenticated = false
        } else {
            Self.markUserActivity(force: true)
        }
    }

    private var autoLockDelaySeconds: TimeInterval? {
        let idx = UserDefaults.standard.integer(forKey: "shield.autoLock")
        switch idx {
        case 0: return 0
        case 1: return 60
        case 2: return 5 * 60
        case 3: return 15 * 60
        case 4: return nil
        default: return 0
        }
    }

    private func startInactivityMonitoring() {
        inactivityCheckCancellable = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.applyForegroundInactivityLockIfNeeded()
            }
    }

    private func applyForegroundInactivityLockIfNeeded() {
        guard !bypassAutoLockForAutomation else { return }
        guard currentScenePhase == .active else { return }
        guard isOnboarded, isAuthenticated else { return }
        guard let delay = autoLockDelaySeconds else { return }
        guard delay > 0 else { return }

        let lastActivity = UserDefaults.standard.double(forKey: Self.userActivityTimestampKey)
        guard lastActivity > 0 else { return }

        let elapsed = Date().timeIntervalSince1970 - lastActivity
        if elapsed >= delay {
            isAuthenticated = false
        }
    }
}
