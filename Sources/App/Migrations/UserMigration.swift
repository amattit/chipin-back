//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import FluentPostgreSQL
import Vapor

/// Allows `User` to be used as a Fluent migration.
extension User: PostgreSQLMigration {
    
    /// See `Migration`.
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.create(User.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
            builder.field(for: \.phoneNumber)
            builder.field(for: \.imagePath)
            builder.field(for: \.isYandexConnect)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.deletedAt)
        }
    }
}
