//
//  UserRoutes.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 10/22/24.
//

@preconcurrency import Papyrus

//MARK: - User Routes

@API
public protocol UserRoutes: Sendable  {
    
    //MARK: - Load Data
    @GET("users/territories")
    func loadTerritories() async throws -> AllDataResponse
    
    @GET("users/load")
    func loadTerritoriesNew() async throws -> [TerritoryWithAll]
    
    @GET("users/loadphone")
    func loadPhoneNew() async throws -> CongregationWithAllPhone
    
    @GET("users/allphonedata")
    func allPhoneData() async throws -> AllPhoneDataResponse
    
    //MARK: - Territory CRUD
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
    
    //MARK: - Territory Address CRUD
    
    @POST("users/territories/address/update")
    func updateTerritoryAddress(territoryAddress: Body<TerritoryAddress>) async throws
    
    //MARK: - House CRUD
    
    @POST("users/houses/update")
    func updateHouse(house: Body<House>) async throws
    
    //MARK: - Visit CRUD
    
    @POST("users/visits/add")
    func addVisit(visit: Body<Visit>) async throws
    
    @POST("users/visits/update")
    func updateVisit(visit: Body<Visit>) async throws
    
    //MARK: - Phone Call CRUD
    
    @POST("users/phone/calls/add")
    func addPhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @POST("users/phone/calls/update")
    func updatePhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    @POST("users/phone/calls/delete")
    func deletePhoneCall(phoneCall: Body<PhoneCall>) async throws
    
    //MARK: - Recalls
    
    @GET("users/recalls")
    func getRecalls() async throws -> [Recalls]
    
    @POST("users/addRecall")
    func addRecall(recall: Body<Recalls>) async throws
    
    @POST("users/removeRecall")
    func removeRecall(recall: Body<Recalls>) async throws
}
