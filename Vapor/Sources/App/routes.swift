import Vapor

func routes(_ app: Application) throws {

    let controller = SamaraEnergoController()

    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    /// sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/GetRegistersToRead
    app.get("sap", "**", use: controller.getRegistry)
    /// sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/MeterReadingResults
    app.post("sap", "**", use: controller.postRegistry)
    ///
    ///
    ///

    app.get("info", use: controller.getInfo)
}
