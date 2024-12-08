//
//  ApiRequestAsync.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import SwiftUI
@preconcurrency import Papyrus

// MARK: - API Provider

class APIProvider {
    
    //MARK: - Headers
    
    private enum HeaderKeys {
        static let contentType = "Content-Type"
        static let xRequestedWith = "X-Requested-With"
        static let authorization = "Authorization"
        static let token = "token"
        static let congregationId = "congregationId"
        static let congregationPass = "congregationPass"
        static let phoneId = "phoneId"
        static let phonePass = "phonePass"
    }
    
    //MARK: - Properties
    
    let provider: Provider
    
    private enum APIError: Error {
        case invalidSelf
        case authDataUnavailable
    }

    //MARK: - Initialization
    
    init() {
        provider = Self.makeProvider()
    }
    
    //MARK: - Methods
    // Fetch auth data from main actor in a way that can be cached
    @BackgroundActor
    private static func getAuthHeaders() async throws -> [String: String] {
        // Switch to main actor just for fetching the auth data
            var headers: [String: String] = [:]
        let auth = await AuthorizationProvider.shared
            
        if let token = await auth.authorizationToken {
                headers[HeaderKeys.authorization] = "Bearer \(token)"
            }
        if let token = await auth.token {
                headers[HeaderKeys.token] = token
            }
        if let congregationId = await auth.congregationId, congregationId != 0 {
                headers[HeaderKeys.congregationId] = String(congregationId)
            }
        if let congregationPass = await auth.congregationPass {
                headers[HeaderKeys.congregationPass] = congregationPass
            }
        if let phoneId = await auth.phoneCongregationId {
                headers[HeaderKeys.phoneId] = phoneId
            }
        if let phonePass = await auth.phoneCongregationPass {
                headers[HeaderKeys.phonePass] = phonePass
            }
            
            return headers
    }
    
    private static func makeProvider() -> Provider {
        return Provider(baseURL: "https://servicemaps.ejvapps.online/api/")
            .modifyRequests { (req: inout RequestBuilder) in
                // Set base headers
                req.headers = [
                    HeaderKeys.contentType: "application/json",
                    HeaderKeys.xRequestedWith: "XMLHttpRequest"
                ]
            }
            .intercept { [self] request, next in
                
                // Create mutable copy of the request
                var modifiedRequest = request
                
                // Fetch auth headers before making the request
                let authHeaders = try await getAuthHeaders()
                
                // Add auth headers to the request
                modifiedRequest.headers.merge(authHeaders) { current, _ in current }
                
                // Log request
                #if DEBUG
                print("\n🌐📤 REQUEST:")
                print("📍 URL: \(modifiedRequest.url?.absoluteString ?? "Unknown URL")")
                print("🔄 Method: \(modifiedRequest.method)")
                print("📋 Headers: \(modifiedRequest.headers)")
                if let body = modifiedRequest.body,
                   let bodyString = String(data: body, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    print("📦 Body: \(bodyString)")
                }
                #endif
                
                // Track timing and execute request
                let start = Date()
                let response = try await next(modifiedRequest)
                let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
                
                // Log response
                #if DEBUG
                print("\n💬 RESPONSE:")
                print("📍 URL: \(modifiedRequest.url?.absoluteString ?? "Unknown URL")")
                print("⏱ Time: \(elapsedTime)")
                print("📊 Status: \(response.statusCode.map(String.init) ?? "N/A")")
                
                if let body = response.body,
                   let bodyString = String(data: body, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    print("📦 Body: \(bodyString)")
                }
                
                if let error = response.error {
                    print("❌ Error: \(error)")
                }
                print("Complete response \(response)")
                #endif
                
                return response
            }
    }
}
