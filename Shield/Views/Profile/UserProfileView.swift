import SwiftUI
import PhotosUI

// MARK: - UserProfileView

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var profileManager = UserProfileManager.shared

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""

    @State private var showPhotoOptions = false
    @State private var showCameraPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var cameraImage: UIImage? = nil
    @State private var showSavedHUD = false

    private var strings: LanguageManager { .shared }
    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SeasonalThemeBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: ShieldTheme.s5) {
                        avatarHero
                            .padding(.top, ShieldTheme.s4)

                        personalInfoSection

                        quickPreferencesSection

                        saveButton
                            .padding(.top, ShieldTheme.s2)
                    }
                    .frame(maxWidth: ShieldTheme.readableWidth)
                    .padding(.horizontal, ShieldTheme.s4)
                    .padding(.bottom, ShieldTheme.s6)
                }

                if showSavedHUD {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 54, weight: .bold))
                                .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent(scheme))
                                .symbolEffect(.bounce, value: showSavedHUD)
                        }
                        .frame(width: 96, height: 96)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(
                                    isHalloween ? Color(hex: "F97316").opacity(0.5) : ShieldTheme.accent(scheme).opacity(0.4),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 16, y: 6)
                        .scaleEffect(showSavedHUD ? 1.0 : 0.6)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    .zIndex(200)
                }
            }
            .navigationTitle(strings.settings("settings_profile_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.common("common_close")) {
                        dismiss()
                    }
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(strings.common("common_save")) {
                        saveProfile()
                    }
                    .font(.body.weight(.bold))
                    .foregroundStyle(ShieldTheme.accent(scheme))
                }
            }
            .confirmationDialog(
                strings.settings("settings_profile_change_photo"),
                isPresented: $showPhotoOptions,
                titleVisibility: .visible
            ) {
                Button(strings.settings("settings_profile_take_photo")) {
                    showCameraPicker = true
                }

                Button(strings.settings("settings_profile_choose_library")) {
                    // Handled by PhotosPicker overlay or programmatic selection
                }

                if profileManager.avatarImage != nil {
                    Button(strings.settings("settings_profile_remove_photo"), role: .destructive) {
                        profileManager.removeAvatarImage()
                    }
                }

                Button(strings.common("common_cancel"), role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCameraPicker) {
                CameraPickerView(image: $cameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: cameraImage) { _, newImage in
                if let newImage {
                    profileManager.setAvatarImage(newImage)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            profileManager.setAvatarImage(uiImage)
                        }
                    }
                }
            }
            .onAppear {
                firstName = profileManager.profile.firstName
                lastName = profileManager.profile.lastName
                email = profileManager.profile.email
                phone = profileManager.profile.phone
            }
        }
    }

    // MARK: - Avatar Hero

    private var avatarHero: some View {
        VStack(spacing: ShieldTheme.s3) {
            ZStack(alignment: .bottomTrailing) {
                // Main Avatar Circle
                Group {
                    if let avatar = profileManager.avatarImage {
                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 104, height: 104)
                            .clipShape(Circle())
                    } else if !profileManager.profile.initials.isEmpty && profileManager.profile.hasData {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isHalloween
                                        ? [Color(hex: "4A2657"), Color(hex: "231433")]
                                        : [ShieldTheme.accent(scheme).opacity(0.85), Color(hex: "0077B6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 104, height: 104)
                            .overlay(
                                Text(profileManager.profile.initials)
                                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    } else {
                        Circle()
                            .fill(
                                isHalloween
                                    ? Color(hex: "231433").opacity(0.85)
                                    : ShieldTheme.rowBackground(scheme)
                            )
                            .frame(width: 104, height: 104)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(isHalloween ? Color(hex: "FFD6A0") : ShieldTheme.secondary(scheme))
                            )
                    }
                }
                .overlay(
                    Circle().stroke(
                        isHalloween ? Color(hex: "F97316").opacity(0.65) : ShieldTheme.line(scheme),
                        lineWidth: 2
                    )
                )
                .shadow(
                    color: isHalloween ? Color(hex: "F97316").opacity(0.4) : Color.black.opacity(0.12),
                    radius: 12,
                    y: 4
                )

                // Camera Action Button Badge
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white)
                        .frame(width: 34, height: 34)
                        .background(
                            isHalloween
                                ? LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "EA580C")], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color(hex: "00B4D8"), Color(hex: "0077B6")], startPoint: .top, endPoint: .bottom),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                        .shadow(radius: 4)
                }
                .offset(x: 2, y: 2)
            }

            VStack(spacing: 4) {
                Text(profileManager.profile.fullName.isEmpty
                     ? strings.settings("settings_profile_title")
                     : profileManager.profile.fullName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ShieldTheme.primary(scheme))

                if !profileManager.profile.email.isEmpty {
                    Text(profileManager.profile.email)
                        .font(.caption)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                }
            }

            // Options: Camera or Gallery or Remove
            HStack(spacing: 12) {
                Button {
                    showCameraPicker = true
                } label: {
                    Label(strings.settings("settings_profile_take_photo"), systemImage: "camera")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isHalloween ? Color(hex: "291636") : ShieldTheme.rowBackground(scheme),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().stroke(
                                isHalloween ? Color(hex: "F97316").opacity(0.4) : ShieldTheme.line(scheme),
                                lineWidth: 1
                            )
                        )
                }
                .foregroundStyle(ShieldTheme.primary(scheme))

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(strings.settings("settings_profile_choose_library"), systemImage: "photo.on.rectangle")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isHalloween ? Color(hex: "291636") : ShieldTheme.rowBackground(scheme),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().stroke(
                                isHalloween ? Color(hex: "F97316").opacity(0.4) : ShieldTheme.line(scheme),
                                lineWidth: 1
                            )
                        )
                }
                .foregroundStyle(ShieldTheme.primary(scheme))

                if profileManager.avatarImage != nil {
                    Button {
                        profileManager.removeAvatarImage()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(ShieldTheme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(ShieldTheme.dangerDim, in: Capsule())
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Personal Information Form

    private var personalInfoSection: some View {
        SettingsCardSection(
            title: strings.settings("settings_profile_personal_info"),
            icon: "person.text.rectangle.fill"
        ) {
            VStack(spacing: 0) {
                profileTextField(
                    label: strings.settings("settings_profile_first_name"),
                    text: $firstName,
                    placeholder: strings.settings("settings_profile_first_name"),
                    icon: "person.fill"
                )

                SettingsRowDivider()

                profileTextField(
                    label: strings.settings("settings_profile_last_name"),
                    text: $lastName,
                    placeholder: strings.settings("settings_profile_last_name"),
                    icon: "person.2.fill"
                )

                SettingsRowDivider()

                profileTextField(
                    label: strings.settings("settings_profile_email"),
                    text: $email,
                    placeholder: "user@example.com",
                    icon: "envelope.fill",
                    keyboard: .emailAddress,
                    autocapitalization: .never
                )

                SettingsRowDivider()

                profileTextField(
                    label: strings.settings("settings_profile_phone"),
                    text: $phone,
                    placeholder: "+34 600 000 000",
                    icon: "phone.fill",
                    keyboard: .phonePad
                )
            }
        }
    }

    // MARK: - Quick Preferences

    private var quickPreferencesSection: some View {
        SettingsCardSection(
            title: strings.settings("settings_section_personalization"),
            icon: "slider.horizontal.3"
        ) {
            SettingsControlRow(
                icon: "character.book.closed",
                color: Color(hex: "00B4D8"),
                title: strings.settings("settings_language"),
                subtitle: strings.currentLanguage.displayName
            ) {
                Picker("", selection: Binding(
                    get: { strings.currentLanguage },
                    set: { newLang in appState.language = newLang }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang == .es ? "Español" : "English").tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .tint(ShieldTheme.accent(scheme))
            }

            SettingsRowDivider()

            SettingsControlRow(
                icon: "wand.and.stars",
                color: Color(hex: "F97316"),
                title: strings.settings("settings_themes_title"),
                subtitle: ShieldTheme.activeThemeID.title(language: strings.currentLanguage)
            ) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShieldTheme.tertiary(scheme))
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack(spacing: ShieldTheme.s2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                Text(strings.settings("settings_profile_save"))
                    .font(.headline.weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Color.white)
            .background(
                isHalloween
                    ? LinearGradient(colors: [Color(hex: "FFA53D"), Color(hex: "F97316"), Color(hex: "EA580C")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color(hex: "00B4D8"), Color(hex: "0077B6")], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(
                color: isHalloween ? Color(hex: "F97316").opacity(0.4) : Color(hex: "00B4D8").opacity(0.3),
                radius: 8,
                y: 3
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func profileTextField(
        label: String,
        text: Binding<String>,
        placeholder: String,
        icon: String,
        keyboard: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words
    ) -> some View {
        HStack(spacing: ShieldTheme.s3) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(ShieldTheme.accent(scheme))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ShieldTheme.tertiary(scheme))

                TextField(placeholder, text: text)
                    .font(.body)
                    .foregroundStyle(ShieldTheme.primary(scheme))
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 10)
    }

    private func saveProfile() {
        profileManager.update(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showSavedHUD = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.2)) {
                showSavedHUD = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
            }
        }
    }
}
