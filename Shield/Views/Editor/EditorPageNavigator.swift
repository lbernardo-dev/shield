import SwiftUI

// MARK: - EditorPageNavigator
/// Side rail thumbnail navigator for multi-page documents in expanded workspaces.
struct EditorPageNavigator: View {
    @ObservedObject var vm: EditorViewModel
    let lang: AppLanguage
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(LanguageManager.shared.t("model_page", table: "Model", language: lang).uppercased())
                    .shieldFont(11, weight: .bold)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                Spacer()
                Text("\(vm.currentPage + 1)/\(vm.pageCount)")
                    .shieldFont(11, weight: .semibold)
                    .foregroundStyle(ShieldTheme.tertiary(scheme))
            }
            .padding(.horizontal, ShieldTheme.s3)
            .padding(.vertical, ShieldTheme.s2)
            .background(ShieldTheme.cardBackground(scheme))

            Divider()

            // Page list
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: ShieldTheme.s2) {
                    ForEach(0..<vm.pageCount, id: \.self) { pageIndex in
                        PageThumbnailCard(
                            pageIndex: pageIndex,
                            isSelected: vm.currentPage == pageIndex,
                            redactionCount: vm.doc.redactions(for: pageIndex).count,
                            imageFileName: vm.doc.imageFileName(for: pageIndex),
                            isVaulted: vm.doc.isVaulted,
                            lang: lang,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    vm.goToPage(pageIndex)
                                }
                            }
                        )
                    }
                }
                .padding(ShieldTheme.s2)
            }
        }
        .background(ShieldTheme.pageBackground(scheme))
    }
}

// MARK: - PageThumbnailCard

private struct PageThumbnailCard: View {
    let pageIndex: Int
    let isSelected: Bool
    let redactionCount: Int
    let imageFileName: String?
    let isVaulted: Bool
    let lang: AppLanguage
    let onSelect: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Page preview
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ShieldTheme.cardBackground(scheme))

                    if let fileName = imageFileName,
                       let image = AppState.loadImage(fileName: fileName, isVaulted: isVaulted) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "doc.text")
                            .shieldFont(24)
                            .foregroundStyle(ShieldTheme.tertiary(scheme))
                            .frame(height: 80)
                    }

                    // Redactions badge overlay
                    if redactionCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "shield.fill")
                                .shieldFont(8, weight: .bold)
                            Text("\(redactionCount)")
                                .shieldFont(9, weight: .heavy)
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(ShieldTheme.accent(scheme), in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(4)
                    }
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.line(scheme),
                            lineWidth: isSelected ? 2 : 0.8
                        )
                )

                // Page number
                Text(LanguageManager.shared.editor("editor_page_indicator", pageIndex + 1, 0)
                    .components(separatedBy: "/").first?
                    .trimmingCharacters(in: .whitespaces) ?? "\(pageIndex + 1)")
                    .shieldFont(10, weight: isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? ShieldTheme.primary(scheme) : ShieldTheme.secondary(scheme))
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? ShieldTheme.accentDim(scheme) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(pageIndex + 1), \(redactionCount) masks")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
