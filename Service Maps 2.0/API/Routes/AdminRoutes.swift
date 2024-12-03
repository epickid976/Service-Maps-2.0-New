//
//  AdminRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

import Foundation
@preconcurrency import Papyrus

@API
public protocol AdminRoutes: Sendable {
    
    @GET("admin/alldata")
    func allData() async throws -> AllDataResponse
    
    @GET("admin/all")
    func all() async throws -> CongregationWithAll
    
    @POST("admin/territories/add")
    func addTerritory(territory: Body<Territory>) async throws
    
    @Multipart
    @POST("admin/territories/add")
    func addTerritory(
        file: Part,
        congregation: Part,
        number: Part,
        description: Part,
        image: Part
    ) async throws
    
    @POST("admin/territories/update")
    func updateTerritory(territory: Body<Territory>)  async throws
    
    @Multipart
    @POST("admin/territories/update")
    func updateTerritory(
        file: Part,
        congregation: Part,
        number: Part,
        description: Part,
        image: Part
    ) async throws
    
    @POST("admin/territories/delete")
    func deleteTerritory(territory: Body<Territory>) async throws
    
    @POST("admin/territories/address/add")
    func addTerritoryAddress(territoryAddress: Body<TerritoryAddress>) async throws
    
    @POST("admin/territories/address/update")
    func updateTerritoryAddress(territoryAddress: Body<TerritoryAddress>) async throws
    
    @POST("admin/territories/address/delete")
    func deleteTerritoryAddress(territoryAddress: Body<TerritoryAddress>) async throws
    
    @POST("admin/houses/add")
    func addHouse(house: Body<House>) async throws
    
    @POST("admin/houses/update")
    func updateHouse(house: Body<House>) async throws
    
    @POST("admin/houses/delete")
    func deleteHouse(house: Body<House>) async throws
    
    @POST("admin/visits/add")
    func addVisit(visit: Body<Visit>) async throws
    
    @POST("admin/visits/update")
    func updateVisit(visit: Body<Visit>) async throws
    
    @POST("admin/visits/delete")
    func deleteVisit(visit: Body<Visit>) async throws
    
    @GET("admin/allphone")
    func allPhone() async throws -> CongregationWithAllPhone
    
    @GET("admin/allphonedata")
    func allPhoneData() async throws -> AllPhoneDataResponse
    
    @POST("admin/phone/territories/add")
    func addPhoneTerritory(phoneTerritory: Body<PhoneTerritory>) async throws
    
    @Multipart
    @POST("admin/phone/territories/add")
    func addPhoneTerritory(
        file: Part,
        congregation: Part,
        number: Part,
        description: Part,
        image: Part
    ) async throws
    
    @POST("admin/phone/territories/update")
    func updatePhoneTerritory(phoneTerritory: Body<PhoneTerritory>) async throws
    
    @Multipart
    @POST("admin/phone/territories/update")
    func updatePhoneTerritory(
        file: Part,
        congregation: Part,
        number: Part,
        description: Part,
        image: Part
    ) async throws
    
    @POST("admin/phone/territories/delete")
    func deletePhoneTerritory(phoneTerritory: Body<PhoneTerritory>) async throws
    
    @POST("admin/phone/numbers/add")
    func addPhoneNumber(phoneNumber: Body<PhoneNumber>) async throws
    
    @POST("admin/phone/numbers/update")
    func updatePhoneNumber(phoneNumber: Body<PhoneNumber>) async throws
    
    @POST("admin/phone/numbers/delete")
    func deletePhoneNumber(phoneNumber: Body<PhoneNumber>) async throws
    
    @POST("admin/phone/calls/add")
    func addPhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @POST("admin/phone/calls/update")
    func updatePhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @POST("admin/phone/calls/delete")
    func deletePhoneCall(phoneCall: Body<PhoneCall>) async throws
}
