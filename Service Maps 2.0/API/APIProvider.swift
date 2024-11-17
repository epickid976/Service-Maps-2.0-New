//
//  ApiRequestAsync.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import SwiftUI
@preconcurrency import Papyrus


class APIProvider {
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
    
    let provider: Provider
    
    private enum APIError: Error {
        case invalidSelf
        case authDataUnavailable
    }

    init() {
        provider = Self.makeProvider()
    }
    
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


//class ApiRequestAsync {
//    
//    let baseURL = "https://servicemaps.ejvapps.online/api/"
//    
//    //MARK: FUNCS
//    func getRequest(url:String) async throws -> String {
//        try await withUnsafeThrowingContinuation { continuation in
//            
//            AF.request("\(baseURL)\(url)", method: .get, headers: getHeaders()).responseString { response in
//                if let string = response.value {
//                    
//                    continuation.resume(returning: string)
//                    return
//                }
//                if let err = response.error {
//                    print(err)
//                    continuation.resume(throwing: err)
//                    return
//                }
//                
//                fatalError("GET Request Failed")
//            }
//        }
//    }
//    
//    func postRequest<T: Encodable>(url: String, body: T) async throws -> String {
//        try await withUnsafeThrowingContinuation { continuation in
//            
//            AF.request("\(baseURL)\(url)", method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: getHeaders())
//                .validate()
//                .responseData { response in
//                    
//                    // Print the full response for debugging
//                    if let data = response.data {
//                        if let responseBody = String(data: data, encoding: .utf8) {
//                            print("Full Response Body: \(responseBody)")
//                        }
//                    }
//                    
//                    // Print status code and headers
//                    print("Status Code: \(response.response?.statusCode ?? 0)")
//                    print("Headers: \(response.response?.allHeaderFields ?? [:])")
//                    
//                    // Handle the response string
//                    switch response.result {
//                    case .success(let data):
//                        if let responseString = String(data: data, encoding: .utf8) {
//                            continuation.resume(returning: responseString)
//                        } else {
//                            continuation.resume(throwing: URLError(.badServerResponse))
//                        }
//                    case .failure(let error):
//                        print("Error: \(error)")
//                        continuation.resume(throwing: error)
//                    }
//                }
//        }
//    }
//    
//    func uploadWithImage(url: String, withFile image: UIImage, parameters: [String: Any] = [:]) async throws -> String {
//      try await withUnsafeThrowingContinuation { continuation in
//        
//        
//        AF.upload(multipartFormData: { multipartFormData in
//            multipartFormData.append(image.pngData()!, withName: "file", fileName: "image.png", mimeType: "image/png")
//          // Add any additional parameters here
//          for (key, value) in parameters {
//              multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
//          }
//        }, to: baseURL + url, usingThreshold: UInt64.max, method: .post, headers: getHeaders())
//          .validate()
//          .responseString { response in
//              
//            if let string = response.value {
//                
//              continuation.resume(returning: string)
//              return
//            }
//            if let err = response.error {
//                print(err)
//              continuation.resume(throwing: err)
//              return
//            }
//            
//            fatalError("Upload Request Failed")
//        }
//      }
//    }
//
//    
//    //MARK: Interceptor
//    private func getHeaders() -> HTTPHeaders {
//        
//        var headers = HTTPHeaders()
//
//        let authorizationProvider = AuthorizationProvider.shared
//        
//        headers.add(name: "Content-Type", value: "application/json")
//        headers.add(name: "X-Requested-With", value: "XMLHttpRequest")
//        
//        
//        
//        if let authorizationToken = authorizationProvider.authorizationToken {
//            headers.add(name: "Authorization", value: "Bearer \(authorizationToken)")
//            }
//        
//        if let token = authorizationProvider.token {
//            headers.add(name: "token", value: token)
//        }
//        
//        if let congregationId = authorizationProvider.congregationId {
//            headers.add(name: "congregationId", value: String(congregationId))
//        }
//        
//        if let congregationPass = authorizationProvider.congregationPass {
//            headers.add(name: "congregationPass", value: congregationPass)
//        }
//        
//        if let phoneCongregationId = authorizationProvider.phoneCongregationId {
//            headers.add(name: "phoneId", value: phoneCongregationId)
//        }
//        
//        if let phoneCongregationPass = authorizationProvider.phoneCongregationPass {
//            headers.add(name: "phonePass", value: phoneCongregationPass)
//        }
//        
//        
//        return headers
//    }
//}
