//
//  File.swift
//  
//
//  Created by Михаил Серёгин on 14.01.2020.
//

import Vapor
import FluentPostgreSQL

class PurposeController {
    
    public func createPurpose(_ req: Request) throws -> Future<CreatePurposeResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreatePurposeRequest.self).flatMap { result in
            
            return Purpose(id: nil, title: result.name, imagePath: result.imageUrl ?? "", description: result.description ?? "", finishDate: result.finishDate?.value ?? Date().value?.value, targetAmmount: result.targetAmmount ?? 0.0).save(on: req)
                .map { purpose in
                    let _ = PurposeUser(userId: try user.requireID(), purposeId: try purpose.requireID(), state: PurposeUserState.initital).save(on: req)
                    
                    return try CreatePurposeResponse(purposeId: purpose.requireID(), personsId: [CreatePurposeUserResponse(id: user.requireID(), phoneNumber: user.phoneNumber)])
            }
            
        }
    }
    
    public func fetchPurposeWhereUserIsPresent(_ req: Request) throws -> Future<[GetPurposeResponse]> {
        let user = try req.requireAuthenticated(User.self)
        return PurposeUser.query(on: req).filter(\.userId, .equal, try user.requireID()).all().flatMap { results in
            
            return try results.map { item in
                
                try self.getPurposeData(req, purposeUser: item).flatMap { purpose in
                    return try self.getPurposeData1(req, purposeUser: item).flatMap { purposeResponse in
                        return try self.getPurposeUsers1(req, purpose: purpose).and(result: purposeResponse).map { (users, purposeR) in
                            var response = purposeR
                            response.persons = users
                            var ca = 0.0
                            for user in users {
                                for paymen in user.payments {
                                    if paymen.state == "DONE" {
                                        ca += paymen.ammount
                                    }
                                    
                                }
                            }
                            response.currentAmmount = ca
                            return response
                        }
                    }
                }
            }.flatten(on: req)
        }
    }
    
    public func fetchPurposeById(_ req: Request) throws -> Future<GetPurposeResponse> {
        let user = try req.requireAuthenticated(User.self)
        let purposeId = try req.parameters.next(Int.self)
        return Purpose.query(on: req).filter(\.id, .equal, purposeId).first().unwrap(or: Abort(.notFound, reason: "Кампания не найдена")).flatMap { purpose in
            return try self.getPurposeUsers1(req, purpose: purpose).and(result: purpose).map { (users, purpose) in
                
                let currentUser = users.filter { (response) -> Bool in
                    return response.id == user.id!
                }.first
                
                var ca = 0.0
                for user in users {
                    for payment in user.payments {
                        if payment.state == "DONE" {
                            ca += payment.ammount
                        }
                        
                    }
                }
                return GetPurposeResponse(id: try purpose.requireID(), name: purpose.title, targetAmmount: purpose.targetAmmount ?? 0.0, currentAmmount: ca, imageUrl: purpose.imagePath, description: purpose.description, finishDate: (purpose.finishDate?.value)!, isInitial: currentUser?.purposeState == PurposeUserState.initital.rawValue, persons: users)
            }
        }
    }
    
    public func archivePurpose(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let purposeId = try req.parameters.next(Int.self)
        return PurposeUser.query(on: req)
            .filter(\.userId, .equal, try user.requireID())
            .filter(\.purposeId, .equal, purposeId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "Кампания не найдена"))
            .flatMap { purposeUser in
                if purposeUser.state == PurposeUserState.initital.rawValue {
                    return purposeUser.purpose.query(on: req).first().unwrap(or: Abort(.notFound, reason: "Кампания не найдена")).flatMap { purposeResult in
                        _ = purposeUser.delete(on: req)
                        return purposeResult
                            .delete(on: req)
                            .transform(to: HTTPStatus.ok)
                    }
                        
                } else {
                    throw Abort(.notAcceptable, reason: "Нет доступа для выполнения операции")
                }
        }
    }
    
    public func editPurpose(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let purposeId = try req.parameters.next(Int.self)
        return try req.content.decode(EditPurposeRequest.self).flatMap { requestData in
            return PurposeUser.query(on: req)
                .filter(\.userId, .equal, try user.requireID())
                .filter(\.purposeId, .equal, purposeId)
                .first()
                .unwrap(or: Abort(.notFound, reason: "Кампания не найдена"))
                .flatMap { purposeUser in
                    if purposeUser.state == PurposeUserState.initital.rawValue {
                        return purposeUser.purpose.query(on: req).first().unwrap(or: Abort(.notFound, reason: "Кампания не найдена")).flatMap { purposeResult in
                            purposeResult.title = requestData.name
                            purposeResult.description = requestData.description
                            purposeResult.finishDate = requestData.finishDate.value
                            purposeResult.targetAmmount = requestData.targetAmmount
                            purposeResult.imagePath = requestData.imageUrl ?? ""
                            
                            return purposeResult.save(on: req).transform(to: HTTPStatus.ok)
                                
                        }
                            
                    } else {
                        throw Abort(.notAcceptable, reason: "Нет доступа для выполнения операции")
                    }
            }
        }
        
    }
    
    /// Поиск кампаний по статусу. Соответсвует так же запросу получения всех приглашений
    public func findByState(_ req: Request) throws -> Future<[GetPurposeResponse]> {
        let user = try req.requireAuthenticated(User.self)
        let stateRequest = try req.query.decode(GetInvitesRequest.self)
        return PurposeUser
            .query(on: req)
            .filter(\.userId, .equal, try user.requireID())
            .filter(\.state, .equal, stateRequest.state).all()
            .flatMap { return try $0.map { try self.getPurposeData1(req, purposeUser: $0)}
                .flatten(on: req)
        }
    }
    
    /// Поиск кампаний где пользователь автор. Устранить в будущем
    public func findInitialPurpose(_ req: Request) throws -> Future<[GetPurposeResponse]> {
        let user = try req.requireAuthenticated(User.self)
        return PurposeUser
            .query(on: req)
            .filter(\.userId, .equal, try user.requireID())
            .filter(\.state, .equal, PurposeUserState.initital.rawValue).all()
            .flatMap { return try $0.map { try self.getPurposeData1(req, purposeUser: $0)}
                .flatten(on: req)
        }
    }
    
    private func getPaymentsByUserAndPurpose(_ req: Request, user: User, purpose: Purpose) throws -> Future<[PaymentResponse]> {
        return try user.payments.query(on: req).filter(\.purposeId, .equal, try purpose.requireID()).all().map { payments in
            return try payments.compactMap { payment in
                return PaymentResponse(id: try payment.requireID(), ammount: payment.ammount, paymentMethod: payment.paymentMethod, paymentDate: payment.paymentDate.value!)
            }
        }
    }
    
    private func getPurposeData(_ req: Request, purposeUser: PurposeUser) throws -> Future<Purpose> {
        return purposeUser.purpose.query(on: req).first().unwrap(or: Abort(.badRequest, reason: "Не удалось найти Кампанию"))
    }
    
    private func getPurposeUsers(_ req: Request, purpose: Purpose) throws -> Future<[User]> {
        return PurposeUser.query(on: req).filter(\.purposeId, .equal, try purpose.requireID()).all().flatMap { purposeUsers in
            return purposeUsers.compactMap { purposeUser in
                return purposeUser.person.query(on: req).first().unwrap(or: Abort(.badRequest))
            }.flatten(on: req)
        }
    }
    
    private func getPurposeData1(_ req: Request, purposeUser: PurposeUser) throws -> Future<GetPurposeResponse> {
        return purposeUser.purpose.query(on: req).first().unwrap(or: Abort(.badRequest, reason: "Не удалось найти Кампанию")).map { purpose in
            return GetPurposeResponse(id: try purpose.requireID(), name: purpose.title, targetAmmount: purpose.targetAmmount ?? 0.0, currentAmmount: 0.0, imageUrl: purpose.imagePath, description: purpose.description, finishDate: purpose.finishDate!.value!, isInitial: purposeUser.state == PurposeUserState.initital.rawValue, persons: [])
        }
    }
    
    private func getPurposeUsers1(_ req: Request, purpose: Purpose) throws -> Future<[GetPurposeResponse.GetPurposeUserResponse]> {
        return PurposeUser.query(on: req).filter(\.purposeId, .equal, try purpose.requireID()).all().flatMap { purposeUsers in
            return purposeUsers.compactMap { purposeUser in
                return purposeUser.person.query(on: req).first().unwrap(or: Abort(.badRequest)).map { user in
                    return try self.getPurposeUsersPayments(req, purpose: purpose, user: user).and(result: user).map { (payments, user) in
                        return GetPurposeResponse.GetPurposeUserResponse(id: try user.requireID(), imagePath: user.imagePath ?? "", name: user.name, payments: payments, phoneNumber: user.phoneNumber, purposeState: purposeUser.state, email: "")
                    }
                }
            }.flatten(on: req).flatMap { response in
                return response.flatten(on: req)
            }
        }
    }
    
    private func getPurposeUsersPayments(_ req: Request, purpose: Purpose, user: User) throws -> Future<[GetPurposeResponse.GetPurposeUserPaymentResponse]> {
        return try user.payments.query(on: req).filter(\.purposeId, .equal, try purpose.requireID()).all().map { payments in
            return payments.map { payment in
                return GetPurposeResponse.GetPurposeUserPaymentResponse(ammount: payment.ammount, paymentMethod: payment.paymentMethod, channel: payment.channel, state: payment.state)
            }
        }
    }
}

struct GetPurposeResponse: Content {
    let id: Int
    let name: String
    let targetAmmount: Double
    var currentAmmount: Double
    let imageUrl : String
    let description: String
    let finishDate: DateFormatFromMobile
    let isInitial: Bool
    var persons: [GetPurposeUserResponse]
    
    struct GetPurposeUserResponse: Content {
        let id: Int
        let imagePath: String
        let name: String
        let payments: [GetPurposeUserPaymentResponse]
        let phoneNumber: String
        let purposeState: String
        let email: String
    }
    
    struct GetPurposeUserPaymentResponse: Content {
        let ammount: Double
        let paymentMethod: String
        let channel: String
        let state: String
    }
}

struct CreatePurposeRequest: Content {
    var imageUrl: String?
    let targetAmmount: Double?
    let currentAmmount: Double?
    let description: String?
    let finishDate: DateFormatFromMobile?
    let name: String
    let persons: [CreatePurposeUserRequest]
}

struct EditPurposeRequest: Content {
    var imageUrl: String?
    let targetAmmount: Double
    let description: String
    let finishDate: DateFormatFromMobile
    let name: String
}

struct CreatePurposeUserRequest: Content {
    let name: String
    let phoneNumber: String
}

struct CreatePurposeResponse: Content {
    let purposeId: Int
    let personsId: [CreatePurposeUserResponse]
}

struct CreatePurposeUserResponse: Content {
    let id: Int
    let phoneNumber: String
}

struct GetInvitesRequest: Content {
    let state: String
}

typealias DateFormatFromMobile = String
typealias DateFormatToMobile = Date

extension DateFormatFromMobile {
    var value: Date? {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-dd-MM"
            return dateFormatter.date(from: self)
        }
    }
}

extension DateFormatToMobile {
    var value: String? {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-dd-MM"
            return dateFormatter.string(from: self)
        }
    }
}

