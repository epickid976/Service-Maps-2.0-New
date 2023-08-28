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
            print(" Making GET: " + baseURL + url)
            AF.request("\(baseURL)\(url)", method: .get, headers: getHeaders()).responseString { response in
                if let string = response.value {
                    print("Get Success: " + self.baseURL + url)
                    continuation.resume(returning: string)
                    return
                }
                if let err = response.error {
                    print("Error: " + self.baseURL + url)
                    print(err.asAFError?.responseCode ?? "")
                    print(err.asAFError?.failureReason ?? "")
                    continuation.resume(throwing: err)
                    return
                }
                
                fatalError("GET Request Failed")
            }
        }
    }
    
    func postRequest<T: Encodable>(url:String, body: T) async throws -> String {
        try await withUnsafeThrowingContinuation { continuation in
            print(" Making POST: " + baseURL + url)
            AF.request("\(baseURL)\(url)", method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: getHeaders()).validate().responseString { response in
                if let string = response.value {
                    print("POST Success: " + self.baseURL + url)
                    continuation.resume(returning: string)
                    return
                }
                if let err = response.error {
                    print("Error Post: " + self.baseURL + url)
                    print(err.asAFError?.responseCode ?? "")
                    print(err.asAFError?.failureReason ?? "")
                    continuation.resume(throwing: err)
                    return
                }
                
                fatalError("POST Request Failed")
                
            }
            //print(request.acceptableStatusCodes.debugDescription)
        }
    }
    
    //MARK: Interceptor
    private func getHeaders() -> HTTPHeaders {
        
        var headers = HTTPHeaders()

        let authorizationProvider = AuthorizationProvider.shared
        
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "X-Requested-With", value: "XMLHttpRequest")
        
        
        
        if let authorizationToken = authorizationProvider.authorizationToken {
            headers.add(name: "Authorization", value: "Bearer  \(authorizationToken)")
            }
        
        if let token = authorizationProvider.token {
            headers.add(name: "token", value: token)
        }
        
        if let congregationId = authorizationProvider.congregationId {
            headers.add(name: "congregationId", value: String(congregationId))
        }
        
        if let congregationPass = authorizationProvider.congregationPass {
            headers.add(name: "congregationPass", value: congregationPass)
        }
        
        
        return headers
    }
}
