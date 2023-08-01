//
//  File.swift
//  
//
//  Created by Sergey Balalaev on 01.08.2023.
//

import Vapor
import FluentKit

final class ElectricCounterEntity: Model, Content {


    static var schema: String = "Counter"



    @ID(key: .id)
    var id: UUID?

    @Field(key: "dayCount")
    var dayCount: Int

    @Field(key: "nightCount")
    var nightCount: Int

    @Field(key: "email")
    var email: String

    // Creates a new, empty Galaxy.
    init() {
        self.id = nil
        self.dayCount = 0
        self.nightCount = 0
        self.email = ""

    }

    init(id: UUID? = nil, dayCount: Int, nightCount: Int, email: String? = nil) {
        self.id = id
        self.dayCount = dayCount
        self.nightCount = nightCount
        self.email = ""
    }


}

struct CreateElectricCounterEntity: AsyncMigration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) async throws {
        try await database.schema("Counter")
            .id()
            .field("dayCount", .int)
            .field("nightCount", .int)
            .field("email", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("Counter").delete()
    }
}
