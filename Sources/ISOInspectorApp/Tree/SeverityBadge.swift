//
//  SeverityBadge.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/30/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//

import Combine
import FoundationUI
import ISOInspectorKit
import NestedA11yIDs
import SwiftUI

extension ParseTreeOutlineView {
    struct SeverityBadge: View {
        let severity: ValidationIssue.Severity

        var body: some View { Badge(text: severity.label.uppercased(), level: badgeLevel) }

        private var badgeLevel: BadgeLevel {
            switch severity {
            case .info: return .info
            case .warning: return .warning
            case .error: return .error
            }
        }
    }
}
