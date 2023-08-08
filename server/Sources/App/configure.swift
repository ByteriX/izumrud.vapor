import Vapor
import Fluent
import FluentSQLiteDriver



// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)

    app.databases.use(.sqlite(.file("dbCounter.sqlite")), as: .sqlite)
    app.migrations.add(CreateElectricCounterEntity())

    try await app.autoMigrate()
}
