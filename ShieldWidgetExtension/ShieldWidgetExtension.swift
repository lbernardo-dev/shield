import AppIntents
import SwiftUI
import WidgetKit

struct ShieldWidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: ShieldWidgetSnapshot
}

struct ShieldWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShieldWidgetEntry {
        ShieldWidgetEntry(date: .now, snapshot: .init(
            totalDocuments: 12,
            protectedDocuments: 9,
            vaultedDocuments: 3
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

struct ShieldWidgetOpenCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Protect a Document"
    static let description = IntentDescription("Open MaskID ready to import, scan, or photograph a document.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await ShieldSystemRequestStore.request(.openCapture)
        return .result()
    }
}

struct ShieldProtectionStatusWidget: Widget {
    let kind = "ShieldProtectionStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShieldWidgetProvider()) { entry in
            ShieldProtectionStatusWidgetView(snapshot: entry.snapshot)
                .widgetURL(URL(string: "shield://capture"))
        }
        .configurationDisplayName("Protection Status")
        .description("See your protected-document totals without exposing document contents.")
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
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.12, blue: 0.20), Color(red: 0.01, green: 0.03, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .privacySensitive()
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Protected", systemImage: "checkmark.shield.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.cyan)

            Text("\(snapshot.protectedDocuments)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text("documents")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))

            Spacer(minLength: 0)

            Button(intent: ShieldWidgetOpenCaptureIntent()) {
                Label("Protect", systemImage: "camera.viewfinder")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .padding(14)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 3) {
                Text("Protection status")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(snapshot.protectedDocuments) protected of \(snapshot.totalDocuments)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                Text("\(snapshot.vaultedDocuments) in secure Vault")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.60))
            }

            Spacer(minLength: 4)

            Button(intent: ShieldWidgetOpenCaptureIntent()) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .accessibilityLabel("Protect a document")
        }
        .padding(16)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Protection status", systemImage: "checkmark.shield.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.cyan)
                Spacer()
                Text(snapshot.generatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }

            HStack(spacing: 10) {
                metric(value: snapshot.totalDocuments, label: "Documents")
                metric(value: snapshot.protectedDocuments, label: "Protected")
                metric(value: snapshot.vaultedDocuments, label: "Vault")
            }

            Spacer(minLength: 0)

            Button(intent: ShieldWidgetOpenCaptureIntent()) {
                Label("Protect a document", systemImage: "camera.viewfinder")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .padding(18)
    }

    private func metric(value: Int, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var circularView: some View {
        Gauge(value: Double(snapshot.protectedDocuments), in: 0...Double(max(snapshot.totalDocuments, 1))) {
            Image(systemName: "checkmark.shield.fill")
        } currentValueLabel: {
            Text("\(snapshot.protectedDocuments)")
                .font(.headline.weight(.bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(.cyan)
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.cyan)
            VStack(alignment: .leading) {
                Text("Protected")
                    .font(.headline)
                Text("\(snapshot.protectedDocuments) of \(snapshot.totalDocuments) documents")
                    .font(.caption2)
            }
        }
    }

    private var inlineView: some View {
        Text("\(snapshot.protectedDocuments) protected documents")
    }
}

@main
struct ShieldWidgetExtension: WidgetBundle {
    var body: some Widget {
        ShieldProtectionStatusWidget()
    }
}
