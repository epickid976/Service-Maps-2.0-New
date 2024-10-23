//
//  AdminRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
import Papyrus

@API
public protocol AdminRoutes {
    
    @GET("admin/alldata")
    func allData() async throws -> AllDataResponse
    
    @POST("admin/territories/add")
    func addTerritory(territory: Territory) async throws
    
    @Multipart
    @POST("admin/territories/add")
    func addTerritory(
        file: Part,
        congregation: String,
        number: String,
        description: String,
        image: String
    ) async throws
    
    @POST("admin/territories/update")
    func updateTerritory(territory: Territory)  async throws
    
    @Multipart
    @POST("admin/territories/update")
    func updateTerritory(
        file: Part,
        congregation: String,
        number: String,
        description: String,
        image: String
    ) async throws
    
    @POST("admin/territories/delete")
    func deleteTerritory(territory: Territory) async throws
    
    @POST("admin/territories/address/add")
    func addTerritoryAddress(territoryAddress: TerritoryAddress) async throws
    
    @POST("admin/territories/address/update")
    func updateTerritoryAddress(territoryAddress: TerritoryAddress) async throws
    
    @POST("admin/territories/address/delete")
    func deleteTerritoryAddress(territoryAddress: TerritoryAddress) async throws
    
    @POST("admin/houses/add")
    func addHouse(house: House) async throws
    
    @POST("admin/houses/update")
    func updateHouse(house: House) async throws
    
    @POST("admin/houses/delete")
    func deleteHouse(house: House) async throws
    
    @POST("admin/visits/add")
    func addVisit(visit: Visit) async throws
    
    @POST("admin/visits/update")
    func updateVisit(visit: Visit) async throws
    
    @POST("admin/visits/delete")
    func deleteVisit(visit: Visit) async throws
    
    @GET("admin/allphonedata")
    func allPhoneData() async throws -> AllPhoneDataResponse
    
    @POST("admin/phone/territories/add")
    func addPhoneTerritory(phoneTerritory: PhoneTerritory) async throws
    
    @Multipart
    @POST("admin/phone/territories/add")
    func addPhoneTerritory(
        file: Part,
        congregation: String,
        number: String,
        description: String,
        image: String
    ) async throws
    
    @POST("admin/phone/territories/update")
    func updatePhoneTerritory(phoneTerritory: PhoneTerritory) async throws
    
    @Multipart
    @POST("admin/phone/territories/update")
    func updatePhoneTerritory(
        file: Part,
        congregation: String,
        number: String,
        description: String,
        image: String
    ) async throws
    
    @POST("admin/phone/territories/delete")
    func deletePhoneTerritory(phoneTerritory: PhoneTerritory) async throws
    
    @POST("admin/phone/numbers/add")
    func addPhoneNumber(phoneNumber: PhoneNumber) async throws
    
    @POST("admin/phone/numbers/update")
    func updatePhoneNumber(phoneNumber: PhoneNumber) async throws
    
    @POST("admin/phone/numbers/delete")
    func deletePhoneNumber(phoneNumber: PhoneNumber) async throws
    
    @POST("admin/phone/calls/add")
    func addPhoneCall(phoneCall: PhoneCall) async throws
    
    @POST("admin/phone/calls/update")
    func updatePhoneCall(phoneCall: PhoneCall) async throws
    
    @POST("admin/phone/calls/delete")
    func deletePhoneCall(phoneCall: PhoneCall) async throws
}
