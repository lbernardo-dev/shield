import SwiftUI

struct HomeRecurringActionsSection: View {
  let scheme: ColorScheme
  let lang: AppLanguage
  let isPro: Bool
  let onSelectMode: (RedactionMode) -> Void
  let onOpenBatch: () -> Void
  let onOpenPaywall: () -> Void

  private struct RecurringPreset: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let mode: RedactionMode?
    let isBatch: Bool
  }

  private var presets: [RecurringPreset] {
    [
      RecurringPreset(
        id: "rental",
        title: lang == .es ? "Alquiler Seguro" : "Secure Rental",
        subtitle: lang == .es ? "DNI, nómina y fianza" : "ID, payslip & lease",
        icon: "house.fill",
        tint: Color(hex: "5E5CE6"),
        mode: .rental,
        isBatch: false
      ),
      RecurringPreset(
        id: "job",
        title: lang == .es ? "Nómina Laboral" : "Job & Payslip",
        subtitle: lang == .es ? "Seg. Social e IRPF" : "SSN & sensitive tax data",
        icon: "briefcase.fill",
        tint: Color(hex: "FF9F0A"),
        mode: .job,
        isBatch: false
      ),
      RecurringPreset(
        id: "banking",
        title: lang == .es ? "Extracto Bancario" : "Bank Statement",
        subtitle: lang == .es ? "Saldos y compras" : "Balances & transactions",
        icon: "building.columns.fill",
        tint: Color(hex: "34C759"),
        mode: .banking,
        isBatch: false
      ),
      RecurringPreset(
        id: "travel",
        title: lang == .es ? "Viajes y Vuelos" : "Travel & Booking",
        subtitle: lang == .es ? "Pasaporte y reservas" : "Passport & booking details",
        icon: "airplane",
        tint: Color(hex: "64D2FF"),
        mode: .travel,
        isBatch: false
      ),
      RecurringPreset(
        id: "batch",
        title: lang == .es ? "Lote Masivo" : "Batch Protect",
        subtitle: lang == .es ? "Múltiples páginas" : "Multi-page processing",
        icon: "square.stack.3d.up.fill",
        tint: Color(hex: "20C7D9"),
        mode: nil,
        isBatch: true
      ),
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Image(systemName: "sparkles")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(ShieldTheme.accentColor(scheme))
        Text(lang == .es ? "Acciones Recurrentes" : "Recurring Actions")
          .shieldFont(16, weight: .bold)
          .foregroundStyle(ShieldTheme.primary(scheme))
        Spacer()
        Text(lang == .es ? "1 toque" : "1 tap")
          .shieldFont(11, weight: .semibold)
          .foregroundStyle(ShieldTheme.secondary(scheme))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(ShieldTheme.rowBackground(scheme), in: Capsule())
      }
      .padding(.horizontal, ShieldTheme.s1)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(presets) { preset in
            Button {
              if preset.isBatch {
                if isPro {
                  onOpenBatch()
                } else {
                  PremiumManager.recordFeatureGate(.batchProcessing, trigger: .settingsUpgrade)
                  onOpenPaywall()
                }
              } else if let mode = preset.mode {
                onSelectMode(mode)
              }
            } label: {
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                      .fill(preset.tint.opacity(scheme == .dark ? 0.22 : 0.14))
                      .frame(width: 34, height: 34)
                    Image(systemName: preset.icon)
                      .font(.system(size: 15, weight: .semibold))
                      .foregroundStyle(preset.tint)
                  }
                  Spacer()
                  if preset.isBatch && !isPro {
                    Image(systemName: "lock.fill")
                      .font(.system(size: 11, weight: .bold))
                      .foregroundStyle(ShieldTheme.tertiary(scheme))
                  }
                }

                VStack(alignment: .leading, spacing: 2) {
                  Text(preset.title)
                    .shieldFont(13, weight: .bold)
                    .foregroundStyle(ShieldTheme.primary(scheme))
                    .lineLimit(1)

                  Text(preset.subtitle)
                    .shieldFont(11, weight: .medium)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .lineLimit(1)
                }
              }
              .padding(12)
              .frame(width: 155, height: 96, alignment: .topLeading)
              .background(
                ZStack {
                  ShieldTheme.cardBackground(scheme)
                  LinearGradient(
                    colors: [
                      preset.tint.opacity(scheme == .dark ? 0.14 : 0.07),
                      preset.tint.opacity(scheme == .dark ? 0.04 : 0.01),
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
                        preset.tint.opacity(scheme == .dark ? 0.40 : 0.25),
                        preset.tint.opacity(scheme == .dark ? 0.12 : 0.06),
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
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 1)
      }
    }
    .padding(ShieldTheme.s4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      ShieldTheme.cardBackground(scheme),
      in: RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
        .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
    )
  }
}

struct HomeQuickAccessSection: View {
  let scheme: ColorScheme
  let onOpenLibrary: () -> Void
  let onOpenVault: () -> Void
  let onOpenTools: () -> Void
  let toolsExpanded: Bool

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var columns: [GridItem] {
    let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
    return Array(repeating: GridItem(.flexible(minimum: 44), spacing: ShieldTheme.s2), count: count)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: ShieldTheme.s3) {
      Text(LanguageManager.shared.home("home_quick_access"))
        .shieldFont(16, weight: .bold)
        .foregroundStyle(ShieldTheme.primary(scheme))
        .padding(.horizontal, ShieldTheme.s1)

      LazyVGrid(columns: columns, alignment: .leading, spacing: ShieldTheme.s2) {
        action(
          key: "home_quick_library",
          identifier: "home.quickAccess.library",
          icon: "doc.text.magnifyingglass",
          tint: Color(hex: "0EA5E9"),
          action: onOpenLibrary
        )
        action(
          key: "home_quick_vault",
          identifier: "home.quickAccess.vault",
          icon: "lock.rectangle.stack",
          tint: Color(hex: "6366F1"),
          action: onOpenVault
        )
      }

      Button {
        onOpenTools()
      } label: {
        HStack(spacing: ShieldTheme.s2) {
          Image(systemName: "square.grid.2x2.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(hex: "14B8A6"))
            .accessibilityHidden(true)
          Text(LanguageManager.shared.home("home_quick_tools"))
            .shieldFont(13, weight: .semibold)
            .foregroundStyle(ShieldTheme.primary(scheme))
            .multilineTextAlignment(.leading)
          Spacer(minLength: ShieldTheme.s2)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(ShieldTheme.tertiary(scheme))
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, ShieldTheme.s3)
        .background(
          ZStack {
            ShieldTheme.rowBackground(scheme)
            LinearGradient(
              colors: [
                Color(hex: "14B8A6").opacity(scheme == .dark ? 0.10 : 0.05),
                Color(hex: "14B8A6").opacity(scheme == .dark ? 0.02 : 0.01),
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
          }
          .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
        )
        .overlay(
          RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
            .stroke(Color(hex: "14B8A6").opacity(scheme == .dark ? 0.32 : 0.20), lineWidth: 0.8)
        )
        .contentShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityLabel(LanguageManager.shared.home("home_quick_tools"))
      .accessibilityHint(LanguageManager.shared.home("home_tools_services_subtitle"))
      .accessibilityValue(
        LanguageManager.shared.common(
          toolsExpanded ? "common_expanded" : "common_collapsed"
        )
      )
      .accessibilityIdentifier("home.quickAccess.tools")
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
  }

  private func action(
    key: String,
    identifier: String,
    icon: String,
    tint: Color,
    action: @escaping () -> Void
  ) -> some View {
    let title = LanguageManager.shared.home(key)

    return Button(action: action) {
      VStack(spacing: ShieldTheme.s2) {
        Image(systemName: icon)
          .font(.system(size: 19, weight: .semibold))
          .foregroundStyle(tint)
          .frame(width: 38, height: 38)
          .background(
            tint.opacity(scheme == .dark ? 0.20 : 0.12),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
          )
          .accessibilityHidden(true)

        Text(title)
          .shieldFont(13, weight: .semibold)
          .foregroundStyle(ShieldTheme.primary(scheme))
          .multilineTextAlignment(.center)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, minHeight: 76)
      .padding(.horizontal, ShieldTheme.s2)
      .padding(.vertical, ShieldTheme.s2)
      .background(
        ZStack {
          ShieldTheme.rowBackground(scheme)
          LinearGradient(
            colors: [
              tint.opacity(scheme == .dark ? 0.12 : 0.06),
              tint.opacity(scheme == .dark ? 0.03 : 0.01),
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
                tint.opacity(scheme == .dark ? 0.35 : 0.22),
                tint.opacity(scheme == .dark ? 0.10 : 0.05),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 0.8
          )
      )
      .contentShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityIdentifier(identifier)
  }
}

struct HomeModesSection: View {
  let scheme: ColorScheme
  let lang: AppLanguage
  let isPro: Bool
  let onShowBatch: () -> Void
  let onShowPaywall: () -> Void
  let onModeSelected: (RedactionMode) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        SectionHeader(title: LanguageManager.shared.home("home_quick_modes"))
        Spacer()
        Button {
          if isPro {
            onShowBatch()
          } else {
            PremiumManager.recordFeatureGate(.batchProcessing, trigger: .settingsUpgrade)
            onShowPaywall()
          }
        } label: {
          HStack(spacing: 5) {
            Image(systemName: isPro ? "square.stack.3d.up.fill" : "lock.fill")
              .shieldFont(11, weight: .semibold)
            Text(
              isPro
                ? (lang == .es ? "Lote" : "Batch") : LanguageManager.shared.home("home_batch_pro")
            )
            .shieldFont(12, weight: .bold)
          }
          .foregroundColor(isPro ? ShieldTheme.accentText : ShieldTheme.tertiary(scheme))
          .padding(.horizontal, 12)
          .frame(height: 28)
          .background(isPro ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
          .overlay(
            Capsule().stroke(
              isPro ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme).opacity(0.5),
              lineWidth: isPro ? 1 : 0.5)
          )
          .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("home.quickModes.batch")
        .padding(.trailing, ShieldTheme.s5)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(RedactionMode.allCases, id: \.self) { mode in
            let locked = mode.requiresPro && !isPro
            ModeCard(mode: mode, lang: lang, isLocked: locked) {
              if locked {
                PremiumManager.recordFeatureGate(.professionalModes, trigger: .settingsUpgrade)
                onShowPaywall()
              } else {
                onModeSelected(mode)
              }
            }
          }
        }
        .padding(.bottom, 4)
      }
      .padding(.horizontal, ShieldTheme.s5)
    }
  }
}

struct HomePaginationControls: View {
  let scheme: ColorScheme
  let currentPage: Int
  let totalPages: Int
  let onPrevious: () -> Void
  let onNext: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onPrevious) {
        Image(systemName: "chevron.left")
          .shieldFont(12, weight: .bold)
          .foregroundColor(
            currentPage > 0
              ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme).opacity(0.35)
          )
          .frame(width: 36, height: 32)
          .background(ShieldTheme.cardBackground(scheme))
          .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
          )
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .frame(minWidth: 44, minHeight: 44)
          .contentShape(Rectangle())
      }
      .disabled(currentPage == 0)

      Spacer()

      Text("\(currentPage + 1) / \(totalPages)")
        .shieldFont(12, weight: .bold)
        .foregroundColor(ShieldTheme.secondary(scheme))

      Spacer()

      Button(action: onNext) {
        Image(systemName: "chevron.right")
          .shieldFont(12, weight: .bold)
          .foregroundColor(
            currentPage < totalPages - 1
              ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme).opacity(0.35)
          )
          .frame(width: 36, height: 32)
          .background(ShieldTheme.cardBackground(scheme))
          .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
          )
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .frame(minWidth: 44, minHeight: 44)
          .contentShape(Rectangle())
      }
      .disabled(currentPage >= totalPages - 1)
    }
  }
}

struct HomeVaultCard: View {
  let scheme: ColorScheme
  let onTap: () -> Void

  private var isHalloween: Bool {
    ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
  }

  private let vaultTint = Color(hex: "6366F1")

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        ZStack {
          if isHalloween {
            RoundedRectangle(cornerRadius: 12)
              .fill(Color(hex: "F97316").opacity(0.2))
              .frame(width: 44, height: 44)
            Image(systemName: "lock.rectangle.stack.fill")
              .shieldFont(20, weight: .semibold)
              .foregroundColor(Color(hex: "FFA53D"))
          } else {
            RoundedRectangle(cornerRadius: 12)
              .fill(vaultTint.opacity(scheme == .dark ? 0.22 : 0.14))
              .frame(width: 44, height: 44)
            Image(systemName: "lock.rectangle.stack.fill")
              .shieldFont(20, weight: .semibold)
              .foregroundColor(vaultTint)
          }
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(LanguageManager.shared.home("home_vault"))
            .shieldFont(15, weight: .bold)
            .foregroundColor(ShieldTheme.primary(scheme))
          Text(LanguageManager.shared.home("home_secure_storage_faceid"))
            .shieldFont(12)
            .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.tertiary(scheme))
        }
        Spacer()
        Image(systemName: "chevron.right")
          .shieldFont(12, weight: .medium)
          .foregroundColor(isHalloween ? Color(hex: "FFA53D").opacity(0.8) : vaultTint.opacity(0.8))
      }
      .padding(16)
      .background {
        if isHalloween {
          Color(hex: "1C1026").opacity(0.85)
        } else {
          ZStack {
            ShieldTheme.cardBackground(scheme)
            LinearGradient(
              colors: [
                vaultTint.opacity(scheme == .dark ? 0.14 : 0.07),
                vaultTint.opacity(scheme == .dark ? 0.04 : 0.01),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          }
        }
      }
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(
            isHalloween
              ? LinearGradient(
                colors: [Color(hex: "FF9A3D").opacity(0.4), Color(hex: "7C3AED").opacity(0.3)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
              : LinearGradient(
                colors: [
                  vaultTint.opacity(scheme == .dark ? 0.38 : 0.25),
                  vaultTint.opacity(scheme == .dark ? 0.12 : 0.06),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
            lineWidth: isHalloween ? 1.0 : 0.8
          )
      )
      .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .buttonStyle(ScaleButtonStyle())
  }
}
