//
//  WorkerManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/4/23.
//

import Foundation
import BackgroundTasks

class ReuploaderWorker {
    let dataUploaderManager = DataUploaderManager()
    let authorizationLevelManager = AuthorizationLevelManager()
    
    static let shared = ReuploaderWorker()
    
    func handleReupload(task: BGProcessingTask) {
        //do task
        Task {
            if await !doWork() {
                scheduleReupload(minutes: 15)
            }
        }
    }
    
    func scheduleReupload(minutes: Double, onError: (() -> Void)? = nil) {
        let request = BGProcessingTaskRequest(identifier: "com.serviceMaps.uploadPendingTasks")
        
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: minutes * 60)
        
        BGTaskScheduler.shared.cancelAllTaskRequests()
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            if let error = onError { error() }
        }
    }
    
    private func doWork() async -> Bool {
        
        for pendingChange in await dataUploaderManager.getAllPendingChanges() {
            var adminApi = AdminAPI()
            var userAPi = UserAPI()
            var isAdmin = authorizationLevelManager.existsAdminCredentials()
            
            var done = switch pendingChange.changeType {
            case .Territory:
                await tryAction(pendingChange: pendingChange, items: DataController.shared.getTerritories()) { model in
                    model.id ?? ""
                } onAdd: { model in
                    do {
                        try await adminApi.addTerritory(territory: convertTerritoryToTerritoryModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onUpdate: { model in
                    
                    do {
                        if isAdmin {
                            try await adminApi.updateTerritory(territory: convertTerritoryToTerritoryModel(model: model))
                        } else {
                            try await userAPi.updateTerritory(territory: convertTerritoryToTerritoryModel(model: model))
                        }
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDelete: { model in
                    do {
                        try await adminApi.deleteTerritory(territory: convertTerritoryToTerritoryModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDeleteSuccess: { model in
                    DataController.shared.container.viewContext.delete(model)
                }

            case .House:
                await tryAction(pendingChange: pendingChange, items: DataController.shared.getHouses()) { model in
                    model.id ?? ""
                } onAdd: { model in
                    do {
                        try await adminApi.addHouse(house: convertHouseToHouseModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onUpdate: { model in
                    
                    do {
                        if isAdmin {
                            try await adminApi.updateHouse(house: convertHouseToHouseModel(model: model))
                        } else {
                            try await userAPi.updateHouse(house: convertHouseToHouseModel(model: model))
                        }
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDelete: { model in
                    do {
                        try await adminApi.deleteHouse(house: convertHouseToHouseModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDeleteSuccess: { model in
                    DataController().container.viewContext.delete(model)
                }
                
            case .Visit:
                await tryAction(pendingChange: pendingChange, items: DataController.shared.getVisits()) { model in
                    model.id ?? ""
                } onAdd: { model in
                    do {
                        try await adminApi.addVisit(visit: convertVisitToVisitModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onUpdate: { model in
                    
                    do {
                        if isAdmin {
                            try await adminApi.updateVisit(visit: convertVisitToVisitModel(model: model))
                        } else {
                            try await userAPi.updateVisit(visit: convertVisitToVisitModel(model: model))
                        }
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDelete: { model in
                    do {
                        try await adminApi.deleteVisit(visit: convertVisitToVisitModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDeleteSuccess: { model in
                    DataController.shared.container.viewContext.delete(model)
                }
                
            case .TerritoryAddress:
                await tryAction(pendingChange: pendingChange, items: DataController.shared.getTerritoryAddresses()) { model in
                    model.id ?? ""
                } onAdd: { model in
                    do {
                        try await adminApi.addTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onUpdate: { model in
                    
                    do {
                        if isAdmin {
                            try await adminApi.updateTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: model))
                        } else {
                            try await userAPi.updateTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: model))
                        }
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDelete: { model in
                    do {
                        try await adminApi.deleteTerritoryAddress(territoryAddress: convertTerritoryToTerritoryAddressModel(model: model))
                        return Result.success(true)
                    } catch {
                        return Result.failure(error)
                    }
                } onDeleteSuccess: { model in
                    DataController.shared.container.viewContext.delete(model)
                }
            }
            
            if done {
                if let index = StorageManager.shared.pendingChanges.firstIndex(where: { $0.modelId == pendingChange.modelId}) {
                    StorageManager.shared.pendingChanges.remove(at: index)
                }
            }
            
        }
        if await !dataUploaderManager.getAllPendingChanges().isEmpty {
            return false
        }
        
        return true
    }
    
    private func tryAction<T>(
        pendingChange: PendingChange,
        items: [T],
        getId: @escaping (T) -> String,
        onAdd: @escaping (T)  async -> Result<Bool, Error>,
        onUpdate: @escaping (T) async -> Result<Bool, Error>,
        onDelete: @escaping (T) async -> Result<Bool, Error>,
        onDeleteSuccess: @escaping (T) async -> Void
    ) async -> Bool {
        if let model = items.first(where: { getId($0) == pendingChange.modelId }) {
            switch pendingChange.changeAction {
            case .Add:
                let result = await onAdd(model)
                
                return switch result {
                case .success(true): 
                    true
                default:
                    false
                }
            case .Update:
                let result = await onUpdate(model)
                
                return switch result {
                case .success(true):
                    true
                default:
                    false
                }
            case .Delete:
                let result = await onDelete(model)
                
                switch result {
                case .success(true):
                    await onDeleteSuccess(model)
                default:
                    print("NOTHING")
                }
                
                return switch result {
                case .success(true):
                    true
                default:
                    false
                }
            }
        }
        return true
    }
    
    
    
    
}
