import SwiftUI
import UIKit
import Combine
import AVFoundation

// MARK: - Design tokens (from tokens.css)

enum ShieldTheme {
    /// The coordinator updates this value when the effective seasonal theme
    /// changes. Static tokens are kept as a compatibility layer while the
    /// existing UI migrates to the dynamic theme context incrementally.
    private(set) static var activeThemeID: SeasonalThemeID = .base

    static func setActiveTheme(_ themeID: SeasonalThemeID) {
        activeThemeID = themeID
    }

    // Surfaces — dark
    static var surface0: Color { activeThemeID == .halloween2026 ? Color(hex: "100A14") : Color(hex: "050D18") }
    static var surface1: Color { activeThemeID == .halloween2026 ? Color(hex: "17101D") : Color(hex: "071426") }
    static var surface2: Color { activeThemeID == .halloween2026 ? Color(hex: "26142E") : Color(hex: "0E2038") }
    static var surface3: Color { activeThemeID == .halloween2026 ? Color(hex: "33203C") : Color(hex: "142A45") }
    static var surface4: Color { activeThemeID == .halloween2026 ? Color(hex: "4A2A4A") : Color(hex: "1B3552") }
    static var surfaceLine: Color { activeThemeID == .halloween2026 ? Color(hex: "FFD6B0").opacity(0.10) : Color.white.opacity(0.08) }
    static var surfaceLineStrong: Color { activeThemeID == .halloween2026 ? Color(hex: "FFD6B0").opacity(0.18) : Color.white.opacity(0.14) }

    // Text — dark
    static var textPrimary: Color { activeThemeID == .halloween2026 ? Color(hex: "FFF7F0") : Color(hex: "F5F5F7") }
    static var textSecondary: Color { activeThemeID == .halloween2026 ? Color(hex: "FFD6B0").opacity(0.85) : textPrimary.opacity(0.72) }
    static var textTertiary: Color { activeThemeID == .halloween2026 ? Color(hex: "FFD6B0").opacity(0.68) : textPrimary.opacity(0.56) }
    static var textQuaternary: Color { activeThemeID == .halloween2026 ? Color(hex: "FFD6B0").opacity(0.45) : textPrimary.opacity(0.36) }

    // MaskID identity palette: electric cyan over deep privacy navy.
    static var accent: Color { activeThemeID == .halloween2026 ? Color(hex: "F97316") : Color(hex: "20C7D9") }
    static var accentStrong: Color { activeThemeID == .halloween2026 ? Color(hex: "FF9A3D") : Color(hex: "42DCEA") }
    static var accentDim: Color { accent.opacity(0.22) }
    static var accentText: Color { activeThemeID == .halloween2026 ? Color(hex: "1B0E05") : Color(hex: "071426") }

    // Semantic
    static var success: Color { activeThemeID == .halloween2026 ? Color(hex: "65A30D") : Color(hex: "30D158") }
    static var successDim: Color { success.opacity(0.16) }
    // The deeper Halloween orange remains readable on the light parchment
    // surfaces as well as on the dark obsidian surfaces.
    static var warning: Color { activeThemeID == .halloween2026 ? Color(hex: "C2410C") : Color(hex: "FF9F0A") }
    static var danger: Color { Color(hex: "FF453A") }
    static var dangerDim: Color { danger.opacity(0.16) }
    static var info: Color { activeThemeID == .halloween2026 ? Color(hex: "C084FC") : Color(hex: "64D2FF") }

    // Halloween accents are deliberately named so decorative views cannot
    // accidentally reuse a semantic color with insufficient contrast.
    static var halloweenBlood: Color { Color(hex: "9E1838") }
    static var halloweenBloodHighlight: Color { Color(hex: "D62F50") }
    static var halloweenPumpkin: Color { Color(hex: "F97316") }
    static var halloweenMoon: Color { Color(hex: "FFD6A0") }
    static var halloweenMoss: Color { Color(hex: "A3E635") }

    // Layout
    static let minimumTapTarget: CGFloat = 44
    static let controlHeight: CGFloat = 50
    static let readableWidth: CGFloat = 760
    static let workspaceWidth: CGFloat = 1_100

    // Radii
    static let rXS: CGFloat = 6
    static let rSM: CGFloat = 10
    static let rMD: CGFloat = 14
    static let rLG: CGFloat = 20
    static let rXL: CGFloat = 28

    // Spacing (4pt grid)
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
}

// MARK: - Seasonal themes

enum SeasonalThemeID: String, CaseIterable, Codable, Identifiable, Sendable {
    case base
    case halloween2026 = "halloween-2026"

    var id: String { rawValue }

    var icon: AppIconOption? {
        switch self {
        case .base: nil
        case .halloween2026: .halloween
        }
    }

    var isSeasonal: Bool { self != .base }

    func title(language: AppLanguage) -> String {
        let key = self == .base ? "settings_theme_base" : "settings_theme_halloween"
        return LanguageManager.shared.t(key, table: "Settings", language: language)
    }

    func subtitle(language: AppLanguage) -> String {
        let key = self == .base ? "settings_theme_base_subtitle" : "settings_theme_halloween_subtitle"
        return LanguageManager.shared.t(key, table: "Settings", language: language)
    }
}

enum SeasonalThemeSelection: Codable, Equatable, Sendable {
    case automatic
    case manual(SeasonalThemeID)
    case base
}

enum SeasonalThemeAvailability: Equatable, Sendable {
    case base
    case upcoming
    case active
    case archived
}

enum SeasonalThemeSchedulePolicy: Codable, Equatable, Sendable {
    case deviceLocalCalendar
    case fixedTimeZone(String)
    case absoluteUTC
}

struct SeasonalThemeSchedule: Codable, Equatable, Sendable {
    let calendarIdentifier: String
    let start: DateComponents
    let end: DateComponents
    let policy: SeasonalThemeSchedulePolicy
    /// Editorial reference zone used for communicating the event window.
    /// Resolution still follows `policy`, so this never changes the user's
    /// local-calendar behavior.
    let referenceTimeZoneIdentifier: String?

    func bounds(using clock: SeasonalThemeClock) -> (start: Date, end: Date)? {
        let timeZone: TimeZone
        switch policy {
        case .deviceLocalCalendar:
            timeZone = clock.timeZone
        case .fixedTimeZone(let identifier):
            timeZone = TimeZone(identifier: identifier) ?? clock.timeZone
        case .absoluteUTC:
            timeZone = TimeZone(secondsFromGMT: 0) ?? clock.timeZone
        }

        var calendar = Calendar(identifier: calendarIdentifier == "gregorian" ? .gregorian : .gregorian)
        calendar.timeZone = timeZone
        guard let startDate = calendar.date(from: start),
              let endDate = calendar.date(from: end),
              endDate > startDate else {
            return nil
        }
        return (startDate, endDate)
    }

    func availability(at date: Date, using clock: SeasonalThemeClock) -> SeasonalThemeAvailability {
        guard let bounds = bounds(using: clock) else { return .archived }
        if date < bounds.start { return .upcoming }
        if date < bounds.end { return .active }
        return .archived
    }
}

struct SeasonalThemeDefinition: Identifiable, Sendable {
    let id: SeasonalThemeID
    let version: Int
    let titleKey: String
    let subtitleKey: String
    let icon: AppIconOption?
    let schedule: SeasonalThemeSchedule?
    let requiresProForManualActivation: Bool
    let priority: Int
    let eventNameKey: String?
    let eventDescriptionKey: String?
    let eventBannerAssetName: String?
    let eventDetailArtworkAssetName: String?

    var isBase: Bool { id == .base }
}

struct SeasonalThemeClock: Sendable {
    var now: Date
    var timeZone: TimeZone

    init(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent) {
        self.now = now
        self.timeZone = timeZone
    }
}

enum SeasonalThemeCatalog {
    static let definitions: [SeasonalThemeDefinition] = [
        SeasonalThemeDefinition(
            id: .base,
            version: 1,
            titleKey: "settings_theme_base",
            subtitleKey: "settings_theme_base_subtitle",
            icon: nil,
            schedule: nil,
            requiresProForManualActivation: false,
            priority: 0,
            eventNameKey: nil,
            eventDescriptionKey: nil,
            eventBannerAssetName: nil,
            eventDetailArtworkAssetName: nil
        ),
        SeasonalThemeDefinition(
            id: .halloween2026,
            version: 1,
            titleKey: "settings_theme_halloween",
            subtitleKey: "settings_theme_halloween_subtitle",
            icon: .halloween,
            schedule: SeasonalThemeSchedule(
                calendarIdentifier: "gregorian",
                start: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 10, day: 1, hour: 0, minute: 0),
                end: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 1, hour: 0, minute: 0),
                policy: .deviceLocalCalendar,
                referenceTimeZoneIdentifier: "Europe/Madrid"
            ),
            requiresProForManualActivation: true,
            priority: 10,
            eventNameKey: "settings_theme_halloween_event_name",
            eventDescriptionKey: "settings_theme_halloween_event_description",
            eventBannerAssetName: "SeasonalThemeEventBanner",
            eventDetailArtworkAssetName: "SeasonalThemeEventArtwork"
        )
    ]

    static func definition(for id: SeasonalThemeID) -> SeasonalThemeDefinition? {
        definitions.first { $0.id == id }
    }
}

enum SeasonalThemeResolver {
    static func activeScheduledTheme(
        at clock: SeasonalThemeClock,
        catalog: [SeasonalThemeDefinition] = SeasonalThemeCatalog.definitions
    ) -> SeasonalThemeID? {
        catalog
            .filter { !$0.isBase }
            .filter { $0.schedule?.availability(at: clock.now, using: clock) == .active }
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority { return lhs.version > rhs.version }
                return lhs.priority > rhs.priority
            }
            .first?
            .id
    }

    static func resolve(
        isPro: Bool,
        selection: SeasonalThemeSelection,
        at clock: SeasonalThemeClock,
        catalog: [SeasonalThemeDefinition] = SeasonalThemeCatalog.definitions
    ) -> SeasonalThemeID {
        if isPro {
            switch selection {
            case .manual(let id):
                guard let definition = catalog.first(where: { $0.id == id }) else { return .base }
                if let schedule = definition.schedule,
                   schedule.availability(at: clock.now, using: clock) == .upcoming {
                    // A future theme may be inspected, but never becomes the
                    // effective theme before its window starts.
                    return .base
                }
                return id
            case .base:
                return .base
            case .automatic:
                break
            }
        }
        return activeScheduledTheme(at: clock, catalog: catalog) ?? .base
    }

    static func canManuallyActivate(
        isPro: Bool,
        themeID: SeasonalThemeID,
        at clock: SeasonalThemeClock,
        catalog: [SeasonalThemeDefinition] = SeasonalThemeCatalog.definitions
    ) -> Bool {
        guard isPro, let definition = catalog.first(where: { $0.id == themeID }) else { return false }
        guard let schedule = definition.schedule else { return true }
        return schedule.availability(at: clock.now, using: clock) != .upcoming
    }
}

final class SeasonalThemeCoordinator: ObservableObject {
    static let shared = SeasonalThemeCoordinator()

    @Published private(set) var activeThemeID: SeasonalThemeID = .base
    @Published private(set) var selection: SeasonalThemeSelection
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isSoundscapeEnabled: Bool
#if DEBUG
#if targetEnvironment(simulator)
    /// A simulator-only override used to inspect any catalog theme without
    /// changing the Free/Pro or date-based production rules.
    @Published private(set) var debugPreviewThemeID: SeasonalThemeID?
#endif
#endif

    private let selectionKey = "shield.theme.selection"
    private let selectedThemeKey = "shield.theme.selectedID"
    private let soundscapeEnabledKey = "shield.theme.halloween.soundscapeEnabled"
#if DEBUG
#if targetEnvironment(simulator)
    private let debugPreviewThemeKey = "shield.theme.debugPreviewID"
#endif
#endif
    private let userDefaults: UserDefaults
    private var timeZoneObserver: NSObjectProtocol?
    private let soundscape = SeasonalThemeSoundscape()
    private var isSceneActive = false

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: selectionKey),
           let decoded = try? JSONDecoder().decode(SeasonalThemeSelection.self, from: data) {
            selection = decoded
        } else if let rawValue = userDefaults.string(forKey: selectedThemeKey),
                  let id = SeasonalThemeID(rawValue: rawValue) {
            selection = .manual(id)
        } else {
            selection = .automatic
        }
        isSoundscapeEnabled = userDefaults.bool(forKey: soundscapeEnabledKey)
#if DEBUG
#if targetEnvironment(simulator)
        if let rawValue = userDefaults.string(forKey: debugPreviewThemeKey) {
            debugPreviewThemeID = SeasonalThemeID(rawValue: rawValue)
        } else {
            debugPreviewThemeID = nil
        }
#endif
#endif

        timeZoneObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        refresh()
    }

    deinit {
        if let timeZoneObserver {
            NotificationCenter.default.removeObserver(timeZoneObserver)
        }
        soundscape.stop()
    }

    var definitions: [SeasonalThemeDefinition] { SeasonalThemeCatalog.definitions }

    func canManuallyActivate(
        _ id: SeasonalThemeID,
        clock: SeasonalThemeClock = SeasonalThemeClock()
    ) -> Bool {
        SeasonalThemeResolver.canManuallyActivate(
            isPro: isPro,
            themeID: id,
            at: clock
        )
    }

    func refresh(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent, isPro: Bool? = nil) {
        if let isPro { self.isPro = isPro }
#if DEBUG
#if targetEnvironment(simulator)
        if let debugPreviewThemeID {
            userDefaults.set(false, forKey: "shield.theme.manualIconOverride")
            apply(themeID: debugPreviewThemeID)
            updateSoundscape()
            return
        }
#endif
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-theme-halloween") {
            userDefaults.set(false, forKey: "shield.theme.manualIconOverride")
            apply(themeID: .halloween2026)
            updateSoundscape()
            return
        }
#endif
#endif
        let next = SeasonalThemeResolver.resolve(
            isPro: self.isPro,
            selection: selection,
            at: SeasonalThemeClock(now: now, timeZone: timeZone)
        )
        guard next != activeThemeID else {
            ShieldTheme.setActiveTheme(next)
            updateSoundscape()
            return
        }
        let previous = activeThemeID
        activeThemeID = next
        ShieldTheme.setActiveTheme(next)
        AppState.trackEvent(
            "theme_automatic_applied",
            properties: ["name": next.rawValue, "from_step": previous.rawValue]
        )
        updateSoundscape()
    }

    /// Keeps the ambient audio tied to the app's foreground state. Sound is
    /// intentionally opt-in and is never required to understand the UI.
    func setSceneActive(_ active: Bool) {
        isSceneActive = active
        updateSoundscape()
    }

    func setSoundscapeEnabled(_ enabled: Bool) {
        guard isSoundscapeEnabled != enabled else { return }
        isSoundscapeEnabled = enabled
        userDefaults.set(enabled, forKey: soundscapeEnabledKey)
        updateSoundscape()
    }

    private func updateSoundscape() {
        guard isSceneActive,
              isSoundscapeEnabled,
              activeThemeID == .halloween2026 else {
            soundscape.stop()
            return
        }
        soundscape.start()
    }

#if DEBUG
#if targetEnvironment(simulator)
    /// Applies a temporary theme override for simulator inspection.
    /// Passing nil restores the real schedule and Free/Pro selection rules.
    func setDebugPreviewTheme(_ themeID: SeasonalThemeID?) {
        debugPreviewThemeID = themeID
        if let themeID {
            userDefaults.set(themeID.rawValue, forKey: debugPreviewThemeKey)
        } else {
            userDefaults.removeObject(forKey: debugPreviewThemeKey)
        }
        refresh(isPro: isPro)
    }
#endif
#endif

    func availability(for id: SeasonalThemeID, clock: SeasonalThemeClock = SeasonalThemeClock()) -> SeasonalThemeAvailability {
        guard let definition = SeasonalThemeCatalog.definition(for: id) else { return .archived }
        guard let schedule = definition.schedule else { return .base }
        return schedule.availability(at: clock.now, using: clock)
    }

    @discardableResult
    func select(_ next: SeasonalThemeSelection) -> Bool {
        if case .base = next, !isPro {
            return false
        }
        if case .manual(let id) = next,
           let definition = SeasonalThemeCatalog.definition(for: id),
           definition.requiresProForManualActivation,
           !isPro {
            SeasonalThemeCoordinator.recordLockedThemeTap(id)
            return false
        }
        if case .manual(let id) = next, !canManuallyActivate(id) {
            AppState.trackEvent("theme_activation_started", properties: [
                "name": id.rawValue,
                "mode": "scheduled"
            ])
            return false
        }
        selection = next
        persistSelection()
        AppState.trackEvent("theme_activation_completed", properties: [
            "name": selection.analyticsName,
            "mode": selection.analyticsMode
        ])
        refresh()
        return true
    }

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            userDefaults.set(data, forKey: selectionKey)
        }
        if case .manual(let id) = selection {
            userDefaults.set(id.rawValue, forKey: selectedThemeKey)
        } else {
            userDefaults.removeObject(forKey: selectedThemeKey)
        }
    }

    private func apply(themeID: SeasonalThemeID) {
        let previous = activeThemeID
        activeThemeID = themeID
        ShieldTheme.setActiveTheme(themeID)
        guard previous != themeID else { return }
        AppState.trackEvent(
            "theme_automatic_applied",
            properties: ["name": themeID.rawValue, "from_step": previous.rawValue]
        )
        updateSoundscape()
    }

    private static func recordLockedThemeTap(_ id: SeasonalThemeID) {
        PremiumManager.recordFeatureGate(.seasonalThemes, trigger: .styleLocked)
        AppState.trackEvent("theme_activation_started", properties: ["name": id.rawValue, "mode": "locked"])
    }
}

private extension SeasonalThemeSelection {
    var analyticsMode: String {
        switch self {
        case .automatic: "automatic"
        case .manual: "manual"
        case .base: "base"
        }
    }

    var analyticsName: String {
        switch self {
        case .automatic: "automatic"
        case .manual(let id): id.rawValue
        case .base: SeasonalThemeID.base.rawValue
        }
    }
}

/// Small, generated Halloween stingers keep the theme self-contained and
/// avoid shipping a large audio bundle. They use the ambient audio category,
/// respect the mute switch, mix with other audio, and only run when the user
/// explicitly enables them from the theme settings.
private final class SeasonalThemeSoundscape {
    private var timer: Timer?
    private let audioQueue = DispatchQueue(label: "com.romerodev.maskid.halloween-soundscape")
    private var isRunning = false
    private var player: AVAudioPlayer?

    func start() {
        guard timer == nil else { return }
        audioQueue.async { [weak self] in
            self?.isRunning = true
        }
        scheduleNext(after: 7)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.isRunning = false
            self.player?.stop()
            self.player = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func scheduleNext(after delay: TimeInterval? = nil) {
        timer?.invalidate()
        let interval = delay ?? Double.random(in: 16...30)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.timer = nil
            self?.playRandomStinger()
            self?.scheduleNext()
        }
    }

    private func playRandomStinger() {
        // AVAudioSession activation can block when performed on the main
        // thread. Keep all session/player work off the UI thread so the
        // cosmetic soundscape cannot affect navigation or accessibility.
        audioQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, options: [.mixWithOthers])
                try session.setActive(true)
                self.player = try AVAudioPlayer(data: HalloweenSoundData.makeRandomStinger())
                self.player?.volume = 0.16
                self.player?.prepareToPlay()
                self.player?.play()
            } catch {
                // Audio is decorative. A device without an available audio
                // session must never affect the theme or the document workflow.
            }
        }
    }
}

private enum HalloweenSoundData {
    static func makeRandomStinger() -> Data {
        let sampleRate = 22_050
        let duration = Double.random(in: 0.8...1.5)
        let frameCount = Int(Double(sampleRate) * duration)
        let style = Int.random(in: 0..<3)
        var samples = [Int16]()
        samples.reserveCapacity(frameCount)

        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            let progress = time / duration
            let envelope = min(1, time * 16) * max(0, 1 - progress) * max(0, 1 - progress)
            let value: Double

            switch style {
            case 0: // Low, haunted pulse with a breath of filtered noise.
                let frequency = 92 + 24 * sin(time * 1.4)
                let pulse = sin(2 * .pi * frequency * time) * 0.62
                let harmonic = sin(2 * .pi * frequency * 1.97 * time) * 0.18
                let noise = Double.random(in: -1...1) * 0.07
                value = (pulse + harmonic + noise) * envelope
            case 1: // A soft bell-like chime.
                let fundamental = sin(2 * .pi * 392 * time)
                let fifth = sin(2 * .pi * 587.33 * time) * 0.33
                let octave = sin(2 * .pi * 784 * time) * 0.16
                value = (fundamental + fifth + octave) * envelope * 0.42
            default: // Creak: descending partials plus a granular edge.
                let frequency = 240 - 160 * progress
                let saw = ((time * frequency).truncatingRemainder(dividingBy: 1) * 2) - 1
                let wobble = sin(2 * .pi * 3.2 * time) * 0.16
                value = (saw * 0.28 + wobble + Double.random(in: -1...1) * 0.035) * envelope
            }

            let clipped = max(-1, min(1, value * 0.55))
            samples.append(Int16(clipped * Double(Int16.max)))
        }

        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36 + samples.count * 2), to: &data)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16), to: &data)
        append(UInt16(1), to: &data)
        append(UInt16(1), to: &data)
        append(UInt32(sampleRate), to: &data)
        append(UInt32(sampleRate * 2), to: &data)
        append(UInt16(2), to: &data)
        append(UInt16(16), to: &data)
        data.append(contentsOf: Array("data".utf8))
        append(UInt32(samples.count * 2), to: &data)
        for sample in samples {
            append(sample, to: &data)
        }
        return data
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { rawBuffer in
            data.append(contentsOf: rawBuffer)
        }
    }
}

struct SeasonalThemeAmbientLayer: View {
    @EnvironmentObject private var coordinator: SeasonalThemeCoordinator
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if coordinator.activeThemeID == .halloween2026 {
            VStack(spacing: 0) {
                // A single restrained blood-red edge keeps the theme present
                // on lock, settings, editor and onboarding without placing
                // decorative content over controls.
                LinearGradient(
                    colors: [
                        ShieldTheme.halloweenBlood.opacity(reduceTransparency ? 0.18 : 0.42),
                        ShieldTheme.halloweenPumpkin.opacity(reduceTransparency ? 0.10 : 0.30),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                Spacer(minLength: 0)
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Full-screen seasonal art direction shared by every managed-theme surface.
/// The artwork stays behind the UI, is hidden from VoiceOver, and is removed
/// when transparency reduction is enabled so the theme never competes with
/// controls or document content.
struct SeasonalThemeBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme)

            if ShieldTheme.activeThemeID == .halloween2026,
               scheme == .dark,
               !reduceTransparency {
                GeometryReader { geo in
                    Image("SeasonalThemeBackdrop")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(0.88)
                        .overlay {
                            LinearGradient(
                                colors: [
                                    Color(hex: "09050F").opacity(0.15),
                                    .clear,
                                    Color(hex: "100A14").opacity(0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The active theme's visual stage for the library. It is deliberately behind
/// the app content and fades before the first interactive card, so the art
/// adds identity without reducing text contrast or changing hit regions.
struct SeasonalThemeHomeBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack(alignment: .top) {
            RadialGradient(
                colors: [
                    ShieldTheme.halloweenPumpkin.opacity(scheme == .dark ? 0.18 : 0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 260
            )
            .frame(height: 300)

            SeasonalThemeHomeWeb()
                .frame(width: 140, height: 110)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
                .opacity(scheme == .dark ? 0.30 : 0.16)
        }
        .frame(height: 290)
        .allowsHitTesting(false)
    }
}

private struct SeasonalThemeHomeWeb: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width, y: 0)
            let radius = min(size.width, size.height) * 0.92
            var web = Path()
            for spoke in 0..<7 {
                let angle = Double(spoke) * .pi / 3.5
                web.move(to: center)
                web.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            }
            for ring in 1...4 {
                web.addArc(
                    center: center,
                    radius: radius * CGFloat(ring) / 4,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false
                )
            }
            context.stroke(
                web,
                with: .color(ShieldTheme.halloweenMoon),
                style: StrokeStyle(lineWidth: 1, lineCap: .round)
            )
        }
        .accessibilityHidden(true)
    }
}

struct SeasonalThemeWebCorner: View {
    var size: CGFloat = 60

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: 0, y: 0)
            let radius = min(canvasSize.width, canvasSize.height) * 0.98
            var web = Path()
            for spoke in 0..<7 {
                let angle = Double(spoke) * .pi / 3.25
                web.move(to: center)
                web.addLine(to: CGPoint(x: cos(angle) * radius, y: sin(angle) * radius))
            }
            for ring in 1...4 {
                let r = radius * CGFloat(ring) / 4
                web.addArc(
                    center: center,
                    radius: r,
                    startAngle: .degrees(-2),
                    endAngle: .degrees(92),
                    clockwise: false
                )
            }
            context.stroke(
                web,
                with: .color(ShieldTheme.halloweenMoon.opacity(0.35)),
                style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct SeasonalThemeCandelabra: View {
    var size: CGFloat = 36

    var body: some View {
        Canvas { context, canvasSize in
            let color = ShieldTheme.halloweenMoon.opacity(0.75)
            let flame = ShieldTheme.halloweenPumpkin
            var holder = Path()
            holder.move(to: CGPoint(x: canvasSize.width * 0.12, y: canvasSize.height * 0.76))
            holder.addCurve(
                to: CGPoint(x: canvasSize.width * 0.88, y: canvasSize.height * 0.76),
                control1: CGPoint(x: canvasSize.width * 0.26, y: canvasSize.height * 0.56),
                control2: CGPoint(x: canvasSize.width * 0.74, y: canvasSize.height * 0.56)
            )
            holder.addLine(to: CGPoint(x: canvasSize.width * 0.78, y: canvasSize.height * 0.84))
            holder.addLine(to: CGPoint(x: canvasSize.width * 0.22, y: canvasSize.height * 0.84))
            holder.closeSubpath()
            context.stroke(holder, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

            for x in [0.22, 0.50, 0.78] {
                let candleX = canvasSize.width * x
                var stem = Path()
                stem.move(to: CGPoint(x: candleX, y: canvasSize.height * 0.66))
                stem.addLine(to: CGPoint(x: candleX, y: canvasSize.height * 0.30))
                context.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                context.fill(
                    Ellipse().path(in: CGRect(x: candleX - 3.5, y: canvasSize.height * 0.14, width: 7, height: 13)),
                    with: .color(flame.opacity(0.95))
                )
                context.fill(
                    Ellipse().path(in: CGRect(x: candleX - 1.5, y: canvasSize.height * 0.17, width: 3, height: 7)),
                    with: .color(Color(hex: "FFF7D6"))
                )
            }
        }
        .frame(width: size, height: size * 0.85)
        .shadow(color: ShieldTheme.halloweenPumpkin.opacity(0.55), radius: 8)
        .accessibilityHidden(true)
    }
}

struct SeasonalThemeHalloweenPumpkin: View {
    var size: CGFloat = 32

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.58)
            let pumpkin = CGRect(x: canvasSize.width * 0.08, y: canvasSize.height * 0.24, width: canvasSize.width * 0.84, height: canvasSize.height * 0.58)
            context.fill(Ellipse().path(in: pumpkin), with: .color(ShieldTheme.halloweenPumpkin.opacity(0.92)))

            for offset in [-0.28, 0.0, 0.28] {
                let ridge = CGRect(
                    x: canvasSize.width * (0.5 + offset * 0.42) - canvasSize.width * 0.17,
                    y: canvasSize.height * 0.30,
                    width: canvasSize.width * 0.34,
                    height: canvasSize.height * 0.46
                )
                context.stroke(
                    Ellipse().path(in: ridge),
                    with: .color(Color.white.opacity(0.18)),
                    style: StrokeStyle(lineWidth: 1.2)
                )
            }

            var stem = Path()
            stem.move(to: CGPoint(x: center.x, y: canvasSize.height * 0.27))
            stem.addLine(to: CGPoint(x: center.x + 2, y: canvasSize.height * 0.10))
            context.stroke(stem, with: .color(ShieldTheme.halloweenMoss.opacity(0.85)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            context.fill(
                Path { path in
                    path.move(to: CGPoint(x: canvasSize.width * 0.26, y: canvasSize.height * 0.51))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.43, y: canvasSize.height * 0.47))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.35, y: canvasSize.height * 0.58))
                    path.closeSubpath()
                },
                with: .color(ShieldTheme.halloweenMoon.opacity(0.85))
            )
            context.fill(
                Path { path in
                    path.move(to: CGPoint(x: canvasSize.width * 0.57, y: canvasSize.height * 0.47))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.74, y: canvasSize.height * 0.51))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.65, y: canvasSize.height * 0.58))
                    path.closeSubpath()
                },
                with: .color(ShieldTheme.halloweenMoon.opacity(0.85))
            )
            // Smiling carved mouth
            context.fill(
                Path { path in
                    path.move(to: CGPoint(x: canvasSize.width * 0.30, y: canvasSize.height * 0.66))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.40, y: canvasSize.height * 0.74))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.50, y: canvasSize.height * 0.68))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.60, y: canvasSize.height * 0.74))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.70, y: canvasSize.height * 0.66))
                    path.addLine(to: CGPoint(x: canvasSize.width * 0.50, y: canvasSize.height * 0.78))
                    path.closeSubpath()
                },
                with: .color(ShieldTheme.halloweenMoon.opacity(0.85))
            )
        }
        .frame(width: size, height: size)
        .shadow(color: ShieldTheme.halloweenPumpkin.opacity(0.50), radius: 8)
        .accessibilityHidden(true)
    }
}

private struct SeasonalThemeHalloweenInsect: View {
    var body: some View {
        ZStack {
            Image(systemName: "ant.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "17101D"), ShieldTheme.halloweenBloodHighlight)
                .shadow(color: ShieldTheme.halloweenBloodHighlight.opacity(0.45), radius: 4)
        }
        .frame(width: 28, height: 22)
        .accessibilityHidden(true)
    }
}

/// Code-native Halloween artwork used as a lightweight, resolution-independent
/// texture across the app. It avoids a full-screen bitmap while retaining a
/// recognizable spiderweb, ember field, and moonlit motif on every device.
private struct SeasonalThemeHalloweenTexture: View {
    let reduceTransparency: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width - 24, y: 32)
            let maxRadius = min(size.width, size.height) * 0.28
            var web = Path()

            for spoke in 0..<8 {
                let angle = (Double(spoke) / 8.0) * (Double.pi * 2)
                let end = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * maxRadius,
                    y: center.y + CGFloat(sin(angle)) * maxRadius
                )
                web.move(to: center)
                web.addLine(to: end)
            }

            for ring in 1...4 {
                let radius = maxRadius * CGFloat(ring) / 4
                web.addEllipse(
                    in: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
            }

            context.stroke(
                web,
                with: .color(Color(hex: "FFD6B0").opacity(reduceTransparency ? 0.035 : 0.11)),
                style: StrokeStyle(lineWidth: 0.8, lineCap: .round)
            )

            let emberColor = Color(hex: "FFB454").opacity(reduceTransparency ? 0.08 : 0.20)
            for index in 0..<18 {
                let phase = CGFloat(index) * 0.73
                let x = (sin(phase * 4.1) * 0.5 + 0.5) * size.width
                let y = (cos(phase * 2.7) * 0.5 + 0.5) * size.height
                let dotSize = CGFloat(1 + index % 3)
                context.fill(
                    Circle().path(in: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(emberColor)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct SeasonalThemeHalloweenMotif: View {
    let reduceMotion: Bool

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFB454").opacity(0.16),
                            Color(hex: "7C3AED").opacity(0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 58
                    )
                )

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: "FFB454"), Color(hex: "C084FC"))
                .shadow(color: Color(hex: "FF9A3D").opacity(0.45), radius: 12)
                .scaleEffect(isPulsing ? 1.04 : 0.96)

            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: "FFD6B0").opacity(0.72))
                .offset(x: 27, y: -21)
                .rotationEffect(.degrees(isPulsing ? 8 : -8))
        }
        .frame(width: 96, height: 96)
        .opacity(0.9)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            guard !reduceMotion else { return }
            isPulsing = true
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Small non-blocking banner used when a seasonal theme changes. It makes the
/// transition legible without forcing a navigation or presenting a modal.
struct SeasonalThemeChangeOverlay: View {
    let themeID: SeasonalThemeID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: ShieldTheme.s3) {
            if let icon = themeID.icon {
                icon.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "shield.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ShieldTheme.accent(scheme))
                    .frame(width: 30, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(themeID.title(language: LanguageManager.shared.current))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.settings("settings_theme_applied"))
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
            }

            Spacer(minLength: 0)
            Image(systemName: themeID.isSeasonal ? "sparkles" : "checkmark.circle.fill")
                .foregroundStyle(ShieldTheme.accent(scheme))
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, ShieldTheme.s3)
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
        }
        .shadow(color: ShieldTheme.accent(scheme).opacity(0.24), radius: 16, y: 8)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible || reduceMotion ? 0 : -12)
        .animation(reduceMotion ? nil : ShieldMotion.navigation, value: isVisible)
        .onAppear { isVisible = true }
        .accessibilityElement(children: .combine)
    }
}

/// Theme-aware loading affordance used by shared buttons and state screens.
/// Halloween gets a moon/ember treatment; other themes retain the native
/// spinner so the seasonal system remains additive rather than intrusive.
struct SeasonalThemeLoadingIndicator: View {
    var size: CGFloat = 18
    var color: Color? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var isAnimating = false

    var body: some View {
        if ShieldTheme.activeThemeID == .halloween2026 {
            ZStack {
                Circle()
                    .stroke(ShieldTheme.accent(scheme).opacity(0.24), lineWidth: max(1.5, size * 0.10))
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: size * 0.46, weight: .bold))
                    .foregroundStyle(color ?? ShieldTheme.accent(scheme))
                    .scaleEffect(isAnimating ? 1.08 : 0.9)
                    .rotationEffect(.degrees(isAnimating ? 7 : -7))
            }
            .frame(width: size, height: size)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                guard !reduceMotion else { return }
                isAnimating = true
            }
            .accessibilityHidden(true)
        } else {
            ProgressView()
                .controlSize(size <= 18 ? .small : .regular)
                .tint(color ?? ShieldTheme.accent(scheme))
                .accessibilityHidden(true)
        }
    }
}

/// Glowing spiderweb and ember aura rendered behind the central floating scan button
struct SeasonalScanButtonHalo: View {
    let reduceMotion: Bool
    @State private var rotation: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // Radial spiderweb aura
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = size.width * 0.48
                var web = Path()
                for spoke in 0..<10 {
                    let angle = Double(spoke) * .pi / 5
                    web.move(to: center)
                    web.addLine(to: CGPoint(x: center.x + cos(angle) * maxRadius, y: center.y + sin(angle) * maxRadius))
                }
                for ring in 1...3 {
                    let r = maxRadius * CGFloat(ring) / 3
                    web.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                }
                context.stroke(
                    web,
                    with: .color(ShieldTheme.halloweenPumpkin.opacity(0.35)),
                    style: StrokeStyle(lineWidth: 0.8, dash: [3, 2])
                )
            }
            .frame(width: 72, height: 72)

            // Outer rotating ember ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            ShieldTheme.halloweenPumpkin.opacity(0.8),
                            ShieldTheme.halloweenMoon.opacity(0.4),
                            ShieldTheme.halloweenBlood.opacity(0.6),
                            ShieldTheme.halloweenPumpkin.opacity(0.8)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.0
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(rotation))
                .shadow(color: ShieldTheme.halloweenPumpkin.opacity(glowPulse ? 0.45 : 0.2), radius: 4.5)

            // Mini flanking pumpkins
            HStack(spacing: 44) {
                SeasonalThemeHalloweenPumpkin(size: 10)
                SeasonalThemeHalloweenPumpkin(size: 10)
            }
            .offset(y: 18)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
            value: glowPulse
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 24).repeatForever(autoreverses: false),
            value: rotation
        )
        .onAppear {
            guard !reduceMotion else { return }
            glowPulse = true
            rotation = 360
        }
    }
}

/// Glowing tech radar and cyber aura rendered behind the standard central floating scan button
struct StandardScanButtonHalo: View {
    let reduceMotion: Bool
    @State private var rotation: Double = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // Tech radar / concentric pulse rings
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = size.width * 0.48
                var radar = Path()
                for spoke in 0..<8 {
                    let angle = Double(spoke) * .pi / 4
                    radar.move(to: center)
                    radar.addLine(to: CGPoint(x: center.x + cos(angle) * maxRadius, y: center.y + sin(angle) * maxRadius))
                }
                for ring in 1...3 {
                    let r = maxRadius * CGFloat(ring) / 3
                    radar.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                }
                context.stroke(
                    radar,
                    with: .color(Color(hex: "20C7D9").opacity(0.28)),
                    style: StrokeStyle(lineWidth: 0.8, dash: [3, 2])
                )
            }
            .frame(width: 72, height: 72)

            // Outer rotating electric cyan ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "20C7D9").opacity(0.75),
                            Color(hex: "80F5FF").opacity(0.40),
                            Color(hex: "0898AA").opacity(0.60),
                            Color(hex: "20C7D9").opacity(0.75)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.0
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color(hex: "20C7D9").opacity(glowPulse ? 0.45 : 0.2), radius: 4.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
            value: glowPulse
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 24).repeatForever(autoreverses: false),
            value: rotation
        )
        .onAppear {
            guard !reduceMotion else { return }
            glowPulse = true
            rotation = 360
        }
    }
}

/// Large glowing mask hero used on the locked Vault screen
struct SeasonalVaultHeroView: View {
    var size: CGFloat = 160
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var rotateDashes = false

    var body: some View {
        ZStack {
            // Warm background radial bloom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ShieldTheme.halloweenPumpkin.opacity(0.38),
                            ShieldTheme.halloweenBlood.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.78
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(pulse ? 1.05 : 0.95)

            // Outer dashed glowing ring
            Circle()
                .stroke(
                    ShieldTheme.halloweenPumpkin.opacity(0.75),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 7])
                )
                .frame(width: size * 0.98, height: size * 0.98)
                .rotationEffect(.degrees(rotateDashes ? 360 : 0))

            // Inner solid glowing neon ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD6A0"),
                            ShieldTheme.halloweenPumpkin,
                            Color(hex: "EA580C")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3.5
                )
                .frame(width: size * 0.82, height: size * 0.82)
                .shadow(color: ShieldTheme.halloweenPumpkin.opacity(0.85), radius: 14)

            // Center dark obsidian disc
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "24122E"), Color(hex: "120817")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.78, height: size * 0.78)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }

            // MaskID identity mark
            MaskIDIdentityMark(
                size: size * 0.52,
                presentation: .animatedLoop,
                treatment: .hero
            )

            // Floating orange digital sparks/pixels
            ForEach(0..<6, id: \.self) { i in
                let offsetAngle = Double(i) * 0.38 - 0.45
                let distance = size * 0.38 + CGFloat((i % 3) * 6)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(ShieldTheme.halloweenPumpkin)
                    .frame(width: CGFloat(3 + (i % 3)), height: CGFloat(3 + (i % 3)))
                    .shadow(color: ShieldTheme.halloweenPumpkin, radius: 4)
                    .offset(
                        x: cos(offsetAngle) * distance,
                        y: sin(offsetAngle) * distance
                    )
            }
        }
        .frame(width: size, height: size)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
            value: pulse
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 20).repeatForever(autoreverses: false),
            value: rotateDashes
        )
        .onAppear {
            guard !reduceMotion else { return }
            pulse = true
            rotateDashes = true
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Light-mode adaptive colors

extension ShieldTheme {
    /// Spacing inside a root view that already respects the top safe area.
    /// Do not add `safeAreaInsets.top` again: SwiftUI has already positioned
    /// the view below the status bar / Dynamic Island.
    static let topChromePadding: CGFloat = 10
    static let topChromeBottomSpacing: CGFloat = 10
    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accentStrong : accent
    }
    static func accentDim(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.18) : accent.opacity(0.24)
    }
    static func accentStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.34) : accent.opacity(0.56)
    }
    static func background(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? surface1 : Color(hex: "F7EFE7")
        }
        return scheme == .dark ? surface1 : Color(hex: "F7F7FA")
    }
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? surface2 : Color(hex: "FFFBF7")
        }
        return scheme == .dark ? surface2 : Color.white
    }
    static func rowBackground(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? surface3 : Color(hex: "F0E1D7")
        }
        return scheme == .dark ? surface3 : Color(hex: "ECECF1")
    }
    static func line(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? surfaceLine : Color(hex: "5D334D").opacity(0.18)
        }
        return scheme == .dark ? surfaceLine : Color.black.opacity(0.14)
    }
    static func strongLine(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? surfaceLineStrong : Color(hex: "5D334D").opacity(0.30)
        }
        return scheme == .dark ? surfaceLineStrong : Color.black.opacity(0.24)
    }
    static func elevatedBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface3 : Color(hex: "FDFDFE")
    }
    static func selectedBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.18) : accent.opacity(0.14)
    }
    static func successBackground(_ scheme: ColorScheme) -> Color {
        success.opacity(scheme == .dark ? 0.16 : 0.12)
    }
    static func warningBackground(_ scheme: ColorScheme) -> Color {
        warning.opacity(scheme == .dark ? 0.18 : 0.13)
    }
    static func errorBackground(_ scheme: ColorScheme) -> Color {
        danger.opacity(scheme == .dark ? 0.18 : 0.12)
    }
    static func scrim(_ scheme: ColorScheme) -> Color {
        Color.black.opacity(scheme == .dark ? 0.58 : 0.34)
    }
    static func primary(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? textPrimary : Color(hex: "241229")
        }
        return scheme == .dark ? textPrimary : Color(hex: "0A0A0B")
    }
    static func secondary(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? textSecondary : Color(hex: "241229").opacity(0.66)
        }
        return scheme == .dark ? textSecondary : Color(hex: "0A0A0B").opacity(0.66)
    }
    static func tertiary(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? textTertiary : Color(hex: "241229").opacity(0.42)
        }
        return scheme == .dark ? textTertiary : Color(hex: "0A0A0B").opacity(0.42)
    }
    static func accentColor(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? accentStrong : Color(hex: "C94C00")
        }
        return scheme == .dark ? accent : Color(hex: "087D8A")
    }
    static func pageBackground(_ scheme: ColorScheme) -> Color {
        if activeThemeID == .halloween2026 {
            return scheme == .dark ? surface0 : Color(hex: "F4E9E1")
        }
        return scheme == .dark ? surface0 : Color(hex: "F4F4F8")
    }
    static func quaternary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textQuaternary : Color(hex: "0A0A0B").opacity(0.24)
    }

    /// Full-screen "premium" backdrop used by Paywall and post-value
    /// onboarding surfaces. In dark mode it keeps the deep privacy-navy
    /// identity; in light mode it becomes a soft, readable gradient so the
    /// surface no longer "ignores" the appearance setting.
    static func premiumBackground(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark
            ? [surface0, surface2]
            : [Color(hex: "F4F4F8"), Color.white]
    }

    /// Selection/affordance highlight for canvas overlays. Yellow reads
    /// clearly over the dark render surface; a deeper amber keeps contrast
    /// in light mode where documents render on white.
    static func selection(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FFD60A") : Color(hex: "B8860B")
    }
}

// MARK: - Motion

enum ShieldMotion {
    static let fast: Double = 0.12
    static let standard: Double = 0.22
    static let contextual: Double = 0.36

    static let press = Animation.easeOut(duration: fast)
    static let state = Animation.smooth(duration: standard)
    static let navigation = Animation.spring(duration: contextual, bounce: 0.08)
}

// MARK: - Color(hex:)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography (Dynamic Type aware)

/// Base sizes for the Shield type scale. These are the design's default
/// point sizes at the system's default content size category; `shieldFont`
/// scales them with the user's Dynamic Type preference.
enum ShieldTypeSize {
    static let micro: CGFloat = 9
    static let caption: CGFloat = 11
    static let captionMid: CGFloat = 12
    static let footnote: CGFloat = 13
    static let subheadline: CGFloat = 14
    static let callout: CGFloat = 15
    static let body: CGFloat = 16
    static let headline: CGFloat = 17
    static let title3: CGFloat = 20
    static let title2: CGFloat = 22
    static let title1: CGFloat = 28
    static let display: CGFloat = 34
}

/// Applies a fixed-layout font size as a Dynamic Type-aware token. The view
/// is re-evaluated when the user changes the system text size, keeping the
/// identical visual design at the default size while honoring accessibility
/// Large/Accessibility sizes. Canvas/output renderers must keep using
/// `.system(size:)` so exported documents never depend on device settings.
struct ShieldFontModifier: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var dynamicSize: CGFloat = 14
    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        let legibleSize = max(size, 10)
        _dynamicSize = ScaledMetric(
            wrappedValue: legibleSize,
            relativeTo: ShieldTypeSize.relativeStyle(for: legibleSize)
        )
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        let resolvedDesign: Font.Design =
            ShieldTheme.activeThemeID == .halloween2026 && design == .default
                ? .rounded
                : design
        content.font(.system(size: dynamicSize, weight: weight, design: resolvedDesign))
    }
}

extension ShieldTypeSize {
    static func relativeStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12: .caption2
        case ..<14: .footnote
        case ..<16: .subheadline
        case ..<18: .body
        case ..<21: .headline
        case ..<24: .title3
        case ..<30: .title2
        default: .largeTitle
        }
    }
}

extension View {
    /// Substitutes the (non-scaling) `.system(size:weight:design:)` pattern
    /// with a Dynamic Type-aware equivalent.
    func shieldFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ShieldFontModifier(size: size, weight: weight, design: design))
    }
}

// MARK: - View modifiers

struct ShieldCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                reduceTransparency
                    ? ShieldTheme.elevatedBackground(scheme)
                    : ShieldTheme.cardBackground(scheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .stroke(
                        contrast == .increased
                            ? ShieldTheme.strongLine(scheme)
                            : ShieldTheme.line(scheme),
                        lineWidth: contrast == .increased ? 1 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
            .shadow(
                color: Color.black.opacity(scheme == .dark ? 0.12 : 0.07),
                radius: 8,
                y: 3
            )
    }
}

extension View {
    func shieldCard() -> some View {
        modifier(ShieldCardStyle())
    }
}

// MARK: - URL helper

extension URL {
    func loadImage() -> UIImage? {
        SecureFileStore.shared.loadImage(from: self)
    }
}
