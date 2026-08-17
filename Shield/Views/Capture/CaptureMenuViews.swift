import SwiftUI

struct CaptureMenuView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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

    private var introSubtitle: String {
        LanguageManager.shared.capture("capture_menu_subtitle")
    }

    private var scanHeroSubtitle: String {
        LanguageManager.shared.capture("capture_guide_frame", selectedScanType.label())
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

    var body: some View {
        VStack(spacing: 0) {
            CaptureTopBarView(
                subtitle: introSubtitle,
                onClose: onClose
            )

            ScrollView(showsIndicators: false) {
                Group {
                    if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: 18) {
                            primaryScanCard
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: 18) {
                                sourceSection
                                typeSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 18) {
                            primaryScanCard
                            sourceSection
                            typeSection
                        }
                    }
                }
                .frame(maxWidth: ShieldTheme.workspaceWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, max(24, bottomInset + 12))
            }
        }
        .background(ShieldTheme.pageBackground(scheme))
        .sensoryFeedback(.selection, trigger: selectedScanType)
    }

    private var primaryScanCard: some View {
        CapturePrimaryScanCard(
            title: LanguageManager.shared.capture("capture_scan_document"),
            subtitle: scanHeroSubtitle,
            selectedType: selectedScanType,
            showGuide: showGuide,
            onToggleGuide: onToggleGuide,
            onScan: onScan
        )
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(importSectionTitle)
                .font(.headline)
                .foregroundColor(ShieldTheme.primary(scheme))

            HStack(spacing: 10) {
                CaptureSourceButton(icon: "photo.on.rectangle.angled", title: LanguageManager.shared.capture("capture_from_photos"), accent: Color(hex: "7DD3FC"), action: onPhotos)
                CaptureSourceButton(icon: "folder.badge.person.crop", title: LanguageManager.shared.capture("capture_from_files"), accent: Color(hex: "A78BFA"), action: onFiles)
                CaptureSourceButton(icon: "icloud.and.arrow.down.fill", title: LanguageManager.shared.capture("capture_from_cloud"), accent: Color(hex: "34D399"), action: onCloud)
            }
        }
    }

    private var typeSection: some View {
        CaptureTypeSectionCard(
            selectedScanType: selectedScanType,
            showGuide: showGuide,
            guideStateDescription: guideStateDescription,
            onToggleGuide: onToggleGuide,
            onSelectScanType: onSelectScanType
        )
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
                    .shieldFont(16, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .frame(width: 44, height: 44)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("capture.close")
            .accessibilityLabel(LanguageManager.shared.common("common_close"))

            VStack(alignment: .leading, spacing: 2) {
                Text(LanguageManager.shared.capture("capture_add_document"))
                    .shieldFont(17, weight: .heavy)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(subtitle)
                    .shieldFont(11, weight: .medium)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ShieldTheme.accent)
                        .frame(width: 48, height: 48)

                    Image(systemName: "camera.viewfinder")
                        .shieldFont(21, weight: .bold)
                        .foregroundColor(ShieldTheme.accentText)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .shieldFont(17, weight: .heavy)
                        .foregroundColor(ShieldTheme.primary(scheme))

                    Text(subtitle)
                        .shieldFont(12, weight: .medium)
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

            ShieldButton(
                label: LanguageManager.shared.home("home_scan_action"),
                icon: "camera.metering.center.weighted",
                action: onScan
            )
            .accessibilityIdentifier("capture.scan")
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
                .shieldFont(11, weight: .bold)
            Text(label)
                .shieldFont(11, weight: .bold)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LanguageManager.shared.capture("capture_document_type"))
                    .shieldFont(12, weight: .bold)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                Spacer()
                Button(action: onToggleGuide) {
                    HStack(spacing: 6) {
                        Image(systemName: showGuide ? "eye.slash.fill" : "eye.fill")
                            .shieldFont(11, weight: .bold)
                        Text(showGuide
                             ? LanguageManager.shared.capture("capture_hide_guide")
                             : LanguageManager.shared.capture("capture_show_guide"))
                            .shieldFont(11, weight: .bold)
                    }
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityIdentifier("capture.toggleGuide")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScanDocumentType.allCases) { type in
                        PillButton(
                            label: type.label(),
                            icon: type.icon,
                            isActive: selectedScanType == type
                        ) {
                            onSelectScanType(type)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: showGuide ? "viewfinder" : "square.dashed")
                    .shieldFont(12, weight: .bold)
                    .foregroundColor(ShieldTheme.info)

                Text(guideStateDescription)
                    .shieldFont(12, weight: .medium)
                    .foregroundColor(ShieldTheme.secondary(scheme))
            }
        }
        .padding(14)
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
                    .shieldFont(15, weight: .bold)
                Text(type.label())
                    .shieldFont(12, weight: .bold)
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

private struct CaptureSourceButton: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(accent)
                    .frame(width: 44, height: 44)
                    .background(accent.opacity(0.14), in: .rect(cornerRadius: 12))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 94)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            )
            .clipShape(.rect(cornerRadius: 16))
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
            MaskIDIdentityMark(
                size: 44,
                presentation: .staticMark,
                treatment: .compact
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .shieldFont(15, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(scheme))

                Text(subtitle)
                    .shieldFont(12, weight: .medium)
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
