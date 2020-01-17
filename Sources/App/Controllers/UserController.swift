import Crypto
import Vapor
import FluentSQLite

/// Creates new users and logs them in.
final class UserController {
    /// Logs a user in, returning a token for accessing protected endpoints.
    func login(_ req: Request) throws -> Future<UserToken> {
        // get user auth'd by basic auth middleware
        let user = try req.requireAuthenticated(User.self)
        
        // create new token for this user
        let token = try UserToken.create(userID: user.requireID())
        
        // save and return token
        return token.save(on: req)
    }
    
    /// Creates a new user.
    func create(_ req: Request) throws -> Future<UserResponse> {
        // decode request content
        return try req.content.decode(CreateUserRequest.self).flatMap { user -> Future<User> in
            
            // save new user
            return User(id: nil, name: user.name, phone: user.phoneNumber)
                .save(on: req)
        }.map { user in
            // map to public user response (omits password hash)
            return try UserResponse(id: user.requireID(), name: user.name)
        }
    }
    
    func authorize(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(CreateUserRequest.self).flatMap { request in
            let code = AuthUserTmpData.shared.addCode(for: request.phoneNumber, name: request.name)
            
            let headers: HTTPHeaders = .init()
            _ = try request.phoneNumber.isAwailableFormat()
            let url = URL(string: "/sys/send.php?login=_silo@mail.ru&psw=jGA76A81&phones=7\(request.phoneNumber)&mes=Ваш код доступа к приложению: \(code)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            let httpReq = HTTPRequest(
                method: .POST,
                url: url!,
                headers: headers,
                body: HTTPBody())

            let client = HTTPClient.connect(hostname: "smsc.ru", on: req)

            return client.flatMap(to: HTTPStatus.self) { client in
                return client.send(httpReq).transform(to: HTTPStatus.ok)
            }
        }
    }
    
    func checkCode(_ req: Request) throws -> Future<String> {
        return try req.content.decode(ConfirmPhone.self).flatMap { requestData in
            _ = try requestData.phoneNumber.isAwailableFormat()
            if let code = AuthUserTmpData.shared.getCode(for: requestData.phoneNumber) {
                guard code == requestData.code else {
                    throw Abort(.badRequest, reason: "Код не подходит")
                }
                
                return self.findUserByPhone(req, phone: requestData.phoneNumber).flatMap { user in
                    if let u = user {
                        let token = try UserToken.create(userID: u.requireID())
                        return token.save(on: req).map { token in
                            AuthUserTmpData.shared.removeUserData(for: requestData.phoneNumber)
                            return token.string
                        }
                    } else {
                        let userData = AuthUserTmpData.shared.getUserData(for: requestData.phoneNumber)
                        return User(name: userData.name, phone: userData.phone).save(on: req).flatMap { user in
                            let token = try UserToken.create(userID: user.requireID())
                            return token.save(on: req).map { token in
                                AuthUserTmpData.shared.removeUserData(for: requestData.phoneNumber)
                                return token.string
                            }
                        }
                    }
                }
                
                
            } else {
                throw Abort(.badRequest, reason: "Повторите процедуру аутентификации заново")
            }
            
        }
    }
    
    public func addPurposeMember(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(AddPurposeMemberRequest.self).flatMap { request in
            PurposeUser.query(on: req)
                .filter(\.purposeId, .equal, request.purposeId)
                .filter(\.userId, .equal, try user.requireID()).first()
                .flatMap { purposeUser in
                    if purposeUser != nil {
                        var item = purposeUser
                        if item!.state != PurposeUserState.initital.rawValue {
                            item!.state = PurposeUserState.init(rawValue: request.state.uppercased())!.rawValue
                        }
                        return item!.save(on: req).transform(to: HTTPStatus.ok)
                    } else {
                        return Purpose.query(on: req).filter(\.id, .equal, request.purposeId).first().unwrap(or: Abort(.badRequest, reason: "Такой цели сбора средств не существует")).flatMap { purpose in
                            return PurposeUser(userId: try user.requireID(), purposeId: request.purposeId, state: PurposeUserState(rawValue: PurposeUserState.init(rawValue: request.state.uppercased())!.rawValue) ?? .decline).save(on: req).transform(to: HTTPStatus.ok)
                        }
                    }
            }
        }
    }
    
    public func editUserRequest(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(EditUserInfoRequest.self).flatMap { request in
            user.name = request.name
            user.imagePath = request.imagePath
            return user.save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    public func addDeviceToken(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(TokenRequest.self).flatMap { request in
            return Device(id: nil, userId: try user.requireID(), token: request.token, platform: "UNKNOWN").save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    public func setYandexConnect(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(IsYandexConnectRequest.self).flatMap { request in
            user.isYandexConnect = request.connect
            return user.save(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
    private func findUserByPhone(_ req: Request, phone: Phone) -> Future<User?> {
        return User.query(on: req).filter(\.phoneNumber, .equal, phone).first()
    }
    
}

// MARK: Content

/// Data required to create a user.
struct CreateUserRequest: Content {
    /// User's full name.
    let name: String
    
    /// User's email address.
    let phoneNumber: Phone

}

struct ConfirmPhone: Content {
    
    /// Сгенерированный код
    let code: String
    
    /// Номер телефона для проверки
    let phoneNumber: Phone
}

/// Public representation of user data.
struct UserResponse: Content {
    /// User's unique identifier.
    /// Not optional since we only return users that exist in the DB.
    var id: Int
    
    /// User's full name.
    var name: String
}

struct AddPurposeMemberRequest: Content {
    let state: String
    let purposeId: Int
}

struct EditUserInfoRequest: Content {
    let name: String
    let imagePath: String
}

struct TokenRequest: Content {
    let token: String
}

struct IsYandexConnectRequest: Content {
    let connect: Bool
}

extension Phone {
    func isAwailableFormat() throws -> Bool {
        
        guard self.endIndex.encodedOffset == 10 else { throw Abort(.badRequest, reason: "Номер телефона в неверном формате") }
        guard self[self.startIndex] == "9" else { throw Abort(.badRequest, reason: "Номер телефона в неверном формате") }
        return true

    }
}
