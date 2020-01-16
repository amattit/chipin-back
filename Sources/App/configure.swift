import Authentication
//import FluentSQLite
import Vapor
import FluentPostgreSQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
//    try services.register(FluentSQLiteProvider())
    try services.register(AuthenticationProvider())
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(SessionsMiddleware.self) // Enables sessions.
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
//    let sqlite = try SQLiteDatabase(storage: .memory)
    
    let psql = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: "clients01.qcaet9meah.postgresql.eu.vapor.cloud", port: 5432, username: "db526f8447c9cd5b2c", database: "db526f8447c9cd5b2c", password: "a697c461104f17a6", transport: .unverifiedTLS))

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
//    databases.enableLogging(on: .sqlite)
//    databases.add(database: sqlite, as: .sqlite)
    databases.add(database: psql, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserToken.self, database: .psql)
    migrations.add(model: Purpose.self, database: .psql)
    migrations.add(model: PurposeUser.self, database: .psql)
    migrations.add(model: Payment.self, database: .psql)
    services.register(migrations)

}
