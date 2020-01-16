//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import Foundation
import FluentSQLite
import Vapor

/// Allows `User` to be used as a Fluent migration.
extension User: Migration {
    /// See `Migration`.
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(User.self, on: conn) { builder in
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
