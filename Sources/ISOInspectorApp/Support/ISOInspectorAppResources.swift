import Foundation

enum ISOInspectorAppResources {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            return .module
        #else
            return .main
        #endif
    }()
}
