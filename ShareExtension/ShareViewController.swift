import Social
import UniformTypeIdentifiers
import UIKit

final class ShareViewController: SLComposeServiceViewController {
    private var isImporting = false

    override func isContentValid() -> Bool {
        supportedProvider() != nil && !isImporting
    }

    override func didSelectPost() {
        guard !isImporting, let provider = supportedProvider() else {
            extensionContext?.cancelRequest(withError: SharedImportStoreError.unsupportedFile)
            return
        }
        isImporting = true
        validateContent()
        let type = provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
            ? UTType.pdf
            : UTType.image
        let typeIdentifier = type.identifier
        let suggestedName = provider.suggestedName
        let reference = ShareControllerReference(self)
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
            let outcome: Result<Void, SharedImportStoreError>
            do {
                if let error { throw error }
                guard let url else { throw SharedImportStoreError.unsupportedFile }
                let values = try url.resourceValues(forKeys: [.fileSizeKey])
                if let size = values.fileSize, size > SharedImportStore.maximumBytes {
                    throw SharedImportStoreError.fileTooLarge
                }
                let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                try SharedImportStore.enqueue(
                    data: data,
                    fileName: suggestedName ?? url.lastPathComponent,
                    typeIdentifier: typeIdentifier
                )
                outcome = .success(())
            } catch let error as SharedImportStoreError {
                outcome = .failure(error)
            } catch {
                outcome = .failure(.unsupportedFile)
            }
            Task { @MainActor in
                guard let controller = reference.value else { return }
                switch outcome {
                case .success:
                    _ = await controller.extensionContext?.open(SharedImportStore.callbackURL)
                    controller.extensionContext?.completeRequest(returningItems: nil)
                case .failure(let error):
                    controller.extensionContext?.cancelRequest(withError: error)
                }
            }
        }
    }

    override func configurationItems() -> [Any]! { [] }

    private func supportedProvider() -> NSItemProvider? {
        extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] }
            .first {
                $0.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
                    || $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            }
    }
}

private final class ShareControllerReference: @unchecked Sendable {
    weak var value: ShareViewController?

    init(_ value: ShareViewController) {
        self.value = value
    }
}
