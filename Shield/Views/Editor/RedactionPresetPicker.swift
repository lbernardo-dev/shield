import SwiftUI

// MARK: - RedactionPresetPickerSheet

struct RedactionPresetPickerSheet: View {
    let lang: AppLanguage
    let onSelect: (RedactionPreset) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingCustomProfileManager = false
    @State private var customProfiles = ProtectionProfileStore.loadProfiles()
    @State private var activeCustomProfile = ProtectionProfileStore.load()

    private var activeCustomProfileTitle: String {
        activeCustomProfile == .privacyFirst
            ? (lang == .es ? "Personalizada" : "Custom")
            : activeCustomProfile.name
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.textTertiary.opacity(0.5))
                .padding(.top, 10)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                        Text(lang == .es ? "¿Qué necesita realmente el receptor?" : "What does the recipient actually need?")
                        .shieldFont(18, weight: .bold)
                        .foregroundColor(ShieldTheme.textPrimary)

                    Text(lang == .es ? "Elige una intención; revisarás cada sugerencia antes de exportar." : "Choose a purpose; you review every suggestion before exporting.")
                        .shieldFont(13, weight: .regular)
                        .foregroundColor(ShieldTheme.textSecondary)
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .shieldFont(13, weight: .semibold)
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.surface3)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(RedactionPreset.allCases) { preset in
                        Button {
                            if preset == .custom {
                                showingCustomProfileManager = true
                            } else {
                                onSelect(preset)
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: preset.iconColorHex).opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: preset.icon)
                                        .shieldFont(18, weight: .semibold)
                                        .foregroundColor(Color(hex: preset.iconColorHex))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(preset == .custom ? activeCustomProfileTitle : preset.title(lang: lang))
                                        .shieldFont(15, weight: .semibold)
                                        .foregroundColor(ShieldTheme.textPrimary)

                                    Text(preset == .custom
                                         ? (lang == .es
                                            ? "\(activeCustomProfile.maskedEntities.count) tipos de datos · \(customProfiles.count) perfiles"
                                            : "\(activeCustomProfile.maskedEntities.count) data types · \(customProfiles.count) profiles")
                                         : preset.subtitle(lang: lang))
                                        .shieldFont(12, weight: .regular)
                                        .foregroundColor(ShieldTheme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .shieldFont(12, weight: .semibold)
                                    .foregroundColor(ShieldTheme.textTertiary)
                            }
                            .padding(14)
                            .background(ShieldTheme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(ShieldTheme.surfaceLine, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("editor.preset.\(preset.rawValue)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(ShieldTheme.surface1.ignoresSafeArea())
        .presentationDetents(horizontalSizeClass == .regular ? [.large] : [.medium, .large])
        .sheet(isPresented: $showingCustomProfileManager) {
            CustomProtectionProfileManager(
                lang: lang,
                profiles: customProfiles,
                activeProfileName: activeCustomProfile.name
            ) { selectedProfile in
                onSelect(.custom)
                dismiss()
            } onRefresh: {
                activeCustomProfile = ProtectionProfileStore.load()
                customProfiles = ProtectionProfileStore.loadProfiles()
            }
        }
    }
}

private struct CustomProtectionProfileManager: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var profiles: [CustomProtectionProfile]
    @State private var activeProfileName: String
    @State private var editingProfile = CustomProtectionProfile.privacyFirst
    @State private var editingOriginalName: String?
    @State private var showingEditor = false
    @State private var profileNameToDelete: String?
    @State private var showingStoreError = false

    let lang: AppLanguage
    let onSelect: (CustomProtectionProfile) -> Void
    let onRefresh: () -> Void

    init(
        lang: AppLanguage,
        profiles: [CustomProtectionProfile],
        activeProfileName: String,
        onSelect: @escaping (CustomProtectionProfile) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.lang = lang
        _profiles = State(initialValue: profiles)
        _activeProfileName = State(initialValue: activeProfileName)
        self.onSelect = onSelect
        self.onRefresh = onRefresh
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(profiles, id: \.name) { profile in
                        HStack(spacing: 10) {
                            Button {
                                do {
                                    try ProtectionProfileStore.setActive(profile)
                                    activeProfileName = profile.name
                                    onSelect(profile)
                                    dismiss()
                                } catch {
                                    showingStoreError = true
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(displayName(for: profile))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(lang == .es
                                         ? "\(profile.maskedEntities.count) tipos de datos"
                                         : "\(profile.maskedEntities.count) data types")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                                if profile.name == activeProfileName {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ShieldTheme.success)
                                        .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityValue(profile.name == activeProfileName
                                                ? (lang == .es ? "Seleccionado" : "Selected")
                                                : (lang == .es ? "No seleccionado" : "Not selected"))
                            .accessibilityIdentifier("editor.customProfile.use.\(profile.name)")

                            Menu {
                                Button(lang == .es ? "Editar" : "Edit", systemImage: "pencil") {
                                    edit(profile)
                                }
                                Button(lang == .es ? "Duplicar" : "Duplicate", systemImage: "plus.square.on.square") {
                                    do {
                                        _ = try ProtectionProfileStore.duplicate(profile, lang: lang)
                                        profiles = ProtectionProfileStore.loadProfiles()
                                    } catch {
                                        showingStoreError = true
                                    }
                                }
                                Button(lang == .es ? "Eliminar" : "Delete", systemImage: "trash", role: .destructive) {
                                    profileNameToDelete = profile.name
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel(lang == .es ? "Acciones del perfil" : "Profile actions")
                        }
                    }
                } footer: {
                    Text(lang == .es
                         ? "Los perfiles se guardan en este dispositivo. Elige uno para generar sugerencias que revisarás antes de compartir."
                         : "Profiles stay on this device. Choose one to create suggestions that you review before sharing.")
                }
            }
            .navigationTitle(LanguageManager.shared.editor("editor_protection_profiles_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang == .es ? "Cerrar" : "Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createProfile) {
                        Label(lang == .es ? "Nuevo perfil" : "New profile", systemImage: "plus")
                    }
                    .accessibilityIdentifier("editor.customProfile.create")
                }
            }
            .confirmationDialog(
                lang == .es ? "¿Eliminar este perfil?" : "Delete this profile?",
                isPresented: Binding(
                    get: { profileNameToDelete != nil },
                    set: { if !$0 { profileNameToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(lang == .es ? "Eliminar perfil" : "Delete profile", role: .destructive) {
                    if let profileNameToDelete {
                        do {
                            try ProtectionProfileStore.delete(name: profileNameToDelete)
                            profiles = ProtectionProfileStore.loadProfiles()
                            activeProfileName = ProtectionProfileStore.load().name
                        } catch {
                            showingStoreError = true
                        }
                    }
                    profileNameToDelete = nil
                }
                Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {
                    profileNameToDelete = nil
                }
            }
            .sheet(isPresented: $showingEditor) {
                CustomProtectionProfileEditor(profile: editingProfile, lang: lang) { updatedProfile in
                    do {
                        _ = try ProtectionProfileStore.save(updatedProfile, replacingName: editingOriginalName)
                        profiles = ProtectionProfileStore.loadProfiles()
                        activeProfileName = ProtectionProfileStore.load().name
                        editingOriginalName = nil
                        return true
                    } catch {
                        return false
                    }
                }
            }
            .alert(
                lang == .es ? "No se pudo guardar" : "Could not save",
                isPresented: $showingStoreError
            ) {
                Button(lang == .es ? "Aceptar" : "OK", role: .cancel) {}
            } message: {
                Text(lang == .es
                     ? "El perfil permanece cifrado en este dispositivo. Comprueba que la app esté desbloqueada e inténtalo de nuevo."
                     : "The profile stays encrypted on this device. Make sure the app is unlocked and try again.")
            }
        }
        .presentationDetents(horizontalSizeClass == .regular ? [.large] : [.medium, .large])
        .onDisappear(perform: onRefresh)
    }

    private func createProfile() {
        let name = lang == .es ? "Perfil personalizado" : "Custom profile"
        editingProfile = CustomProtectionProfile.newProfile(name: name)
        editingOriginalName = nil
        showingEditor = true
    }

    private func edit(_ profile: CustomProtectionProfile) {
        editingProfile = profile
        editingOriginalName = profile.name
        showingEditor = true
    }

    private func displayName(for profile: CustomProtectionProfile) -> String {
        profile == .privacyFirst
            ? (lang == .es ? "Personalizada" : "Custom")
            : profile.name
    }
}

private struct CustomProtectionProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var profile: CustomProtectionProfile
    @State private var showingSaveError = false

    let lang: AppLanguage
    let onSave: (CustomProtectionProfile) -> Bool

    init(profile: CustomProtectionProfile, lang: AppLanguage, onSave: @escaping (CustomProtectionProfile) -> Bool) {
        _profile = State(initialValue: profile)
        self.lang = lang
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(lang == .es ? "Nombre del perfil" : "Profile name", text: $profile.name)
                        .accessibilityIdentifier("editor.customProfile.name")
                } header: {
                    Text(lang == .es ? "PERFIL" : "PROFILE")
                }

                Section {
                    ForEach(OCRSensitiveEntityKind.allCases, id: \.self) { kind in
                        Toggle(kind.title(lang: lang), isOn: binding(for: kind))
                            .accessibilityIdentifier("editor.customProfile.entity.\(kind.rawValue)")
                    }
                } header: {
                    Text(lang == .es ? "DATOS QUE DEBE OCULTAR" : "DATA TO HIDE")
                } footer: {
                    Text(lang == .es
                         ? "El perfil genera sugerencias locales. Revisa cada máscara antes de compartir."
                         : "This profile creates on-device suggestions. Review every mask before sharing.")
                }

                Section {
                    Picker(lang == .es ? "Estilo de máscara" : "Mask style", selection: maskStyleBinding) {
                        ForEach(MaskStyle.allCases.filter { !$0.isPremium }, id: \.self) { style in
                            Text(style.label(lang: lang)).tag(style)
                        }
                    }
                    .accessibilityIdentifier("editor.customProfile.maskStyle")
                } header: {
                    Text(lang == .es ? "APARIENCIA" : "APPEARANCE")
                } footer: {
                    Text(lang == .es
                         ? "El estilo es una preferencia visual. La exportación sustituye los estilos difuminados por una máscara opaca."
                         : "Style is a visual preference. Export replaces blurred styles with an opaque mask.")
                }

                Section {
                    Toggle(lang == .es ? "Añadir marca de agua" : "Add watermark", isOn: watermarkBinding)
                        .accessibilityIdentifier("editor.customProfile.watermarkEnabled")
                    if profile.shouldApplyWatermark {
                        TextField(
                            lang == .es ? "Texto de la marca de agua" : "Watermark text",
                            text: watermarkTextBinding,
                            axis: .vertical
                        )
                        .lineLimit(1...2)
                        .accessibilityIdentifier("editor.customProfile.watermarkText")
                    }
                } header: {
                    Text(lang == .es ? "MARCA DE AGUA" : "WATERMARK")
                } footer: {
                    Text(lang == .es
                         ? "La marca de agua puede contener información visible para quien reciba la copia."
                         : "The watermark may contain information visible to anyone who receives the copy.")
                }

                Section {
                    Picker(lang == .es ? "Formato preferido" : "Preferred format", selection: outputFormatBinding) {
                        Text(lang == .es ? "PDF protegido" : "Protected PDF")
                            .tag(ProtectionProfileOutputFormat.pdf)
                        Text(lang == .es ? "Imagen protegida · página actual" : "Protected image · current page")
                            .tag(ProtectionProfileOutputFormat.image)
                    }
                    .accessibilityIdentifier("editor.customProfile.outputFormat")
                    Text(lang == .es
                         ? "Todos los formatos se rasterizan y verifican antes de compartir; el texto original no queda seleccionable."
                         : "Every format is rasterized and verified before sharing; original text remains non-selectable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } header: {
                    Text(lang == .es ? "SALIDA SEGURA" : "SAFE OUTPUT")
                }
            }
            .accessibilityIdentifier("editor.customProfile.form")
            .scrollContentBackground(.hidden)
            .background(ShieldTheme.surface1)
            .navigationTitle(lang == .es ? "Perfil personalizado" : "Custom profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang == .es ? "Cancelar" : "Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let cleanedName = String(profile.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
                    profile.name = cleanedName.isEmpty
                        ? (lang == .es ? "Personalizada" : "Custom")
                        : cleanedName
                    if onSave(profile) {
                        dismiss()
                    } else {
                        showingSaveError = true
                    }
                } label: {
                    Text(lang == .es ? "Guardar perfil" : "Save profile")
                        .shieldFont(14, weight: .bold)
                        .foregroundColor(ShieldTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(ShieldTheme.accent(scheme), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(profile.maskedEntities.isEmpty)
                .opacity(profile.maskedEntities.isEmpty ? 0.55 : 1)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(ShieldTheme.surface1)
            }
            .alert(
                lang == .es ? "No se pudo guardar el perfil" : "Could not save profile",
                isPresented: $showingSaveError
            ) {
                Button(lang == .es ? "Aceptar" : "OK", role: .cancel) {}
            } message: {
                Text(lang == .es
                     ? "El almacenamiento cifrado no está disponible ahora. El perfil no se ha guardado."
                     : "Encrypted storage is unavailable right now. The profile was not saved.")
            }
        }
        .presentationDetents(horizontalSizeClass == .regular ? [.large] : [.medium, .large])
    }

    private func binding(for kind: OCRSensitiveEntityKind) -> Binding<Bool> {
        Binding(
            get: { profile.maskedEntities.contains(kind) },
            set: { profile.setMasked($0, kind: kind) }
        )
    }

    private var maskStyleBinding: Binding<MaskStyle> {
        Binding(
            get: { profile.maskStyle },
            set: { profile.maskStyleRawValue = $0.rawValue }
        )
    }

    private var watermarkBinding: Binding<Bool> {
        Binding(
            get: { profile.shouldApplyWatermark },
            set: { profile.appliesWatermark = $0 }
        )
    }

    private var watermarkTextBinding: Binding<String> {
        Binding(
            get: { profile.watermarkText ?? "" },
            set: { profile.watermarkText = String($0.prefix(80)) }
        )
    }

    private var outputFormatBinding: Binding<ProtectionProfileOutputFormat> {
        Binding(
            get: { profile.preferredOutputFormat },
            set: { profile.preferredOutputFormatRawValue = $0.rawValue }
        )
    }
}
