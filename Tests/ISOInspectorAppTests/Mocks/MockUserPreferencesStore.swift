#if canImport(Foundation)
    import Foundation
    @testable import ISOInspectorApp

    /// Mock implementation of UserPreferencesPersisting for testing
    final class MockUserPreferencesStore: UserPreferencesPersisting, Sendable {
        var storedPreferences: UserPreferences?
        var resetCalled = false
        var shouldThrowOnSave = false
        var shouldThrowOnLoad = false

        func loadPreferences() throws -> UserPreferences? {
            if shouldThrowOnLoad { throw NSError(domain: "TestError", code: 1, userInfo: nil) }
            return storedPreferences
        }

        func savePreferences(_ preferences: UserPreferences) throws {
            if shouldThrowOnSave { throw NSError(domain: "TestError", code: 2, userInfo: nil) }
            storedPreferences = preferences
        }

        func reset() throws {
            resetCalled = true
            storedPreferences = nil
        }
    }
#endif
