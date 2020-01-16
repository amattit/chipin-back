//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import FluentSQLite
import Vapor

/// Allows `User` to be used as a Fluent migration.
extension Purpose: Migration {
    /// See `Migration`.
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(Purpose.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.title)
            builder.field(for: \.description)
            builder.field(for: \.imagePath)
            builder.field(for: \.finishDate)
            builder.field(for: \.targetAmmount)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.deletedAt)
        }
    }
}
