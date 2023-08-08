//
//  SamaraEnergoController..swift
//  
//
//  Created by Sergey Balalaev on 01.08.2023.
//

import Vapor
import iSamaraCountersModels

extension SamaraEnergoData.GetRegistersData: Content {}
extension SamaraEnergoData.OutputData: Content {}

final class SamaraEnergoController {

    func getRegistry(_ request: Request) async throws -> SamaraEnergoData.GetRegistersData {
        SamaraEnergoData.GetRegistersData(results: [
            .init(deviceID: "", registerID: "", registerTypeID: "", readingUnit: "", integerPlaces: "", decimalPlaces: "", noMeterReadingOrderFlag: true, previousMeterReadingResult: "", previousMeterReadingDate: "", previousMeterReadingReasonID: "", previousMeterReadingCategoryID: "", serialNumber: "123"),
            .init(deviceID: "", registerID: "", registerTypeID: "", readingUnit: "", integerPlaces: "", decimalPlaces: "", noMeterReadingOrderFlag: true, previousMeterReadingResult: "", previousMeterReadingDate: "", previousMeterReadingReasonID: "", previousMeterReadingCategoryID: "", serialNumber: "123")
        ])
    }

    func postRegistry(_ request: Request) async throws -> SamaraEnergoData.OutputData {
        let params = try request.content.decode(SamaraEnergoData.InputData.self)
        if params.email == "" {
            throw Abort(.notFound)
        }
        if params.email == "!" {
            throw Abort(.custom(code: 417, reasonPhrase: "rrrr"))
        }

        guard let dayCount = Int(params.readingResult),
              let nightCount = Int(params.dependentMeterReadingResults.first?.readingResult ?? "")
        else {
            throw Abort(.badRequest)
        }

        if let entity = try await request.db(.sqlite).query(ElectricCounterEntity.self).first() {
            entity.email = params.email
            entity.dayCount = dayCount
            entity.nightCount = nightCount
            try await entity.update(on: request.db(.sqlite))
        } else {
            let entity = ElectricCounterEntity(dayCount: dayCount, nightCount: nightCount, email: params.email)
            try await entity.create(on: request.db(.sqlite))
        }
        return .init(d: .init(deviceID: "", meterReadingNoteID: "", readingResult: "", registerID: "", readingDateTime: "", contractAccountID: "", email: "", meterReadingResultID: "", consumption: "", meterReadingReasonID: "", meterReadingCategoryID: "", meterReadingStatusID: "", multipleMeterReadingReasonsFlag: true))
    }

    func getInfo(_ request: Request) async throws -> ElectricCounterEntity {
        guard let entity = try await request.db(.sqlite).query(ElectricCounterEntity.self).first() else {
            throw Abort(.notFound)
        }
        return entity
    }

}
