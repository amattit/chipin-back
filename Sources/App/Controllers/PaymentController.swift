//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 16.01.2020.
//

import Vapor
import FluentPostgreSQL

class PaymentController {
    
    public func addPaymentData(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let purposeId = try req.parameters.next(Int.self)
        
        return try req.content.decode(PaymentRequest.self).flatMap { request in
            return Payment(id: nil, userId: try user.requireID(), purposeId: purposeId, ammount: request.ammount, channel: request.channel, paymentMethod: request.paymentMethod, paymentDate: Date(), state: request.state).save(on: req)
        }.transform(to: HTTPStatus.ok)
        
    }
}

struct PaymentRequest: Content {
    let ammount: Double
    let paymentMethod: String
    let channel: String
    let state: String
}

struct PaymentResponse: Content {
    let id: Int
    let ammount: Double
    let paymentMethod: String
    let paymentDate: String
}
