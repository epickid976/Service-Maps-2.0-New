//
//  MyTokenModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation

struct MyTokenModel: Codable {
    var id: String
    var name: String
    var owner: String
    var congregation: String
    var moderator: Bool
    var expire: Int64?
    var user: String?
}
