//
//  ApiRequestAsync.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import SwiftUI
import UIKit
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
        // Create proper User-Agent to avoid server blocking
        let bundleId = Bundle.main.bundleIdentifier ?? "com.servicemaps.app"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let userAgent = "ServiceMaps/\(version) iOS/\(systemVersion) (\(bundleId))"
        
        return Provider(baseURL: "https://servicemaps.ejvapps.online/api/")
            .modifyRequests { (req: inout RequestBuilder) in
                // Set base headers
                req.headers[HeaderKeys.contentType] = "application/json"
                req.headers[HeaderKeys.xRequestedWith] = "XMLHttpRequest"
                
                // Add browser-like headers to avoid server blocking
                req.headers["User-Agent"] = userAgent
                req.headers["Accept"] = "application/json"
                req.headers["Accept-Language"] = Locale.current.languageCode ?? "en"
                req.headers["Accept-Encoding"] = "gzip, deflate, br"
                req.headers["Connection"] = "keep-alive"
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
                    
                    // Log specific TLS/SSL errors
                    if let nsError = error as NSError? {
                        switch nsError.code {
                        case NSURLErrorServerCertificateUntrusted:
                            print("🔒 TLS Error: Server certificate untrusted")
                        case NSURLErrorSecureConnectionFailed:
                            print("🔒 TLS Error: Secure connection failed")
                        case NSURLErrorCannotConnectToHost:
                            print("🔒 TLS Error: Cannot connect to host")
                        case NSURLErrorTimedOut:
                            print("⏰ TLS Error: Connection timed out")
                        case NSURLErrorCancelled:
                            print("❌ Request was cancelled")
                        case NSURLErrorNotConnectedToInternet:
                            print("🌐 Network Error: Not connected to internet")
                        default:
                            print("🔍 Error details - Domain: \(nsError.domain), Code: \(nsError.code)")
                            if let userInfo = nsError.userInfo as? [String: Any] {
                                print("🔍 User Info: \(userInfo)")
                            }
                        }
                    }
                }
                print("Complete response \(response)")
                #endif
                
                // Check for CAPTCHA/HTML responses - only for error responses or suspicious content
                if let statusCode = response.statusCode,
                   statusCode != 200,  // Don't check successful responses
                   let body = response.body,
                   let bodyString = String(data: body, encoding: .utf8) {
                    
                    // Check content type headers safely
                    var isHtmlResponse = false
                    if let contentTypeHeaders = response.headers?["Content-Type"] {
                        // Convert headers to string representation and check for HTML
                        let contentTypeString = "\(contentTypeHeaders)"
                        isHtmlResponse = contentTypeString.lowercased().contains("text/html")
                    }
                    
                    // Also check body content for HTML indicators
                    let bodyLower = bodyString.lowercased()
                    if isHtmlResponse || bodyLower.contains("<html") || bodyLower.contains("<!doctype html") {
                        if bodyString.contains("Bot Verification") || bodyString.contains("recaptcha") {
                            print("🚨 CAPTCHA detected in API response - Server requires verification")
                            throw CustomErrors.CaptchaRequired
                        } else {
                            print("🚨 HTML response detected instead of JSON - Server blocked request")
                            throw CustomErrors.ServerBlocked
                        }
                    }
                } else if let body = response.body,
                          let bodyString = String(data: body, encoding: .utf8) {
                    // For successful responses, only check for obvious blocking patterns
                    if bodyString.contains("Bot Verification") || bodyString.contains("recaptcha") {
                        print("🚨 CAPTCHA detected in successful response - Server requires verification")
                        throw CustomErrors.CaptchaRequired
                    }
                }
                
                return response
            }
    }
}
