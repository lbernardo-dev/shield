import SwiftUI

struct CaptureMenuView: View {
    @Environment(\.colorScheme) private var scheme
    let bottomInset: CGFloat
    let selectedScanType: ScanDocumentType
    let showGuide: Bool
    let onClose: () -> Void
    let onToggleGuide: () -> Void
    let onSelectScanType: (ScanDocumentType) -> Void
    let onScan: () -> Void
    let onPhotos: () -> Void
    let onFiles: () -> Void
    let onCloud: () -> Void

    private var introEyebrow: String {
        LanguageManager.shared.capture("capture_menu_eyebrow")
    }

    private var introTitle: String {
        LanguageManager.shared.capture("capture_menu_title")
    }

    private var introSubtitle: String {
        LanguageManager.shared.capture("capture_menu_subtitle")
    }

    private var scanHeroSubtitle: String {
        LanguageManager.shared.capture("capture_guide_frame", selectedScanType.label())
    }

    private var guideStateLabel: String {
        showGuide
            ? LanguageManager.shared.capture("capture_hide_guide")
            : LanguageManager.shared.capture("capture_show_guide")
    }

    private var guideStateDescription: String {
        if showGuide {
            return LanguageManager.shared.capture("capture_guide_visible_desc")
        }
        return LanguageManager.shared.capture("capture_guide_free_desc")
    }

    private var importSectionTitle: String {
        LanguageManager.shared.capture("capture_other_sources_title")
    }

    private var importSectionSubtitle: String {
        LanguageManager.shared.capture("capture_other_sources_subtitle")
    }

    var body: some View {
        VStack(spacing: 0) {
            CaptureTopBarView(
                subtitle: introSubtitle,
                onClose: onClose
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    CapturePrimaryScanCard(
                        title: LanguageManager.shared.capture("capture_scan_document"),
                        subtitle: scanHeroSubtitle,
                        selectedType: selectedScanType,
                        showGuide: showGuide,
                        onToggleGuide: onToggleGuide,
                        onScan: onScan
                    )

                    CaptureTypeSectionCard(
                        selectedScanType: selectedScanType,
                        showGuide: showGuide,
                        guideStateDescription: guideStateDescription,
                        onToggleGuide: onToggleGuide,
                        onSelectScanType: onSelectScanType
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(importSectionTitle)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(ShieldTheme.primary(scheme))

                        Text(importSectionSubtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ShieldTheme.secondary(scheme))

                        VStack(spacing: 12) {
                            CaptureSecondarySourceCard(
                                icon: "photo.on.rectangle.angled",
                                title: LanguageManager.shared.capture("capture_from_photos"),
                                subtitle: LanguageManager.shared.capture("capture_pick_images"),
                                accent: Color(hex: "7DD3FC"),
                                action: onPhotos
                            )

                            CaptureSecondarySourceCard(
                                icon: "folder.badge.person.crop",
                                title: LanguageManager.shared.capture("capture_from_files"),
                                subtitle: LanguageManager.shared.capture("capture_files_subtitle"),
                                accent: Color(hex: "A78BFA"),
                                action: onFiles
                            )

                            CaptureSecondarySourceCard(
                                icon: "icloud.and.arrow.down.fill",
                                title: LanguageManager.shared.capture("capture_from_cloud"),
                                subtitle: "Google Drive, Dropbox",
                                accent: Color(hex: "34D399"),
                                action: onCloud
                            )
                        }
                    }

                    CapturePrivacyCard(
                        title: LanguageManager.shared.home("home_on_device"),
                        subtitle: LanguageManager.shared.capture("capture_on_device_privacy")
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, max(24, bottomInset + 12))
            }
        }
        .background(ShieldTheme.pageBackground(scheme))
    }
}

private struct CaptureTopBarView: View {
    @Environment(\.colorScheme) private var scheme
    let subtitle: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .frame(width: 42, height: 42)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LanguageManager.shared.capture("capture_add_document"))
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, ShieldTheme.topChromePadding)
        .padding(.bottom, ShieldTheme.topChromeBottomSpacing)
        .background(ShieldTheme.pageBackground(scheme))
    }
}

private struct CapturePrimaryScanCard: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String
    let selectedType: ScanDocumentType
    let showGuide: Bool
    let onToggleGuide: () -> Void
    let onScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ShieldTheme.accent)
                        .frame(width: 48, height: 48)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(ShieldTheme.accentText)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(ShieldTheme.primary(scheme))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                scanBadge(icon: selectedType.icon, label: selectedType.label())
                scanBadge(
                    icon: showGuide ? "viewfinder.circle.fill" : "crop",
                    label: showGuide
                        ? LanguageManager.shared.capture("capture_hide_guide")
                        : LanguageManager.shared.capture("capture_show_guide")
                )
            }

            Button(action: onScan) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.metering.center.weighted")
                        .font(.system(size: 15, weight: .bold))
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(ShieldTheme.accentText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 16)
                .background(ShieldTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(hex: "2A2410"), Color(hex: "17171D")]
                    : [Color(hex: "FFF4BF"), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ShieldTheme.accent.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func scanBadge(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(ShieldTheme.primary(scheme))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(ShieldTheme.rowBackground(scheme))
        .overlay(Capsule().stroke(ShieldTheme.line(scheme), lineWidth: 0.8))
        .clipShape(Capsule())
    }
}

private struct CaptureTypeSectionCard: View {
    @Environment(\.colorScheme) private var scheme
    let selectedScanType: ScanDocumentType
    let showGuide: Bool
    let guideStateDescription: String
    let onToggleGuide: () -> Void
    let onSelectScanType: (ScanDocumentType) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LanguageManager.shared.capture("capture_document_type"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                Spacer()
                Button(action: onToggleGuide) {
                    HStack(spacing: 6) {
                        Image(systemName: showGuide ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(showGuide
                             ? LanguageManager.shared.capture("capture_hide_guide")
                             : LanguageManager.shared.capture("capture_show_guide"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ScanDocumentType.allCases) { type in
                    CaptureTypeChip(
                        type: type,
                        isSelected: selectedScanType == type,
                        onSelect: { onSelectScanType(type) }
                    )
                }
            }

            HStack(spacing: 10) {
                Image(systemName: showGuide ? "viewfinder" : "square.dashed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ShieldTheme.info)

                Text(guideStateDescription)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.secondary(scheme))
            }
        }
        .padding(18)
        .background(ShieldTheme.cardBackground(scheme))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct CaptureTypeChip: View {
    @Environment(\.colorScheme) private var scheme
    let type: ScanDocumentType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 15, weight: .bold))
                Text(type.label())
                    .font(.system(size: 12, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(isSelected ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(isSelected ? ShieldTheme.accent : ShieldTheme.rowBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.line(scheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct CaptureSecondarySourceCard: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accent.opacity(0.16))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(scheme))

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            .padding(16)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct CapturePrivacyCard: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ShieldTheme.successDim)
                    .frame(width: 44, height: 44)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShieldTheme.success)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "101513"))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ShieldTheme.success.opacity(0.18), lineWidth: 0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
