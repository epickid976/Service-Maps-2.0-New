//
//  AreEqualFuncs.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation

func areEqual(tokenModel: MyTokenModel, tokenObject: TokenObject) -> Bool {
  return tokenModel.id == tokenObject.id &&
         tokenModel.name == tokenObject.name &&
         tokenModel.owner == tokenObject.owner &&
         tokenModel.congregation == tokenObject.congregation &&
         tokenModel.moderator == tokenObject.moderator &&
         tokenModel.expire == tokenObject.expire &&
         tokenModel.user == tokenObject.user
}


