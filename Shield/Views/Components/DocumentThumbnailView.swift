import SwiftUI

// MARK: - DocumentThumbnailView

struct DocumentThumbnailView: View {
    let doc: DocumentItem
    var maxPixelSize: CGFloat = 360
    var contentMode: ContentMode = .fill

    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            } else {
                placeholderView
            }
        }
        .task(id: thumbnailKey) {
            await loadThumbnail()
        }
    }

    private var thumbnailKey: String {
        let filename = doc.imageFileName ?? doc.pageFileNames?.first ?? ""
        return "\(doc.id)_\(filename)_\(doc.modifiedAt.timeIntervalSince1970)"
    }

    private func loadThumbnail() async {
        guard let filename = doc.imageFileName ?? doc.pageFileNames?.first else {
            isLoading = false
            return
        }

        let loaded = await ThumbnailManager.shared.thumbnail(
            for: filename,
            isVaulted: doc.isVaulted,
            maxPixelSize: maxPixelSize
        )

        await MainActor.run {
            self.image = loaded
            self.isLoading = false
        }
    }

    private var placeholderView: some View {
        ZStack {
            ShieldTheme.surface2
            VStack(spacing: 6) {
                Image(systemName: doc.category.icon)
                    .shieldFont(24, weight: .medium)
                    .foregroundColor(ShieldTheme.textTertiary)
            }
        }
    }
}
