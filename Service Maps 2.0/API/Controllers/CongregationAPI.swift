//
//  CongregationAPI.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 7/31/23.
//

import Foundation
import Alamofire

class CongregationAPI {
    let baseURL = ApiRequestAsync().baseURL + "congregation/"
    
    func signIn(congregationId: Int64, congregationPass: String) async throws -> CongregationResponse {
        do {
            let response = try await ApiRequestAsync().postRequest(url: baseURL + "sign", body: CongregationSignInForm(id: congregationId, password: congregationPass))
            let decoder = JSONDecoder()
            let jsonData = response.data(using: .utf8)!
            
            let congregationResponse = try decoder.decode(CongregationResponse.self, from: jsonData)
            
            return congregationResponse
        } catch {
            throw error.self
        }
    }
}
