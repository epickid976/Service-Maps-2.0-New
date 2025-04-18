//
//  TokenCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/9/24.
//

import SwiftUI

//MARK: - Token Cell

@MainActor
struct TokenCell: View {
    
    //MARK: - Dependencies

    @ObservedObject var dataStore = StorageManager.shared
    
    //MARK: - Environment
   
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Properties
    
    var keyData: KeyData
    var ipad: Bool = false
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    //MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(keyData.key.name )")
                        .font(.title3)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                }
                
                if keyData.key.user == dataStore.userEmail || keyData.key.moderator {
                    Text("Level: Servant")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .hSpacing(.leading)
                } else {
                    Text("Level: Publisher")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .hSpacing(.leading)
                }
                
                Text("Territories: \(processData(key: keyData))")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                
                Text(keyData.key.user == dataStore.userEmail ? dataStore.userName ?? "" : keyData.key.user ?? keyData.key.owner)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.heavy)
                    .hSpacing(.trailing).vSpacing(.bottom)
                
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(10)
        .frame(minWidth: ipad ? (mainWindowSize.width / 2) * 0.90 : mainWindowSize.width * 0.90)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .optionalViewModifier { content in
            if isIpad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
    
    func processData(key: KeyData) -> String {
        var name = ""
        if !key.territories.isEmpty {
            let data = key.territories.sorted { $0.number < $1.number}
            for territory in data {
                if name.isEmpty {
                    name = String(territory.number)
                } else {
                    name += ", " + String(territory.number)
                }
            }
            return name
        }
        return name
    }
}

//MARK: - User Token Cell

struct UserTokenCell: View {
    
    //MARK: - Dependencies
    @ObservedObject var dataStore = StorageManager.shared
    
    //MARK: - Properties
    
    var userKeyData: UserToken
    
    //MARK: - Environment
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                    Text("\(userKeyData.name )")
                        .font(.title3)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                }
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
