import Crypto
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    let purposeController = PurposeController()
//    router.post("users", use: userController.create)
    
    // bearer / token auth protected routes
    let bearer = router.grouped(User.tokenAuthMiddleware())
    
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.post("authorize", use: userController.authorize)
    router.post("authorize", "code", use: userController.checkCode)
    
    bearer.post("purpose", use: purposeController.createPurpose)
    bearer.get("purpose", use: purposeController.fetchPurposeWhereUserIsPresent)
    bearer.get("purpose", Int.parameter, use: purposeController.fetchPurposeById)
    bearer.delete("purpose", Int.parameter, use: purposeController.archivePurpose)
    bearer.put("purpose", Int.parameter, use: purposeController.archivePurpose)
    
    bearer.put("person", "state", use: userController.addPurposeMember)
    
    bearer.get("purpose", "find", use: purposeController.findByState)
//    bearer.get("purpose", "find", use: purposeController.findInitialPurpose)
    
}
