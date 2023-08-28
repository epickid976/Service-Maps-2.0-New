//
//  PendingChange.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/27/23.
//

import Foundation

struct PendingChange: Codable {
    var id: UUID
    var changeType: ChangeType
    var changeAction: ChangeAction
    var modelId: String
}
