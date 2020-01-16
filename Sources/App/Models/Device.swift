//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 16.01.2020.
//

import Vapor
import FluentPostgreSQL

final class Device: PostgreSQLModel {
    
    var id: Int?

    var userId: User.ID
    
    var token: String
    
    var platform: String?
    
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    static let deletedAtKey: TimestampKey? = \.deletedAt

    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    init(userId: Int, token: String, platform: String) {
        self.userId = userId
        self.token = token
        self.platform = platform
    }
}
