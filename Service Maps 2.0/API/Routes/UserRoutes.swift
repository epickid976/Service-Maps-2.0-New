//
//  UserRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

@preconcurrency import Papyrus
@API
public protocol UserRoutes: Sendable  {
    
    @GET("users/territories")
    func loadTerritories() async throws -> AllDataResponse
    
    @GET("users/allphonedata")
    func allPhoneData() async throws -> AllPhoneDataResponse
    
    @POST("users/territories/update")
    func updateTerritory(territory: Body<Territory>) async throws
    
    @Multipart
    @POST("users/territories/update")
    func updateTerritory(
        file: Part,
        congregation: String,
        number: String,
        description: String,
        image: String
    ) async throws
    
    @POST("users/territories/address/update")
    func updateTerritoryAddress(territoryAddress: Body<TerritoryAddress>) async throws
    
    @POST("users/houses/update")
    func updateHouse(house: Body<House>) async throws
    
    @POST("users/visits/add")
    func addVisit(visit: Body<Visit>) async throws
    
    @POST("users/visits/update")
    func updateVisit(visit: Body<Visit>) async throws
    
    @POST("users/phone/calls/add")
    func addPhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @POST("users/phone/calls/update")
    func updatePhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @POST("users/phone/calls/delete")
    func deletePhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @GET("users/recalls")
    func getRecalls() async throws -> [Recalls]
    
    @POST("users/addRecall")
    func addRecall(recall: Body<Recalls>) async throws
    
    @POST("users/removeRecall")
    func removeRecall(recall: Body<Recalls>) async throws
}
