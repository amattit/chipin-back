//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//


import Vapor
import FluentSQLite

extension PurposeUser: Migration {
    
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(PurposeUser.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.userId)
            builder.reference(from: \.userId, to: \User.id)
            builder.field(for: \.purposeId)
            builder.reference(from: \.purposeId, to: \Purpose.id)
            builder.field(for: \.state)
            builder.unique(on: \.userId, \.purposeId)
        }
    }
}
