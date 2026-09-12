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
        loadData(from: provider, typeIdentifier: typeIdentifier, suggestedName: suggestedName) { result in
            let outcome: Result<Void, SharedImportStoreError>
            do {
                let loaded = try result.get()
                try SharedImportStore.enqueue(
                    data: loaded.data,
                    fileName: loaded.fileName,
                    typeIdentifier: typeIdentifier
                )
                outcome = .success(())
            } catch {
                outcome = .failure((error as? SharedImportStoreError) ?? .unsupportedFile)
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

    private typealias LoadedShareData = (data: Data, fileName: String)

    /// Some providers expose a security-scoped temporary file; others only
    /// vend bytes. Try the file path first to avoid an unnecessary copy, then
    /// fall back to data representation without logging or persisting source
    /// provider details.
    private func loadData(
        from provider: NSItemProvider,
        typeIdentifier: String,
        suggestedName: String?,
        completion: @escaping (Result<LoadedShareData, SharedImportStoreError>) -> Void
    ) {
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
            if let url {
                do {
                    let values = try url.resourceValues(forKeys: [.fileSizeKey])
                    if let size = values.fileSize, size > SharedImportStore.maximumBytes {
                        completion(.failure(.fileTooLarge))
                        return
                    }
                    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                    completion(.success((data, suggestedName ?? url.lastPathComponent)))
                    return
                } catch {
                    // Fall through to loadDataRepresentation. A provider can
                    // revoke its temporary URL before the callback reads it.
                }
            }

            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                guard let data, !data.isEmpty else {
                    completion(.failure(.unsupportedFile))
                    return
                }
                guard data.count <= SharedImportStore.maximumBytes else {
                    completion(.failure(.fileTooLarge))
                    return
                }
                completion(.success((data, suggestedName ?? "")))
            }
        }
    }

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
