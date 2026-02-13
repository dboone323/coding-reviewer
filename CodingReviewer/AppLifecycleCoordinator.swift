import Foundation
import Security
import SwiftUI

@MainActor
enum CodingReviewerLifecycleCoordinator {
    static func configureOnLaunch() {
        UserDefaults.standard.register(defaults: [
            "CR_USE_AI": false,
            "CR_AUTO_REFRESH_SECONDS": 30,
            "CR_ACCESSIBILITY_MODE": true,
        ])

        if CodingReviewerSecureStore.string(forKey: "codingreviewer.session.token") == nil {
            _ = CodingReviewerSecureStore.set("", forKey: "codingreviewer.session.token")
        }

        _ = NetworkSecurityPolicy.makeSecureSession()
    }
}

enum CodingReviewerSecureStore {
    static func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, forKey: key)
    }

    static func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func set(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "CodingReviewer",
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            return SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecSuccess
        }

        var addQuery = query
        addQuery.merge(attributes) { _, new in new }
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    private static func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "CodingReviewer",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}

struct CodingReviewerAccessibilityDefaultsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(.xSmall ... .accessibility5)
            .accessibilityElement(children: .contain)
    }
}

extension View {
    func codingReviewerAccessibilityDefaults() -> some View {
        modifier(CodingReviewerAccessibilityDefaultsModifier())
    }
}
