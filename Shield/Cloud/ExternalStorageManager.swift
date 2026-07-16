import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExternalStorageProvider

enum ExternalStorageProvider: String, CaseIterable, Identifiable {
    case googleDrive
    case dropbox
    case oneDrive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleDrive: return "Google Drive"
        case .dropbox:     return "Dropbox"
        case .oneDrive:    return "OneDrive"
        }
    }

    var icon: String {
        switch self {
        case .googleDrive: return "g.circle.fill"
        case .dropbox:     return "shippingbox.fill"
        case .oneDrive:    return "cloud.fill"
        }
    }

    var iconColor: String {
        switch self {
        case .googleDrive: return "4285F4"
        case .dropbox:     return "0061FF"
        case .oneDrive:    return "0078D4"
        }
    }

}

// MARK: - ExternalStoragePickerView
// Cloud providers are exposed by their Files extensions. Shield never stores
// provider credentials and receives only the security-scoped URL selected by
// the user in the system document picker.

struct ExternalStoragePickerSheet: View {
    @StateObject private var pm = PremiumManager.shared
    @Binding var isPresented: Bool
    var onImport: (URL) -> Void

    @State private var showDocPicker = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.textTertiary.opacity(0.5))
                .padding(.top, 10)

            HStack {
                Text(LanguageManager.shared.common("cloud_import_title"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)

            if !pm.isPro {
                proGate
            } else {
                providerList
            }

            Spacer()
        }
        .background(ShieldTheme.surface1.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showDocPicker) {
            FilesPickerView { url in
                showDocPicker = false
                isPresented = false
                onImport(url)
            } onCancel: {
                showDocPicker = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
        }
    }

    private var proGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.textTertiary)
            Text(LanguageManager.shared.common("cloud_pro_desc"))
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showPaywall = true
            } label: {
                Label(LanguageManager.shared.paywall("paywall_unlock_pro"),
                      systemImage: "crown.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(ShieldTheme.accent)
                    .foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
    }

    private var providerList: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Native Files app picker (includes all cloud providers via Files extension)
                providerRow(
                    icon: "folder.fill",
                    color: "FFD60A",
                    name: LanguageManager.shared.common("cloud_files_title"),
                    subtitle: LanguageManager.shared.common("cloud_files_subtitle"),
                    isConnected: true
                ) {
                    showDocPicker = true
                }

                ShieldDivider().padding(.leading, 54)

                // These shortcuts all open the system picker. iOS controls which
                // provider is initially visible and which locations are enabled.
                ForEach(ExternalStorageProvider.allCases) { provider in
                    providerRow(
                        icon: provider.icon,
                        color: provider.iconColor,
                        name: provider.displayName,
                        subtitle: LanguageManager.shared.common("cloud_select_in_files"),
                        isConnected: true
                    ) {
                        showDocPicker = true
                    }
                    if provider != ExternalStorageProvider.allCases.last {
                        ShieldDivider().padding(.leading, 54)
                    }
                }
            }
            .background(ShieldTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
            .padding(.horizontal, 16)

            Label(
                LanguageManager.shared.common("cloud_provider_setup_hint"),
                systemImage: "info.circle"
            )
            .font(.system(size: 11))
            .foregroundColor(ShieldTheme.textTertiary)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private func providerRow(icon: String, color: String, name: String, subtitle: String,
                               isConnected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: color))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ShieldTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textTertiary)
                }

                Spacer()

                if isConnected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                } else {
                    Text(LanguageManager.shared.common("cloud_connect"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
