//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import FluentPostgreSQL
import Vapor

/// A registered user, capable of owning todo items.
final class Purpose: PostgreSQLModel {
    
    /// Уникальный идентификатор клиента, может быть nil пока не создан в БД
    var id: Int?
    
    /// Наименование сбора средств
    var title: String
    
    /// Ссылка на изобоажение
    var imagePath: String
    
    /// Описание кампании сбора средств
    var description: String
    
    /// Плановая дата окончания сбора средств
    var finishDate: Date?
    
    /// Плановая сумма сбора средств
    var targetAmmount: Double?
    
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    static let deletedAtKey: TimestampKey? = \.deletedAt

    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    init(id: Int?, title: String, imagePath: String, description: String, finishDate: Date?, targetAmmount: Double?) {
        self.id = id
        self.title = title
        self.imagePath = imagePath
        self.description = description
        self.finishDate = finishDate
        self.targetAmmount = targetAmmount
    }
}

//extension Purpose {
//    /// Fluent relation to the user that owns this token.
//    var user: Parent<Purpose, User> {
//        return parent(\.userId)
//    }
//}
