//
//  ApiRequestAsync.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import SwiftUI
import Papyrus

class APIProvider {
    static let shared = APIProvider()

    let provider: Provider

    private init() {
        provider = Provider(baseURL: "https://servicemaps.ejvapps.online/api/")
            .modifyRequests { (req: inout RequestBuilder) in
                // Adding headers directly here instead of using a separate modifier
                let authorizationProvider = AuthorizationProvider.shared

                req.addHeader("Content-Type", value: "application/json")
                req.addHeader("X-Requested-With", value: "XMLHttpRequest")

                // Conditional headers based on the authorization provider
                if let authorizationToken = authorizationProvider.authorizationToken {
                    req.addHeader("Authorization", value: "Bearer \(authorizationToken)")
                }
                if let token = authorizationProvider.token {
                    req.addHeader("token", value: token)
                }
                if let congregationId = authorizationProvider.congregationId {
                    if congregationId != 0 {
                        req.addHeader("congregationId", value: String(congregationId))
                    }
                }
                if let congregationPass = authorizationProvider.congregationPass {
                    req.addHeader("congregationPass", value: congregationPass)
                }
                if let phoneCongregationId = authorizationProvider.phoneCongregationId {
                    req.addHeader("phoneId", value: phoneCongregationId)
                }
                if let phoneCongregationPass = authorizationProvider.phoneCongregationPass {
                    req.addHeader("phonePass", value: phoneCongregationPass)
                }
            }
            .intercept { req, next in
                // 🌐 Logging the Request
                print("\n🌐📤 Sending request to: \(req.url?.absoluteString ?? "Unknown URL")")
                print("🌐 Method: \(req.method)")
                print("🌐 Headers: \(req.headers)")
                if let body = req.body {
                    print("🌐 Body: \(String(describing: String(data: body, encoding: .utf8)))")
                }

                // Proceed with the request
                let start = Date()
                let response = try await next(req)

                // 💬 Logging the Response
                let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
                print("\n💬 Response received from: \(req.url?.absoluteString ?? "Unknown URL")")
                let statusCode = response.statusCode.map { "\($0)" } ?? "N/A"
                print("💬 Status Code: \(statusCode) (after \(elapsedTime))")
                if let body = response.body {
                    print("💬 Response Body: \(String(describing: String(data: body, encoding: .utf8)))")
                }

                return response
            }
    }
}

struct SharedHeaderModifier: RequestModifier {
    func modify(req: inout RequestBuilder) throws {
        let authorizationProvider = AuthorizationProvider.shared
        
        req.addHeader("Content-Type", value: "application/json")
        req.addHeader("X-Requested-With", value: "XMLHttpRequest")
        
        if let authorizationToken = authorizationProvider.authorizationToken {
            req.addHeader("Authorization", value: "Bearer \(authorizationToken)")
        }
        if let token = authorizationProvider.token {
            req.addHeader("token", value: token)
        }
        if let congregationId = authorizationProvider.congregationId {
            req.addHeader("congregationId", value: String(congregationId))
        }
        if let congregationPass = authorizationProvider.congregationPass {
            req.addHeader("congregationPass", value: congregationPass)
        }
        if let phoneCongregationId = authorizationProvider.phoneCongregationId {
            req.addHeader("phoneId", value: phoneCongregationId)
        }
        if let phoneCongregationPass = authorizationProvider.phoneCongregationPass {
            req.addHeader("phonePass", value: phoneCongregationPass)
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
