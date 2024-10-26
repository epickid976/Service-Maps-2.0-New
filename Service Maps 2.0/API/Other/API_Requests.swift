//
//  API_Manager.swift
//  Bussiness App
//
//  Created by Jose Blanco on 7/3/23.
//
//
//import Foundation
//import Alamofire
//
//class API_Requests {
//    
//    let baseURL = "https://servicemaps.ejvapps.online/api/"
//    
//    
//    //GET Request
//    func getRequest(url: String, headers: [String:String] ,result: @escaping (String?, Error?) -> Void) {
//        AF.request("\(baseURL)\(url)", headers: HTTPHeaders(headers))
//            .validate()
//            .responseString { response in
//                switch response.result {
//                    //Receive code, check if good or bad
//                case .success:
//                    
//                    
//                    result(response.value, nil)
//                    
//                case let .failure(error):
//                    
//                    result(nil, error)
//                }
//            }
//    }
//    
//    //POST Request
//    func postRequest<T: Encodable>(url: String, headers: [String:String], body: T, method: HTTPMethod, result: @escaping (String?, Error?) -> Void) {
//        //Send request to server
//        AF.request("\(baseURL)\(url)", method: method, parameters: body, encoder: JSONParameterEncoder.default, headers: HTTPHeaders(headers))
//            .validate()
//            .responseString { response in
//                switch response.result {
//                    //Receive code, check if good or bad
//                case .success:
//                    
//                    debugPrint(response)
//                    result(response.value, nil)
//                    
//                case let .failure(error):
//                    
//                    debugPrint(response)
//                    result(nil, error)
//                }
//            }
//    }
//    
//    func buildUrl(baseUrl: String, url: String) -> String {
//        return "\(baseUrl)\(url)"
//    }
//    
//    
//}
