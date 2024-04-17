////
////  Persistence.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 7/27/23.
////
//
import CoreData
extension NSManagedObject {
    var primaryKey : String {
        guard objectID.uriRepresentation().lastPathComponent.count > 1 else { return "" }
        return objectID.uriRepresentation().lastPathComponent.substring(from: 1)
    }
}

extension String
{
    func substring(from : Int) -> String {
        guard self.count > from else { return "" }
        return String(self[self.index(self.startIndex, offsetBy: from)...])
     }
}
