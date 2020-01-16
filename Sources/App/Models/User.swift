import Authentication
import FluentSQLite
import Vapor

/// A registered user, capable of owning todo items.
final class User: SQLiteModel {
    /// User's unique identifier.
    /// Can be `nil` if the user has not been saved yet.
    var id: Int?
    
    /// Полное имя пользователя
    var name: String
    
    /// Телефон пользователя
    var phoneNumber: String
    
    /// Ссылка на аватар
    var imagePath: String?
    
    /// Признак подключения яндекс кошелька
    var isYandexConnect: Bool
    
    static let createdAtKey: TimestampKey? = \.createdAt
    static let updatedAtKey: TimestampKey? = \.updatedAt
    static let deletedAtKey: TimestampKey? = \.deletedAt

    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    /// Creates a new `User`.
    init(id: Int? = nil, name: String, phone: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phone
        self.isYandexConnect = false
    }
}

extension User {
    var payments: Children<User, Payment> {
        return children(\.userId)
    }
}

/// Allows users to be verified by bearer / token auth middleware.
extension User: TokenAuthenticatable {
    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}

typealias Code = String
typealias Phone = String

class AuthUserTmpData {
    
    
    static let shared = AuthUserTmpData()
    
    var tmpUserAndCodes: [UserData] = []
    
    private init() {}
    
    public func addCode(for phone: Phone, name: String) -> Code {
        
        let code = generateCode()
        print(code)
        let data = UserData(name: name, phone: phone, code: code)
        
        tmpUserAndCodes.removeAll { (userData) -> Bool in
            return userData.phone == data.phone
        }
        
        tmpUserAndCodes.append(data)
        return code
    }
    
    public func getCode(for phone: Phone) -> Code? {
        
        return tmpUserAndCodes.filter { res -> Bool in
            return res.phone == phone
            }.first?.code
        
    }
    
    public func getUserData(for phone: Phone) -> UserData {
        return tmpUserAndCodes.filter { res -> Bool in
            return res.phone == phone
        }.first!
    }
    
    public func removeUserData(for phone: Phone) {
        tmpUserAndCodes.removeAll { (res) -> Bool in
            return res.phone == phone
        }
    }
    
    private func generateCode() -> String {
        
        return Int.random(in: 1000...9999).description
    }
    
    struct UserData {
        let name: String
        let phone: Phone
        let code: String
    }
}
