//
//  AppVersionHelpers.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/12/24.
//

import Foundation

func getAppVersion() -> String {
    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        return appVersion
    }
    return "Unknown"
}

func getBuildNumber() -> String {
    if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        return buildNumber
    }
    return "Unknown"
}

@discardableResult
func isUpdateAvailable(completion: @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
    guard let info = Bundle.main.infoDictionary,
        let currentVersion = info["CFBundleShortVersionString"] as? String,
        let identifier = info["CFBundleIdentifier"] as? String,
        let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {
            throw VersionError.invalidBundleInfo
    }
        
    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData)
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        do {
            if let error = error { throw error }
            
            guard let data = data else { throw VersionError.invalidResponse }
                        
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                        
            guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let lastVersion = result["version"] as? String else {
                throw VersionError.invalidResponse
            }
            print("last version: \(lastVersion) current version: \(currentVersion)")
            completion(lastVersion > currentVersion, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    task.resume()
    return task
}

enum VersionError: Error {
    case invalidResponse, invalidBundleInfo
    
    var localizedDescription: String {
            switch self {
            case .invalidResponse:
                return NSLocalizedString("The server returned an invalid response.", comment: "")
            case .invalidBundleInfo:
                return NSLocalizedString("The bundle info could not be parsed.", comment: "")
            }
        }
}
