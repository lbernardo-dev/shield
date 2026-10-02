import SwiftUI
import UIKit
import Combine

// MARK: - UserProfile Model

public struct UserProfile: Codable, Equatable, Sendable {
    public var firstName: String
    public var lastName: String
    public var email: String
    public var phone: String
    public var avatarFileName: String?

    public init(
        firstName: String = "",
        lastName: String = "",
        email: String = "",
        phone: String = "",
        avatarFileName: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.avatarFileName = avatarFileName
    }

    public var fullName: String {
        let parts = [firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                     lastName.trimmingCharacters(in: .whitespacesAndNewlines)].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    public var initials: String {
        let f = firstName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)
        let l = lastName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)
        let combined = "\(f)\(l)".uppercased()
        return combined.isEmpty ? "U" : combined
    }

    public var hasData: Bool {
        !firstName.isEmpty || !lastName.isEmpty || !email.isEmpty || !phone.isEmpty || avatarFileName != nil
    }
}

// MARK: - UserProfileManager

@MainActor
public final class UserProfileManager: ObservableObject {
    public static let shared = UserProfileManager()

    private let userDefaultsKey = "shield.userProfile.data"
    private let avatarFileName = "shield_user_avatar.jpg"

    @Published public private(set) var profile: UserProfile
    @Published public private(set) var avatarImage: UIImage?

    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = saved
        } else {
            self.profile = UserProfile()
        }
        self.avatarImage = Self.loadAvatar(fileName: avatarFileName)
    }

    public func update(
        firstName: String,
        lastName: String,
        email: String,
        phone: String
    ) {
        profile.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    public func setAvatarImage(_ image: UIImage) {
        let normalized = Self.normalizeImage(image, maxDimension: 512)
        if Self.saveAvatar(image: normalized, fileName: avatarFileName) {
            profile.avatarFileName = avatarFileName
            self.avatarImage = normalized
            persist()
        }
    }

    public func removeAvatarImage() {
        Self.deleteAvatar(fileName: avatarFileName)
        profile.avatarFileName = nil
        self.avatarImage = nil
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - File Storage

    private static var avatarDirectoryURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("UserProfile", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func loadAvatar(fileName: String) -> UIImage? {
        let fileURL = avatarDirectoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }

    private static func saveAvatar(image: UIImage, fileName: String) -> Bool {
        let fileURL = avatarDirectoryURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return false
        }
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private static func deleteAvatar(fileName: String) {
        let fileURL = avatarDirectoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static func normalizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
