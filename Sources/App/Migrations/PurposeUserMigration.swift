//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//


import Vapor
import FluentPostgreSQL

extension PurposeUser: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.create(PurposeUser.self, on: connection) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.userId)
            builder.reference(from: \.userId, to: \User.id)
            builder.field(for: \.purposeId)
            builder.reference(from: \.purposeId, to: \Purpose.id)
            builder.field(for: \.state)
            builder.unique(on: \.userId, \.purposeId)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.deletedAt)
        }
    }
}
