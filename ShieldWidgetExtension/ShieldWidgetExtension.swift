import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Theme & Design Tokens

enum WidgetTheme {
    static let bgTop = Color(red: 0.03, green: 0.07, blue: 0.14)
    static let bgBottom = Color(red: 0.01, green: 0.03, blue: 0.06)
    static let cyan = Color(red: 0.125, green: 0.78, blue: 0.85)
    static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let amber = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let purple = Color(red: 0.66, green: 0.33, blue: 0.97)
    static let cardFill = Color.white.opacity(0.07)
    static let cardStroke = Color.white.opacity(0.12)
}

// MARK: - App Intents

struct ShieldWidgetOpenCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Protect a Document"
    static let description = IntentDescription("Open MaskID ready to import, scan, or photograph a document.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await ShieldSystemRequestStore.request(.openCapture)
        return .result()
    }
}

struct ShieldWidgetOpenVaultIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Vault"
    static let description = IntentDescription("Quickly access MaskID's encrypted vault.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await ShieldSystemRequestStore.request(.openVault)
        return .result()
    }
}

struct ShieldWidgetOpenPresetIntent: AppIntent {
    static let title: LocalizedStringResource = "Apply Preset"
    static let description = IntentDescription("Open MaskID with a specific protection preset.")
    static let openAppWhenRun = true

    @Parameter(title: "Preset")
    var preset: String

    init() {
        self.preset = "verify"
    }

    init(preset: String) {
        self.preset = preset
    }

    func perform() async throws -> some IntentResult {
        if preset == "job" {
            await ShieldSystemRequestStore.request(.presetJob)
        } else if preset == "rental" {
            await ShieldSystemRequestStore.request(.presetRental)
        } else {
            await ShieldSystemRequestStore.request(.presetVerify)
        }
        return .result()
    }
}

// MARK: - Timeline Provider & Entry

struct ShieldWidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: ShieldWidgetSnapshot
}

struct ShieldWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShieldWidgetEntry {
        ShieldWidgetEntry(date: .now, snapshot: .init(
            totalDocuments: 12,
            documentsWithRedactions: 9,
            vaultedDocuments: 3,
            watermarkedDocuments: 4
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (ShieldWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? placeholder(in: context).snapshot : ShieldWidgetSnapshotStore.load()
        completion(ShieldWidgetEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShieldWidgetEntry>) -> Void) {
        let snapshot = ShieldWidgetSnapshotStore.load()
        let entry = ShieldWidgetEntry(date: .now, snapshot: snapshot)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3_600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - Widget 1: Quick Actions (Operative)

struct MaskIDQuickActionsWidget: Widget {
    let kind = "MaskIDQuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShieldWidgetProvider()) { entry in
            MaskIDQuickActionsView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("MaskID Quick Actions")
        .description("One-tap shortcuts for ID, payroll, rental, and Vault workflows.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

private struct MaskIDQuickActionsView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: ShieldWidgetSnapshot

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            default:
                mediumView
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .privacySensitive()
    }

    private var widgetBackground: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetTheme.bgTop, WidgetTheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [WidgetTheme.cyan.opacity(0.12), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 160
            )
        }
    }

    // Small: 2 Quick Action Cards + Header
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(WidgetTheme.cyan)
                    .font(.caption.weight(.bold))
                    .widgetAccentable()
                Text("MaskID")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                if snapshot.hasPremiumAccess {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(WidgetTheme.amber)
                        .accessibilityHidden(true)
                }
                Spacer()
                HStack(spacing: 3) {
                    Circle()
                        .fill(WidgetTheme.emerald)
                        .frame(width: 5, height: 5)
                    Text("On-device processing")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WidgetTheme.emerald)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(WidgetTheme.emerald.opacity(0.12))
                .clipShape(Capsule())
            }

            VStack(spacing: 6) {
                Button(intent: ShieldWidgetOpenPresetIntent(preset: "verify")) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(WidgetTheme.cyan.opacity(0.20))
                                .frame(width: 28, height: 28)
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(WidgetTheme.cyan)
                                .widgetAccentable()
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("DNI / ID")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Protect")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WidgetTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(WidgetTheme.cardStroke, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(intent: ShieldWidgetOpenPresetIntent(preset: "rental")) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(WidgetTheme.amber.opacity(0.20))
                                .frame(width: 28, height: 28)
                            Image(systemName: "house.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(WidgetTheme.amber)
                                .widgetAccentable()
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Rental / Lease")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Watermarks")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WidgetTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(WidgetTheme.cardStroke, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
    }

    // Medium: 4-Action Grid
    private var mediumView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(WidgetTheme.cyan)
                        .font(.subheadline.weight(.bold))
                        .widgetAccentable()
                    Text("MaskID")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    if snapshot.hasPremiumAccess {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(WidgetTheme.amber)
                            .accessibilityHidden(true)
                    }
                    Text("•")
                        .foregroundStyle(.white.opacity(0.40))
                    Text("Quick Actions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.cyan)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                actionColumn(
                    intent: ShieldWidgetOpenPresetIntent(preset: "verify"),
                    icon: "person.text.rectangle.fill",
                    color: WidgetTheme.cyan,
                    title: "DNI / ID"
                )
                actionColumn(
                    intent: ShieldWidgetOpenPresetIntent(preset: "job"),
                    icon: "briefcase.fill",
                    color: WidgetTheme.amber,
                    title: "Payroll"
                )
                actionColumn(
                    intent: ShieldWidgetOpenPresetIntent(preset: "rental"),
                    icon: "house.fill",
                    color: Color(red: 0.22, green: 0.74, blue: 0.97),
                    title: "Rental / Lease"
                )
                actionColumn(
                    intent: ShieldWidgetOpenVaultIntent(),
                    icon: "lock.shield.fill",
                    color: WidgetTheme.purple,
                    title: "Vault"
                )
            }
        }
        .padding(14)
    }

    private func actionColumn(
        intent: some AppIntent,
        icon: String,
        color: Color,
        title: LocalizedStringKey
    ) -> some View {
        Button(intent: intent) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(color)
                        .widgetAccentable()
                }

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(WidgetTheme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(WidgetTheme.cardStroke, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget 2: Library Overview (Informative)

struct ShieldProtectionStatusWidget: Widget {
    let kind = "ShieldProtectionStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShieldWidgetProvider()) { entry in
            ShieldProtectionStatusWidgetView(snapshot: entry.snapshot)
                .widgetURL(URL(string: "shield://library"))
        }
        .configurationDisplayName("Library Overview")
        .description("See local counts for documents, redactions, watermarks, and Vault.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

private struct ShieldProtectionStatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: ShieldWidgetSnapshot

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge, .systemExtraLarge:
                largeView
            case .accessoryCircular:
                circularView
            case .accessoryRectangular:
                rectangularView
            case .accessoryInline:
                inlineView
            default:
                smallView
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .privacySensitive()
    }

    private var widgetBackground: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetTheme.bgTop, WidgetTheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [WidgetTheme.cyan.opacity(0.12), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )
        }
    }

    // Small: library count, scope, and a direct add action.
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Library Overview", systemImage: "checkmark.shield.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WidgetTheme.cyan)
                    .widgetAccentable()
                Spacer()
                Button(intent: ShieldWidgetOpenCaptureIntent()) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(WidgetTheme.cyan.opacity(0.30))
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add document")
                .accessibilityHint("Open MaskID's scan and import options.")
            }

            Spacer(minLength: 0)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(snapshot.documentsWithRedactions)")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                if snapshot.totalDocuments > 0 {
                    Text("/ \(snapshot.totalDocuments)")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            Text(snapshot.totalDocuments > 0 ? "Documents with redactions" : "No documents yet")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Mini Progress Bar
            GeometryReader { proxy in
                let width = proxy.size.width
                let ratio = snapshot.totalDocuments > 0
                    ? Double(snapshot.documentsWithRedactions) / Double(snapshot.totalDocuments)
                    : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [WidgetTheme.cyan, WidgetTheme.emerald],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * ratio, height: 5)
                }
            }
            .frame(height: 6)

            Text("Processed on device")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WidgetTheme.emerald)
        }
        .padding(13)
    }

    // Medium: four factual library counts.
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Library Overview", systemImage: "checkmark.shield.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WidgetTheme.cyan)
                .widgetAccentable()

            if snapshot.totalDocuments == 0 {
                Label("No documents yet", systemImage: "doc.on.doc")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    metricCard(icon: "doc.on.doc.fill", color: .white.opacity(0.85), count: snapshot.totalDocuments, label: "Documents")
                    metricCard(icon: "rectangle.slash", color: WidgetTheme.cyan, count: snapshot.documentsWithRedactions, label: "With redactions")
                    metricCard(icon: "drop.fill", color: WidgetTheme.amber, count: snapshot.watermarkedDocuments, label: "Watermarked")
                    metricCard(icon: "lock.shield.fill", color: WidgetTheme.purple, count: snapshot.vaultedDocuments, label: "In Vault")
                }
            }
        }
        .padding(14)
    }

    private func metricCard(icon: String, color: Color, count: Int, label: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.18))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .widgetAccentable()
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(WidgetTheme.cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(WidgetTheme.cardStroke, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // Large: Privacy Dashboard + Tip + Quick Action Footers
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Library Overview", systemImage: "checkmark.shield.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WidgetTheme.cyan)
                    .widgetAccentable()
                Spacer()
                Text("Processed on device")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WidgetTheme.emerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(WidgetTheme.emerald.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Top Metrics Grid
            if snapshot.totalDocuments == 0 {
                Label("No documents yet", systemImage: "doc.on.doc")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    largeMetricCard(
                        icon: "doc.on.doc.fill",
                        color: .white.opacity(0.85),
                        value: snapshot.totalDocuments,
                        label: "Documents"
                    )
                    largeMetricCard(
                        icon: "rectangle.slash",
                        color: WidgetTheme.cyan,
                        value: snapshot.documentsWithRedactions,
                        label: "With redactions"
                    )
                    largeMetricCard(
                        icon: "drop.fill",
                        color: WidgetTheme.amber,
                        value: snapshot.watermarkedDocuments,
                        label: "Watermarked"
                    )
                    largeMetricCard(
                        icon: "lock.shield.fill",
                        color: WidgetTheme.purple,
                        value: snapshot.vaultedDocuments,
                        label: "In Vault"
                    )
                }
            }

            // Privacy Tip Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WidgetTheme.amber)
                    Text("Privacy Tip")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WidgetTheme.amber)
                }
                Text("For each recipient, mask only the fields they do not need. Add a purpose and date to the watermark.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(WidgetTheme.amber.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(WidgetTheme.amber.opacity(0.25), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Spacer(minLength: 0)

            // Action Buttons
            HStack(spacing: 10) {
                Button(intent: ShieldWidgetOpenPresetIntent(preset: "verify")) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.caption.weight(.bold))
                        Text("Protect ID")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(WidgetTheme.cyan)

                Button(intent: ShieldWidgetOpenVaultIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption.weight(.bold))
                        Text("Open Vault")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .padding(16)
    }

    private func largeMetricCard(icon: String, color: Color, value: Int, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .widgetAccentable()
            Text("\(value)")
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(WidgetTheme.cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(WidgetTheme.cardStroke, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // Lock Screen Circular: the value counts documents with redactions.
    private var circularView: some View {
        Gauge(value: Double(snapshot.documentsWithRedactions), in: 0...Double(max(snapshot.totalDocuments, 1))) {
            Image(systemName: "rectangle.slash")
        } currentValueLabel: {
            Text("\(snapshot.documentsWithRedactions)")
                .font(.headline.weight(.bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(WidgetTheme.cyan)
        .accessibilityLabel("Documents with redactions")
    }

    // Lock Screen Rectangular
    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.slash")
                .font(.title2.weight(.bold))
                .foregroundStyle(WidgetTheme.cyan)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 2) {
                Text("MaskID")
                    .font(.caption.weight(.heavy))
                Text("With redactions")
                    .font(.caption2)
                Text("\(snapshot.documentsWithRedactions) / \(snapshot.totalDocuments)")
                    .font(.caption2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // Lock Screen Inline
    private var inlineView: some View {
        Label("\(snapshot.documentsWithRedactions) with redactions", systemImage: "rectangle.slash")
    }
}

// MARK: - iOS 18 Control Widgets (Control Center & Lock Screen Controls)

@available(iOS 18.0, *)
struct MaskIDProtectControl: ControlWidget {
    static let kind = "com.romerodev.shield.protect-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: ShieldWidgetOpenCaptureIntent()) {
                Label("Protect Document", systemImage: "checkmark.shield.fill")
            }
        }
        .displayName("Protect Document")
        .description("Quickly open MaskID to protect a document.")
    }
}

@available(iOS 18.0, *)
struct MaskIDVaultControl: ControlWidget {
    static let kind = "com.romerodev.shield.vault-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: ShieldWidgetOpenVaultIntent()) {
                Label("Open Vault", systemImage: "lock.shield.fill")
            }
        }
        .displayName("Open Vault")
        .description("Quickly access MaskID's encrypted vault.")
    }
}

// MARK: - Widget Bundle Entrypoint

@main
struct ShieldWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        ShieldProtectionStatusWidget()
        MaskIDQuickActionsWidget()
        if #available(iOS 18.0, *) {
            MaskIDProtectControl()
            MaskIDVaultControl()
        }
    }
}
