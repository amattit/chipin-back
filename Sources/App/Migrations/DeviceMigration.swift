//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 16.01.2020.
//

import FluentPostgreSQL
import Vapor

/// Allows `User` to be used as a Fluent migration.
extension Device: Migration {
    /// See `Migration`.
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.create(Device.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.userId)
            builder.field(for: \.token)
            builder.field(for: \.platform)
            builder.reference(from: \.userId, to: \User.id)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.deletedAt)
        }
    }
}
