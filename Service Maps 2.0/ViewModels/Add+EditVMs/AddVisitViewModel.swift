//
//  AddTerritoryViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//


import Foundation
import SwiftUI
import Alamofire

// MARK: - AddVisitViewModel
@MainActor
class AddVisitViewModel: ObservableObject {
    
    // MARK: - Initializers
    init(house: House) {
        error = ""
        self.house = house
    }
    
    // MARK: - Dependencies
    @Published private var dataUploader = DataUploaderManager()
    
    // MARK: - Published Properties
    @Published var notes = ""
    
    @Published var selectedOption: Symbols = .none
    
    @Published var house: House
    
    @Published var error = ""
    
    @Published var loading = false
    
    // MARK: - Functions
    @BackgroundActor
    func addVisit() async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation { loading = true }
        }
        let date = Date.now.millisecondsSince1970
        let visitObject = await Visit(id: "\(house.id)-\(date)", house: house.id, date: (date), symbol: selectedOption.forServer, notes: notes, user: StorageManager.shared.userEmail ?? "")
        return await dataUploader.addVisit(visit: visitObject)
    }
    
    @BackgroundActor
    func editVisit(visit: Visit) async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation { loading = true }
        }
        let visitObject = await Visit(id: visit.id, house: house.id, date: visit.date, symbol: selectedOption.forServer, notes: notes, user: StorageManager.shared.userEmail ?? "")
        return await dataUploader.updateVisit(visit: visitObject)
    }
    
    func checkInfo() -> Bool {
        if notes.isEmpty && selectedOption == .none {
            error = NSLocalizedString("At least one field is required.", comment: "")
            return false
        } else if notes.isEmpty {
            notes = selectedOption.legend
            return true
        } else {
            return true
        }
    }
    
    // Inside AddVisitViewModel
    func fillWithLastVisit() async {
        if let lastVisit = await fetchLastVisit() {
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notes = lastVisit.notes
                    self.selectedOption = Symbols(rawValue: lastVisit.symbol.uppercased()) ?? .none
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.error = NSLocalizedString("No previous visit found.", comment: "")
            }
        }
    }

    // Placeholder for actual implementation
    private func fetchLastVisit() async -> Visit? {
        // Fetch your last visit from your data source
        let result = await GRDBManager.shared.fetchAllAsync(Visit.self)
        switch result {
        case .success(let visits):
            return visits.filter { $0.house == house.id }.max(by: { $0.date < $1.date })
        case .failure:
            return nil
        }
    }

    // MARK: - Error Handling
    func getErrorMessage(for error: Error) -> String {
        if let customError = error as? CustomErrors {
            switch customError {
            case .WrongCredentials:
                return NSLocalizedString("Authentication required. Please log in again.", comment: "")
            case .NoInternet:
                return NSLocalizedString("No internet connection. Please check your network and try again.", comment: "")
            case .Duplicate:
                return NSLocalizedString("This visit already exists.", comment: "")
            case .NotFound:
                return NSLocalizedString("Required data not found.", comment: "")
            case .ErrorUploading:
                return NSLocalizedString("Failed to upload visit data.", comment: "")
            case .ServerBlocked:
                return NSLocalizedString("Server is temporarily blocking requests. Please try again later or contact support.", comment: "")
            case .CaptchaRequired:
                return NSLocalizedString("Server requires verification. Please try again later or contact support.", comment: "")
            default:
                return NSLocalizedString("An unexpected error occurred.", comment: "")
            }
        } else if let afError = error.asAFError {
            switch afError.responseCode {
            case .some(401):
                return NSLocalizedString("Authentication expired. Please log in again.", comment: "")
            case .some(403):
                return NSLocalizedString("You don't have permission to add visits.", comment: "")
            case .some(422):
                return NSLocalizedString("Invalid visit data. Please check your information.", comment: "")
            case .some(500...599):
                return NSLocalizedString("Server error. Please try again later.", comment: "")
            default:
                return NSLocalizedString("Network error. Please check your connection.", comment: "")
            }
        } else if let nsError = error as NSError? {
            // Handle specific network/TLS errors
            switch nsError.code {
            case NSURLErrorServerCertificateUntrusted:
                return NSLocalizedString("Security certificate error. Please check your internet connection.", comment: "")
            case NSURLErrorSecureConnectionFailed:
                return NSLocalizedString("Secure connection failed. Please try again.", comment: "")
            case NSURLErrorCannotConnectToHost:
                return NSLocalizedString("Cannot connect to server. Please check your internet connection.", comment: "")
            case NSURLErrorTimedOut:
                return NSLocalizedString("Connection timed out. Please try again.", comment: "")
            case NSURLErrorCancelled:
                return NSLocalizedString("Request was cancelled. Please try again.", comment: "")
            case NSURLErrorNotConnectedToInternet:
                return NSLocalizedString("No internet connection. Please check your network.", comment: "")
            default:
                return NSLocalizedString("Connection error. Please check your internet and try again.", comment: "")
            }
        } else {
            return NSLocalizedString("Failed to save visit. Please try again.", comment: "")
        }
    }
    
}
