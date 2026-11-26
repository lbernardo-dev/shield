import SwiftUI
import UIKit

// MARK: - DocumentThumbnailView

struct DocumentThumbnailView: View {
  let doc: DocumentItem
  var size: CGSize = CGSize(width: 60, height: 44)
  var maxPixelSize: CGFloat = 360
  var contentMode: ContentMode = .fill
  var isVaultUnlocked: Bool = false

  @State private var image: UIImage? = nil
  @State private var isLoading: Bool = true
  @Environment(\.colorScheme) private var scheme

  private var isVaultProtected: Bool {
    doc.isVaulted && !isVaultUnlocked
  }

  var body: some View {
    ZStack {
      // Document image or vector template with redactions
      if doc.kind == .photo || doc.imageFileName != nil || (doc.pageFileNames?.isEmpty == false) {
        photoContent
      } else {
        templateContent
      }

      // Vault protection overlay: frosted glass veil and cyber-violet vault badge
      if isVaultProtected {
        vaultOverlay
      } else if doc.isLocked {
        lockedOverlay
      }
    }
    .frame(width: size.width, height: size.height)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(
          isVaultProtected
            ? Color(hex: "6366F1").opacity(0.4)
            : ShieldTheme.line(scheme).opacity(0.7),
          lineWidth: 0.8
        )
    )
    .task(id: thumbnailKey) {
      await loadThumbnail()
    }
  }

  private var thumbnailKey: String {
    let filename = doc.imageFileName(for: 0) ?? doc.imageFileName ?? doc.pageFileNames?.first ?? ""
    return
      "\(doc.id)_\(filename)_\(doc.modifiedAt.timeIntervalSince1970)_\(doc.isVaulted)_\(doc.redactions(for: 0).count)"
  }

  private func loadThumbnail() async {
    guard let filename = doc.imageFileName(for: 0) ?? doc.imageFileName ?? doc.pageFileNames?.first
    else {
      await MainActor.run {
        isLoading = false
      }
      return
    }

    var loaded = await ThumbnailManager.shared.thumbnail(
      for: filename,
      isVaulted: doc.isVaulted,
      maxPixelSize: maxPixelSize
    )

    if let baseImage = loaded, let adjustment = doc.imageAdjustment {
      loaded = ExportEngine.applyImageAdjustment(baseImage, store: adjustment) ?? baseImage
    }

    await MainActor.run {
      self.image = loaded
      self.isLoading = false
    }
  }

  private var photoContent: some View {
    ZStack {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: size.width, height: size.height)
          .clipped()

        // Scaled redactions overlay
        let redactions = doc.redactions(for: 0)
        if !redactions.isEmpty {
          Canvas { context, sz in
            for r in redactions where r.style != .blurStrong && r.style != .blurSoft {
              let rect = CGRect(
                x: r.rect.origin.x * sz.width,
                y: r.rect.origin.y * sz.height,
                width: r.rect.width * sz.width,
                height: r.rect.height * sz.height
              )
              drawMask(context: &context, rect: rect, style: r.style)
            }
          }
          .frame(width: size.width, height: size.height)

          BlurRedactionOverlay(redactions: redactions, size: size)
        }
      } else {
        placeholderView
      }
    }
    .frame(width: size.width, height: size.height)
    .blur(radius: isVaultProtected ? 7 : 0)
  }

  private var templateContent: some View {
    DocumentView(
      kind: doc.kind,
      size: size,
      fields: doc.fields,
      redactions: doc.redactions(for: 0),
      watermark: doc.watermark,
      imageFileName: doc.imageFileName,
      isVaulted: doc.isVaulted,
      imageAdjustment: doc.imageAdjustment
    )
    .frame(width: size.width, height: size.height)
    .blur(radius: isVaultProtected ? 7 : 0)
  }

  private var vaultOverlay: some View {
    ZStack {
      Rectangle()
        .fill(.ultraThinMaterial)
        .opacity(0.85)

      Color.black.opacity(0.35)

      let badgeDimension = min(size.width, size.height) * 0.46
      let iconSize = min(size.width, size.height) * 0.24

      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: badgeDimension, height: badgeDimension)
          .shadow(color: Color.black.opacity(0.45), radius: 3, x: 0, y: 1.5)

        Image(systemName: "lock.shield.fill")
          .font(.system(size: iconSize, weight: .bold))
          .foregroundColor(.white)
      }
    }
    .frame(width: size.width, height: size.height)
  }

  private var lockedOverlay: some View {
    ZStack {
      Color.black.opacity(0.4)
      Image(systemName: "lock.fill")
        .font(.system(size: min(size.width, size.height) * 0.26, weight: .semibold))
        .foregroundColor(.white)
    }
    .frame(width: size.width, height: size.height)
  }

  private var placeholderView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(ShieldTheme.surface2)

      VStack(spacing: 3) {
        RoundedRectangle(cornerRadius: 1.5)
          .fill(ShieldTheme.tertiary(scheme).opacity(0.4))
          .frame(width: size.width * 0.55, height: 2.5)
        RoundedRectangle(cornerRadius: 1.5)
          .fill(ShieldTheme.tertiary(scheme).opacity(0.3))
          .frame(width: size.width * 0.72, height: 2.5)
        RoundedRectangle(cornerRadius: 1.5)
          .fill(ShieldTheme.tertiary(scheme).opacity(0.25))
          .frame(width: size.width * 0.4, height: 2.5)
      }
    }
    .frame(width: size.width, height: size.height)
  }
}
