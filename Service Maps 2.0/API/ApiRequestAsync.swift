//
//  ApiRequestAsync.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire

class ApiRequestAsync {
    
    let baseURL = "https://servicemaps.ejvapps.online/api/"
    
    //MARK: FUNCS
    func getRequest(url:String) async throws -> String {
        try await withUnsafeThrowingContinuation { continuation in
            AF.request("\(baseURL)\(url)", method: .get, headers: HTTPHeaders(getHeaders())).validate().responseString { response in
                if let string = response.value {
                    continuation.resume(returning: string)
                    return
                }
                if let err = response.error {
                    continuation.resume(throwing: err)
                    return
                }
                
                fatalError("GET Request Failed")
            }
        }
    }
    
    func postRequest<T: Encodable>(url:String, body: T) async throws -> String {
        try await withUnsafeThrowingContinuation { continuation in
            AF.request("\(baseURL)\(url)", method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: HTTPHeaders(getHeaders())).validate().responseString { response in
                if let string = response.value {
                    continuation.resume(returning: string)
                    return
                }
                if let err = response.error {
                    continuation.resume(throwing: err)
                    return
                }
                
                fatalError("POST Request Failed")
            }
        }
    }
    
    //MARK: Interceptor
    private func getHeaders() -> [String:String] {
        let authorizationProvider = AuthorizationProvider()
        
        var dictionary = ["Content-Type" : "application/json", "X-Requested-With": "XMLHttpRequest"]
        
        if let authorizationToken = authorizationProvider.authorizationToken { dictionary.updateValue("Authorization", forKey: "Bearer + \(authorizationToken)") }
        
        if let token = authorizationProvider.token { dictionary.updateValue("token", forKey: token) }
        
        if let congregationId = authorizationProvider.congregationId { dictionary.updateValue("congregationId", forKey: String(congregationId)) }
        
        if let congregationPass = authorizationProvider.congregationPass { dictionary.updateValue("congregationPass", forKey: congregationPass) }
        
        return dictionary
    }
}
