//
//  ApiRequestAsync.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire
import SwiftUI

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
    
    func uploadWithImage(url: String, withFile image: UIImage, parameters: [String: Any] = [:]) async throws -> String {
      try await withUnsafeThrowingContinuation { continuation in
        print("Uploading file to: " + baseURL + url)
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(image.pngData()!, withName: "file", fileName: "image.png", mimeType: "image/png")
          // Add any additional parameters here
          for (key, value) in parameters {
              multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
          }
        }, to: baseURL + url, usingThreshold: UInt64.max, method: .post, headers: getHeaders())
          .validate()
          .responseString { response in
              print(response)
            if let string = response.value {
                print("Upload Success: " + self.baseURL + url)
              continuation.resume(returning: string)
              return
            }
            if let err = response.error {
                print("Error Uploading: " + self.baseURL + url)
              print(err.asAFError?.responseCode ?? "")
              print(err.asAFError?.failureReason ?? "")
              continuation.resume(throwing: err)
              return
            }
            
            fatalError("Upload Request Failed")
        }
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
        
        if let phoneCongregationId = authorizationProvider.phoneCongregationId {
            headers.add(name: "phoneId", value: phoneCongregationId)
        }
        
        if let phoneCongregationPass = authorizationProvider.phoneCongregationPass {
            headers.add(name: "phonePass", value: phoneCongregationPass)
        }
        
        
        return headers
    }
}
