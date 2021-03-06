//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import FluentPostgreSQL
import Vapor

struct PurposeUser: PostgreSQLModel {
    
    var id: Int?
    var userId: User.ID
    var purposeId: Purpose.ID
    var state: String
    
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    static let deletedAtKey: TimestampKey? = \.deletedAt

    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    init(userId: Int, purposeId: Int, state: PurposeUserState) {
        self.userId = userId
        self.purposeId = purposeId
        self.state = state.rawValue
    }
}

extension PurposeUser {
    var purpose: Parent<PurposeUser, Purpose> {
        return parent(\.purposeId)
    }
    
    var person: Parent<PurposeUser, User> {
        return parent(\.userId)
    }
}

enum PurposeUserState: String {
    case inviteSend = "INVITESEND"
    case decline = "DECLINE"
    case accept = "ACCEPT"
    case initital = "INITIAL"
}
