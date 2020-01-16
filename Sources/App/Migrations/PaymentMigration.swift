//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import FluentPostgreSQL
import Vapor

/// Allows `User` to be used as a Fluent migration.
extension Payment: Migration {
    /// See `Migration`.
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.create(Payment.self, on: connection) { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.ammount)
            builder.field(for: \.channel)
            builder.field(for: \.paymentDate)
            builder.field(for: \.paymentMethod)
            builder.field(for: \.purposeId)
            builder.reference(from: \.purposeId, to: \Purpose.id)
            builder.field(for: \.state)
            builder.field(for: \.userId)
            builder.reference(from: \.userId, to: \User.id)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.deletedAt)
            
        }
    }
}
