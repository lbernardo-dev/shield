import SwiftUI

enum HomeLibraryMetric: String, CaseIterable {
  case documents
  case redacted
  case vaulted
  case watermarked

  var localizationKey: String {
    switch self {
    case .documents: "home_metric_documents"
    case .redacted: "home_metric_redacted"
    case .vaulted: "home_metric_vault"
    case .watermarked: "home_metric_watermarked"
    }
  }

  var icon: String {
    switch self {
    case .documents: "doc.text.fill"
    case .redacted: "rectangle.slash"
    case .vaulted: "lock.fill"
    case .watermarked: "drop.halffull"
    }
  }

  func includes(_ document: DocumentItem) -> Bool {
    switch self {
    case .documents: true
    case .redacted: document.redactionCount > 0 || document.totalRedactionCount > 0
    case .vaulted: document.isVaulted
    case .watermarked:
      document.watermark?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
  }
}

struct HomeLibraryStatisticsView: View {
  let documentCount: Int
  let redactedDocumentCount: Int
  let vaultDocumentCount: Int
  let watermarkedDocumentCount: Int
  let scheme: ColorScheme
  let language: AppLanguage
  let onSelect: (HomeLibraryMetric) -> Void

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private var columns: [GridItem] {
    let count: Int
    if dynamicTypeSize.isAccessibilitySize {
      count = 1
    } else if horizontalSizeClass == .regular {
      count = 4
    } else {
      count = 2
    }
    return Array(repeating: GridItem(.flexible(), spacing: ShieldTheme.s2), count: count)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: ShieldTheme.s3) {
      HStack(alignment: .center) {
        HStack(spacing: 6) {
          Image(systemName: "chart.bar.xaxis")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(ShieldTheme.accentColor(scheme))
          Text(LanguageManager.shared.home("home_library_summary"))
            .shieldFont(16, weight: .bold)
            .foregroundStyle(ShieldTheme.primary(scheme))
        }
        Spacer()
        HStack(spacing: 4) {
          Image(systemName: "lock.shield.fill")
            .font(.caption2.weight(.bold))
          Text(language == .es ? "Cifrado Local" : "Local Vault")
            .shieldFont(11, weight: .semibold)
        }
        .foregroundStyle(ShieldTheme.secondary(scheme))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(ShieldTheme.rowBackground(scheme), in: Capsule())
      }
      .padding(.horizontal, ShieldTheme.s1)

      LazyVGrid(columns: columns, alignment: .leading, spacing: ShieldTheme.s2) {
        metric(
          .documents,
          value: documentCount,
          isEnabled: true
        )
        metric(
          .redacted,
          value: redactedDocumentCount,
          isEnabled: redactedDocumentCount > 0
        )
        metric(
          .vaulted,
          value: vaultDocumentCount,
          isEnabled: vaultDocumentCount > 0
        )
        metric(
          .watermarked,
          value: watermarkedDocumentCount,
          isEnabled: watermarkedDocumentCount > 0
        )
      }
    }
    .padding(ShieldTheme.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      ShieldTheme.cardBackground(scheme),
      in: RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
        .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
    }
    .padding(.horizontal, ShieldTheme.s5)
  }

  private var metricColors: [HomeLibraryMetric: Color] {
    [
      .documents: Color(hex: "38BDF8"),  // Azure Sky
      .redacted: Color(hex: "F43F5E"),  // Neon Rose
      .vaulted: Color(hex: "6366F1"),  // Cyber Violet
      .watermarked: Color(hex: "06B6D4"),  // Aqua Cyan
    ]
  }

  private func metric(_ metric: HomeLibraryMetric, value: Int, isEnabled: Bool) -> some View {
    let tint = metricColors[metric] ?? ShieldTheme.accentColor(scheme)
    return Button {
      onSelect(metric)
    } label: {
      VStack(alignment: .leading, spacing: ShieldTheme.s2) {
        HStack(spacing: ShieldTheme.s2) {
          ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(tint.opacity(scheme == .dark ? 0.22 : 0.14))
              .frame(width: 28, height: 28)
            Image(systemName: metric.icon)
              .font(.caption.weight(.bold))
              .foregroundStyle(tint)
          }

          Text(LanguageManager.shared.home(metric.localizationKey))
            .shieldFont(12, weight: .medium)
            .foregroundStyle(ShieldTheme.secondary(scheme))
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
        }

        Text(value.formatted(.number.locale(Locale(identifier: language.rawValue))))
          .shieldFont(24, weight: .heavy, design: .rounded)
          .foregroundStyle(ShieldTheme.primary(scheme))
          .contentTransition(.numericText())
      }
      .frame(
        maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : 64,
        alignment: .leading
      )
      .padding(.horizontal, ShieldTheme.s3)
      .padding(.vertical, ShieldTheme.s2)
      .background(
        ZStack {
          ShieldTheme.rowBackground(scheme)
          LinearGradient(
            colors: [
              tint.opacity(scheme == .dark ? 0.12 : 0.06),
              tint.opacity(scheme == .dark ? 0.02 : 0.005),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
      )
      .overlay(
        RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
          .stroke(
            LinearGradient(
              colors: [
                tint.opacity(scheme == .dark ? 0.40 : 0.28),
                ShieldTheme.line(scheme).opacity(0.35),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 0.8
          )
      )
      .contentShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
    }
    .buttonStyle(ScaleButtonStyle())
    .disabled(!isEnabled)
    .accessibilityLabel("\(LanguageManager.shared.home(metric.localizationKey)), \(value)")
    .accessibilityHint(isEnabled ? LanguageManager.shared.home("home_metric_open_hint") : "")
  }
}

struct HomeToolbarBrandLabel: View {
  let scheme: ColorScheme
  let isHalloween: Bool

  var body: some View {
    horizontalBrand
  }

  private var horizontalBrand: some View {
    HStack(spacing: 9) {
      MaskIDIdentityMark(size: 42, presentation: .staticMark, treatment: .compact)
      Text(LanguageManager.shared.common("common_app_name"))
        .shieldFont(22, weight: .heavy)
        .foregroundStyle(ShieldTheme.primary(scheme))
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
      if isHalloween {
        Text("🎃")
          .font(.system(size: 16))
          .accessibilityHidden(true)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(LanguageManager.shared.common("common_app_name"))
    .accessibilityIdentifier("home.toolbar.brand")
    .fixedSize(horizontal: true, vertical: false)
  }
}

struct HomeProfileToolbarButton: View {
  let scheme: ColorScheme
  let onToggleLanguage: () -> Void
  let onToggleScheme: () -> Void
  let onOpenSettings: () -> Void

  @EnvironmentObject private var appState: AppState
  @ObservedObject private var profileManager = UserProfileManager.shared
  @State private var showProfileSheet = false

  private var isHalloween: Bool {
    ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
  }

  var body: some View {
    Button {
      showProfileSheet = true
    } label: {
      avatar
        .contentShape(Circle())
    }
    .buttonStyle(ScaleButtonStyle())
    .accessibilityLabel(LanguageManager.shared.settings("settings_profile_title"))
    .accessibilityHint(LanguageManager.shared.home("home_account_menu_hint"))
    .accessibilityIdentifier("home.toolbar.profile")
    .contextMenu {
      Button(action: { showProfileSheet = true }) {
        Label(
          LanguageManager.shared.settings("settings_profile_title"),
          systemImage: "person.crop.circle")
      }

      Button(action: onToggleLanguage) {
        Label(
          LanguageManager.shared.settings("settings_language"), systemImage: "character.book.closed"
        )
      }

      Button(action: onToggleScheme) {
        Label(
          LanguageManager.shared.settings("settings_dark_mode"),
          systemImage: scheme == .dark ? "sun.max.fill" : "moon.fill")
      }

      Button(action: onOpenSettings) {
        Label(LanguageManager.shared.common("common_tab_settings"), systemImage: "gearshape")
      }
    }
    .sheet(isPresented: $showProfileSheet) {
      UserProfileView()
        .environmentObject(appState)
    }
  }

  private var avatar: some View {
    Group {
      if #available(iOS 27.1, *) {
        DuoAdaptiveHomeProfileAvatar(
          image: profileManager.avatarImage,
          initials: profileManager.profile.initials,
          hasProfileData: profileManager.profile.hasData,
          scheme: scheme,
          isHalloween: isHalloween
        )
      } else {
        HomeProfileAvatar(
          image: profileManager.avatarImage,
          initials: profileManager.profile.initials,
          hasProfileData: profileManager.profile.hasData,
          scheme: scheme,
          isHalloween: isHalloween,
          diameter: 48
        )
      }
    }
    .contentShape(Circle())
    .accessibilityHidden(true)
  }
}

private struct HomeProfileAvatar: View {
  let image: UIImage?
  let initials: String
  let hasProfileData: Bool
  let scheme: ColorScheme
  let isHalloween: Bool
  let diameter: CGFloat

  private var gradientColors: [Color] {
    isHalloween
      ? [Color(hex: "4A2657"), Color(hex: "231433")]
      : [ShieldTheme.accent(scheme), Color(hex: "0077B6")]
  }

  private var ringColor: Color {
    isHalloween ? Color(hex: "F97316") : ShieldTheme.accent(scheme)
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(
          LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )

      // Keep a recognizable fallback under photos so transparent or
      // partially decoded avatar images never turn the toolbar action blank.
      if hasProfileData && !initials.isEmpty {
        Text(initials)
          .font(.system(size: diameter * 0.34, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
      } else {
        Image(systemName: "person.fill")
          .font(.system(size: diameter * 0.44, weight: .semibold))
          .symbolRenderingMode(.monochrome)
          .foregroundStyle(.white)
      }

      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: diameter - 4, height: diameter - 4)
          .clipShape(Circle())
      }
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .overlay(Circle().stroke(ringColor.opacity(isHalloween ? 0.9 : 0.85), lineWidth: 2))
  }
}

@available(iOS 27.1, *)
private struct DuoAdaptiveHomeProfileAvatar: View {
  let image: UIImage?
  let initials: String
  let hasProfileData: Bool
  let scheme: ColorScheme
  let isHalloween: Bool

  @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge

  var body: some View {
    HomeProfileAvatar(
      image: image,
      initials: initials,
      hasProfileData: hasProfileData,
      scheme: scheme,
      isHalloween: isHalloween,
      diameter: toolbarVerticalEdge == nil ? 48 : 54
    )
  }
}

struct HomeHeroCardView: View {
  let scheme: ColorScheme
  var showsHeading = true
  let onProtect: () -> Void
  var onScan: (() -> Void)? = nil
  var onPhotos: (() -> Void)? = nil
  var onFiles: (() -> Void)? = nil
  let onLearnMore: () -> Void

  private var isHalloween: Bool {
    ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      livePrivacyTelemetryPill
        .padding(.bottom, 10)

      if showsHeading {
        HStack(spacing: 8) {
          Text(heroTitle)
            .shieldFont(32, weight: .heavy)
            .foregroundColor(ShieldTheme.primary(scheme))
            .fixedSize(horizontal: false, vertical: true)
          if isHalloween {
            Text("🦇")
              .font(.system(size: 22))
          }
        }
        .padding(.bottom, 6)

        Text(heroSubtitle)
          .shieldFont(16, weight: .medium)
          .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(scheme))
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom, 14)
      }

      commandCenterLaunchpad
        .padding(.bottom, ShieldTheme.s3)

      HomeProcessingCard(scheme: scheme, onLearnMore: onLearnMore)
    }
  }

  private var livePrivacyTelemetryPill: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(ShieldTheme.success)
        .frame(width: 7, height: 7)
        .overlay(
          Circle()
            .stroke(ShieldTheme.success.opacity(0.4), lineWidth: 2)
            .scaleEffect(1.5)
        )

      Text("100% On-Device • Bóveda Criptográfica • Cero Rastreo")
        .shieldFont(11, weight: .bold)
        .foregroundColor(ShieldTheme.secondary(scheme))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(
      Capsule()
        .fill(ShieldTheme.rowBackground(scheme))
        .overlay(Capsule().stroke(ShieldTheme.line(scheme).opacity(0.6), lineWidth: 0.8))
    )
  }

  private var commandCenterLaunchpad: some View {
    VStack(spacing: 10) {
      protectDocumentAction

      intakeShortcutsRow
    }
    .padding(ShieldTheme.s3)
    .background(
      RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
        .fill(ShieldTheme.cardBackground(scheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [
              ShieldTheme.accent(scheme).opacity(0.35),
              ShieldTheme.line(scheme).opacity(0.5),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
  }

  @ViewBuilder
  private var protectDocumentAction: some View {
    if #available(iOS 26.0, *) {
      protectDocumentButton.buttonStyle(.glassProminent)
    } else {
      protectDocumentButton.buttonStyle(.borderedProminent)
    }
  }

  private var protectDocumentButton: some View {
    Button(action: onProtect) {
      HStack(spacing: 8) {
        Image(systemName: "shield.lefthalf.filled")
          .font(.system(size: 19, weight: .bold))
        Text(LanguageManager.shared.home("home_primary_action"))
          .font(.system(size: 17, weight: .bold))
      }
      .frame(maxWidth: .infinity, minHeight: 52)
    }
    .controlSize(.large)
    .tint(ShieldTheme.accent(scheme))
    .accessibilityIdentifier("home.primaryAction")
  }

  private var intakeShortcutsRow: some View {
    HStack(spacing: 8) {
      shortcutPill(
        icon: "camera.fill",
        title: LanguageManager.shared.current == .es ? "Escanear" : "Scan",
        tint: Color(hex: "10B981"),
        action: { (onScan ?? onProtect)() }
      )
      shortcutPill(
        icon: "photo.fill",
        title: LanguageManager.shared.current == .es ? "Fotos" : "Photos",
        tint: Color(hex: "0EA5E9"),
        action: { (onPhotos ?? onProtect)() }
      )
      shortcutPill(
        icon: "folder.fill",
        title: LanguageManager.shared.current == .es ? "Archivos" : "Files",
        tint: Color(hex: "F59E0B"),
        action: { (onFiles ?? onProtect)() }
      )
    }
  }

  private func shortcutPill(icon: String, title: String, tint: Color, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(tint)
        Text(title)
          .shieldFont(12, weight: .bold)
          .foregroundStyle(ShieldTheme.primary(scheme))
      }
      .frame(maxWidth: .infinity, minHeight: 36)
      .background(
        ZStack {
          ShieldTheme.rowBackground(scheme)
          tint.opacity(scheme == .dark ? 0.10 : 0.05)
        }
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 11, style: .continuous)
          .stroke(
            LinearGradient(
              colors: [
                tint.opacity(scheme == .dark ? 0.40 : 0.30),
                ShieldTheme.line(scheme).opacity(0.4),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 0.8
          )
      )
    }
    .buttonStyle(ScaleButtonStyle())
  }

  private var heroTitle: String {
    LanguageManager.shared.home("home_hero_title")
  }

  private var heroSubtitle: String {
    LanguageManager.shared.home("home_hero_subtitle")
  }

}

private struct HomeProcessingCard: View {
  let scheme: ColorScheme
  let onLearnMore: () -> Void

  private var isHalloween: Bool {
    ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
  }

  var body: some View {
    Button(action: onLearnMore) {
      HStack(alignment: .center, spacing: 14) {
        ZStack {
          if isHalloween {
            Circle()
              .fill(
                LinearGradient(
                  colors: [Color(hex: "F97316").opacity(0.28), Color(hex: "7C3AED").opacity(0.2)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
            Circle()
              .stroke(Color(hex: "FF9A3D").opacity(0.5), lineWidth: 1)
            Image(systemName: "lock.shield.fill")
              .shieldFont(24, weight: .semibold)
              .foregroundColor(Color(hex: "FFA53D"))
          } else {
            Circle()
              .fill(ShieldTheme.accentDim(scheme))
            Image(systemName: "lock.shield.fill")
              .shieldFont(24, weight: .semibold)
              .foregroundColor(ShieldTheme.accentColor(scheme))
          }
        }
        .frame(width: 56, height: 56)

        VStack(alignment: .leading, spacing: 5) {
          Text(LanguageManager.shared.home("home_processing_local_title"))
            .shieldFont(16, weight: .bold)
            .foregroundColor(ShieldTheme.primary(scheme))
            .lineLimit(2)

          Text(LanguageManager.shared.home("home_processing_local_body"))
            .shieldFont(13)
            .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(scheme))
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)

          HStack(spacing: 6) {
            Text("AES-256 GCM • Cero Nube")
              .shieldFont(10, weight: .bold)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(ShieldTheme.rowBackground(scheme), in: Capsule())

            Spacer()

            HStack(spacing: 4) {
              Text(LanguageManager.shared.home("home_processing_local_learn_more"))
                .shieldFont(13, weight: .semibold)
              Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
            }
          }
          .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accentColor(scheme))
        }

        Spacer(minLength: 0)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        isHalloween
          ? Color(hex: "1F112B").opacity(0.85)
          : ShieldTheme.selectedBackground(scheme)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(
            isHalloween
              ? LinearGradient(
                colors: [Color(hex: "FF9A3D").opacity(0.55), Color(hex: "7C3AED").opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
              : LinearGradient(
                colors: [ShieldTheme.accentStroke(scheme).opacity(0.4)], startPoint: .top,
                endPoint: .bottom),
            lineWidth: isHalloween ? 1.0 : 0.8
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(ScaleButtonStyle())
    .accessibilityLabel(LanguageManager.shared.home("home_processing_local_title"))
    .accessibilityHint(LanguageManager.shared.home("home_processing_local_body"))
    .accessibilityIdentifier("home.onDeviceInfo")
  }
}

struct HomeRecentDocumentCard: View {
  let doc: DocumentItem
  let lang: AppLanguage
  let action: () -> Void

  @EnvironmentObject private var appState: AppState
  private var isHalloween: Bool {
    ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark
  }

  private var shouldMask: Bool {
    doc.isVaulted
  }

  private var matchingPageNumbers: [Int] {
    doc.matchingOCRPageIndices(for: appState.searchQuery).map { $0 + 1 }
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        thumbnail

        VStack(alignment: .leading, spacing: 4) {
          Text(
            shouldMask
              ? LanguageManager.shared.home("home_protected_document")
              : doc.title
          )
          .shieldFont(16, weight: .bold)
          .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
          .lineLimit(2)
          .minimumScaleFactor(0.85)

          Text(doc.compactDateLabel(lang: lang))
            .shieldFont(14)
            .foregroundColor(
              isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(appState.preferredScheme)
            )
            .lineLimit(1)

          if !appState.searchQuery.isEmpty, !matchingPageNumbers.isEmpty {
            HStack(spacing: 6) {
              Image(systemName: "text.magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
              Text(
                LanguageManager.shared.home(
                  "home_search_pages_found",
                  matchingPageNumbers.map { String($0) }.joined(separator: ", ")
                )
              )
              .shieldFont(12, weight: .semibold)
              .lineLimit(1)
              .minimumScaleFactor(0.78)
            }
            .foregroundColor(
              isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.accent(appState.preferredScheme)
            )
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(ShieldTheme.accentDim(appState.preferredScheme), in: Capsule())
          } else if !doc.batchReviewPendingPageIndices.isEmpty {
            HStack(spacing: 6) {
              Image(systemName: "clock")
                .font(.system(size: 13, weight: .semibold))
              Text(LanguageManager.shared.home("home_review_pending_short"))
                .shieldFont(12, weight: .semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            }
            .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.warning)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
              isHalloween
                ? Color(hex: "F97316").opacity(0.18)
                : ShieldTheme.warningBackground(appState.preferredScheme),
              in: Capsule()
            )
            .overlay(
              Capsule().stroke(
                isHalloween ? Color(hex: "FFA53D").opacity(0.4) : Color.clear,
                lineWidth: 0.8
              )
            )
          }
        }

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(
            isHalloween
              ? Color(hex: "FF9A3D").opacity(0.8) : ShieldTheme.tertiary(appState.preferredScheme)
          )
          .accessibilityHidden(true)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        isHalloween
          ? Color(hex: "1C1026").opacity(0.85)
          : ShieldTheme.cardBackground(appState.preferredScheme)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(
            isHalloween
              ? LinearGradient(
                colors: [Color(hex: "FF9A3D").opacity(0.55), Color(hex: "7C3AED").opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
              : LinearGradient(
                colors: [ShieldTheme.line(appState.preferredScheme)], startPoint: .top,
                endPoint: .bottom),
            lineWidth: isHalloween ? 1.0 : 0.8
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .buttonStyle(ScaleButtonStyle())
    .disabled(doc.isLocked)
    .opacity(doc.isLocked ? 0.7 : 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      shouldMask
        ? LanguageManager.shared.home("home_protected_document")
        : doc.title
    )
    .accessibilityValue(
      !matchingPageNumbers.isEmpty
        ? LanguageManager.shared.home(
          "home_search_pages_found",
          matchingPageNumbers.map { String($0) }.joined(separator: ", ")
        )
        : (!doc.batchReviewPendingPageIndices.isEmpty
          ? LanguageManager.shared.home("home_review_pending")
          : "")
    )
    .accessibilityHint(
      doc.isVaulted
        ? LanguageManager.shared.vault("vault_unlock_faceid")
        : "")
  }

  private var thumbnail: some View {
    DocumentThumbnailView(
      doc: doc,
      size: CGSize(width: 104, height: 74),
      maxPixelSize: 360,
      isVaultUnlocked: appState.isVaultUnlocked
    )
    .accessibilityHidden(true)
  }
}
