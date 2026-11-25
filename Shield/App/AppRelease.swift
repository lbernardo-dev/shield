import StoreKit
import SwiftUI

enum AppRelease {
    static let installedVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    private static let seenVersionKey = "shield.release.seenVersion"

    static func hasUnseenNotes(installed: String? = installedVersion, defaults: UserDefaults = .standard) -> Bool {
        guard let installed, let seenVersion = defaults.string(forKey: seenVersionKey) else { return false }
        return !highlights(for: installed).isEmpty && isNewer(installed, than: seenVersion)
    }

    static func establishBaseline(
        previousVersion: String?,
        installed: String? = installedVersion,
        defaults: UserDefaults = .standard
    ) {
        guard defaults.string(forKey: seenVersionKey) == nil else { return }
        // Builds predating engagement metadata still set the install marker.
        let firstVersion = defaults.bool(forKey: AppSessionCoordinator.installedKey) ? "0" : installed
        defaults.set(previousVersion ?? firstVersion, forKey: seenVersionKey)
    }

    static func markNotesSeen(installed: String? = installedVersion, defaults: UserDefaults = .standard) {
        defaults.set(installed, forKey: seenVersionKey)
    }

    // Add a version and its localized highlights here when preparing a release.
    static func highlights(for version: String? = installedVersion) -> [Highlight] {
        switch version {
        case "1.1.7":
            [
                Highlight(id: "release_117_access", icon: "clock"),
                Highlight(id: "release_117_recovery", icon: "tray"),
                Highlight(id: "release_117_review", icon: "checkmark.shield")
            ]
        case "1.1.8":
            [
                Highlight(id: "release_118_feedback", icon: "bubble.left.and.bubble.right"),
                Highlight(id: "release_118_updates", icon: "arrow.up.forward.app"),
                Highlight(id: "release_118_reviews", icon: "star.bubble")
            ]
        default:
            []
        }
    }

    struct Highlight: Identifiable {
        let id: String
        let icon: String

        var title: String { LanguageManager.shared.settings("\(id)_title") }
        var detail: String { LanguageManager.shared.settings("\(id)_detail") }
    }

    static func isNewer(_ candidate: String, than installed: String) -> Bool {
        guard let candidate = versionComponents(candidate),
              let installed = versionComponents(installed) else { return false }
        return installed.lexicographicallyPrecedes(candidate)
    }

    static func isCompatible(minimum: String, device: String) -> Bool {
        guard let minimum = versionComponents(minimum),
              let device = versionComponents(device) else { return false }
        return !device.lexicographicallyPrecedes(minimum)
    }

    private static func versionComponents(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        let numbers = parts.compactMap { part -> Int? in
            guard part.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
            return Int(part)
        }
        guard numbers.count == parts.count else { return nil }
        return numbers + Array(repeating: 0, count: 3 - numbers.count)
    }
}

enum AppStoreUpdate {
    struct Listing: Decodable {
        let bundleId: String
        let version: String
        let minimumOsVersion: String

        func isUpdate(bundleID: String, installed: String, deviceVersion: String) -> Bool {
            bundleId == bundleID
                && AppRelease.isNewer(version, than: installed)
                && AppRelease.isCompatible(minimum: minimumOsVersion, device: deviceVersion)
        }
    }

    private struct LookupResponse: Decodable {
        let results: [Listing]
    }

    static let pageURL = URL(string: "https://apps.apple.com/app/id\(AppStoreConfiguration.appID)")!

    static func availableVersion() async throws -> String? {
        guard let installed = AppRelease.installedVersion,
              let bundleID = Bundle.main.bundleIdentifier else { return nil }
        let device = ProcessInfo.processInfo.operatingSystemVersion
        let deviceVersion = "\(device.majorVersion).\(device.minorVersion).\(device.patchVersion)"
        let region: Locale.Region?
        if let storefront = await Storefront.current {
            // StoreKit supplies ISO alpha-3 codes. Foundation normalizes them
            // to the alpha-2 codes expected by the lookup endpoint.
            region = Locale(identifier: "und_\(storefront.countryCode)").region
        } else {
            region = Locale.current.region
        }
        guard let country = region?.identifier.lowercased(), country.utf8.count == 2 else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        components.queryItems = [
            URLQueryItem(name: "id", value: AppStoreConfiguration.appID),
            URLQueryItem(name: "country", value: country)
        ]
        guard let url = components.url else { return nil }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let lookup = try JSONDecoder().decode(LookupResponse.self, from: data)
        return lookup.results.first {
            $0.isUpdate(bundleID: bundleID, installed: installed, deviceVersion: deviceVersion)
        }?.version
    }

    static func canRemind(about version: String, now: Date = .now) -> Bool {
        let defaults = UserDefaults.standard
        let key = "shield.release.updateReminded.\(version)"
        guard let lastReminder = defaults.object(forKey: key) as? Date else { return true }
        return now.timeIntervalSince(lastReminder) >= 7 * 24 * 60 * 60
    }

    static func markReminded(about version: String) {
        UserDefaults.standard.set(Date.now, forKey: "shield.release.updateReminded.\(version)")
    }
}

enum AppReleasePrompt: Identifiable {
    case whatsNew
    case update(String)

    var id: String {
        switch self {
        case .whatsNew: "whatsNew"
        case .update(let version): version
        }
    }
}

struct AppReleaseHighlightsView: View {
    @Environment(\.colorScheme) private var scheme
    private var highlights: [AppRelease.Highlight] { AppRelease.highlights() }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(highlights.enumerated()), id: \.element.id) { index, highlight in
                HStack(alignment: .top, spacing: ShieldTheme.s3) {
                    SettingsIconBadge(icon: highlight.icon, color: ShieldTheme.accent, size: 34)
                    VStack(alignment: .leading, spacing: ShieldTheme.s1) {
                        Text(highlight.title)
                            .font(.body.weight(.semibold))
                        Text(highlight.detail)
                            .font(.subheadline)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .padding(ShieldTheme.s4)

                if index < highlights.count - 1 {
                    SettingsRowDivider(inset: 62)
                }
            }
        }
    }
}

struct AppReleaseSheet: View {
    let prompt: AppReleasePrompt
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme

    private var strings: LanguageManager { .shared }

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: ShieldTheme.s5) {
                    switch prompt {
                    case .whatsNew:
                        heading(icon: "sparkles", title: strings.settings("release_whats_new_title"))
                        if let version = AppRelease.installedVersion {
                            SettingsCardSection(
                                title: strings.settings("settings_version_value", version),
                                icon: "sparkles"
                            ) {
                                AppReleaseHighlightsView()
                            }
                        }
                    case .update(let version):
                        heading(title: strings.settings("release_update_title")) {
                            Image("AppStoreIcon")
                                .resizable()
                                .scaledToFit()
                            .frame(width: 78, height: 78)
                        }
                        Text(strings.settings("release_update_description", version))
                            .font(.body)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(ShieldTheme.s4)
                            .frame(maxWidth: .infinity)
                            .shieldSettingsCard()
                    }
                }
                .frame(maxWidth: 500)
                .padding(ShieldTheme.s4)
                .padding(.bottom, ShieldTheme.s3)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: ShieldTheme.s2) {
                switch prompt {
                case .whatsNew:
                    ShieldButton(label: strings.common("common_continue")) { dismiss() }
                case .update:
                    ShieldButton(label: strings.settings("release_update_action"), icon: "arrow.up.forward.app") {
                        openURL(AppStoreUpdate.pageURL) { accepted in
                            if accepted { dismiss() }
                        }
                    }
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text(strings.settings("release_update_later"))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ShieldTheme.minimumTapTarget)
                    }
                    .buttonStyle(.bordered)
                    .tint(ShieldTheme.primary(scheme))
                }
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, ShieldTheme.s3)
            .frame(maxWidth: .infinity)
            .background(ShieldTheme.pageBackground(scheme))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(ShieldTheme.line(scheme))
                    .frame(height: 1)
            }
        }
        .presentationBackground(ShieldTheme.pageBackground(scheme))
        .presentationDragIndicator(.visible)
        .onAppear {
            switch prompt {
            case .whatsNew: AppRelease.markNotesSeen()
            case .update(let version): AppStoreUpdate.markReminded(about: version)
            }
        }
    }

    private func heading(icon: String, title: String) -> some View {
        heading(title: title) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(ShieldTheme.accent(scheme))
        }
    }

    private func heading<Icon: View>(
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        VStack(spacing: ShieldTheme.s3) {
            icon()
                .accessibilityHidden(true)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
    }

}
