//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import FluentPostgreSQL
import Vapor

/// A registered user, capable of owning todo items.
final class Payment: PostgreSQLModel {
    
    /// Идентификатор платежа
    var id: Int?
    
    /// Сумма платежа
    var ammount: Double
    
    /// Метож платежа CLEARING, DEBT
    var paymentMethod: String
    
    /// Канал поступления IOS, ANDROID
    var channel: String
    
    /// Дата платежа
    var paymentDate: Date
    
    /// Состояние платежа. Выполнен, в процессе итд. Может не использоваться
    var state: String
    
    /// Ссылка на назнаяение сбора средств
    var purposeId: Purpose.ID
    
    /// Ссылка на пользователя
    var userId: User.ID
    
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    static let deletedAtKey: TimestampKey? = \.deletedAt

    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    init(id: Int?, userId: Int, purposeId: Int, ammount: Double, channel: String, paymentMethod: String, paymentDate: Date, state: String) {
        self.id = id
        self.ammount = ammount
        self.userId = userId
        self.purposeId = purposeId
        self.channel = channel
        self.paymentMethod = paymentMethod
        self.paymentDate = paymentDate
        self.state = state
        
    }

}
