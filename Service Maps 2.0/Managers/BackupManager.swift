//
//  BackupManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/16/24.
//

import Foundation
import PDFKit
import SwiftUI
import Nuke
import NukeExtensions
import NukeUI
import ZIPFoundation


class BackupManager: ObservableObject {
    
    //FIELD NAMES
    let street = "STREET" //There are four, each other one adds a 2, 3, 4
    let territoryNumber = "Terr No" //There are four, each other one adds a 2, 3, 4
    let houseNumber = "HOUSE" //Each row changes number, each other adds 2_1, 2_2, 2_3, 2_4 etc, first number being other, second number being house row
    
    let date = "FechaRow" //Each other one changes the row number, each other s8 adds _2, _3, _4
    let symbol = "S"  //Each row adds number, each other adds 2_1, 2_2, 2_3, 2_4 etc, first number being other, second number being row
    let notes = "Nombre colocaciones y observacionesRow" //Each row adds number, each other adds _2, _3, _4
    
    @Published var backup = false
    
    @ObservedObject var realmManager = RealmManager.shared
    
    let fileManager = FileManager.default
    
    
    func backupFiles() async -> Result<URL, Error>{
        let territories = realmManager.getAllTerritoriesDirect()
        let addresses = realmManager.getAllAddressesDirect()
        let houses = realmManager.getAllHousesDirect()
        let visits = realmManager.getAllVisitsDirect()
        
        let territoryModels = ModelToStruct().convertTerritoryEntitiesToStructs(entities: territories)
        let addressModels = ModelToStruct().convertTerritoryAddressEntitiesToStructs(entities: addresses)
        let houseModels = ModelToStruct().convertHouseEntitiesToStructs(entities: houses)
        let visitModels = ModelToStruct().convertVisitEntitiesToStructs(entities: visits)
        
        
        print("JUST GOT HERE")
        
        guard let pdfURL = Bundle.main.url(forResource: "s8NEW", withExtension: "pdf"), let pdfDocument = PDFDocument(url: pdfURL) else {
            print("Failed to load the PDF document")
            return Result.failure(CustomErrors.GenericError)
        }
        
        let page1 = pdfDocument.page(at: 0)
        if page1 == nil {
            print("Failed to load the first page of the PDF document")
            return Result.failure(CustomErrors.GenericError)
        }
        let fields = page1!.annotations.filter({ $0.fieldName != ""})
        
        let date = getCurrentDate()
        guard let backupFolder =  createBackupFolder(date: date) else {
            return Result.failure(CustomErrors.GenericError)
        }
        
        let backupPDFURL = backupFolder.appendingPathComponent("Backup-\(date).pdf")
        
        let data = orderAllData(territories: territoryModels, addressesList: addressModels, houseList: houseModels, visits: visitModels)
        print("Ordered all data \(data.count)")
        
        for territory in data {
            let territoryFolderURL = createTerritoryFolder(backupFolder: backupFolder, territory: territory.territory)
            
            
            let imageProcess = await saveTerritoryImage(folder: territoryFolderURL, territory: territory.territory)
            
            
            switch imageProcess {
                case .success(_):
                    print("Successfully saved the territory image")
                case .failure(_):
                    print("Failed to save the territory image")
            }
            
            var doors = 0
            
            for address in territory.addresses {
                doors += address.houses.count
            }
            
            saveTerritoryTextFile(territory: territory.territory, territoryFolder: territoryFolderURL, doors: doors)
            
            print("Number of addresses: \(territory.addresses.count)")
            
            
            for address in territory.addresses {
                print("Entering loop")
                print("Number of houses: \(address.houses.count)")
                if address.houses.count > 96 {
                    print("Entering houses > 96")
                    var split = [AddressWithHouses]()
                    
                    for houses in address.houses.divideIn(96) {
                        split.append(AddressWithHouses(address: address.address, houses: houses))
                    }
                    
                    for (index, addressWithHouses) in split.enumerated() {
                        await writeS8(parentFolder: territoryFolderURL, territoryNumber: String(territory.territory.number), address: addressWithHouses, version: index + 1)
                    }
                } else {
                    print("Entering else")
                    await writeS8(parentFolder: territoryFolderURL, territoryNumber: String(territory.territory.number), address: address)
                }
            }
        }
        
        let zipFileName = "Backup-\(date).zip"
            let zipFileURL = backupFolder.deletingLastPathComponent().appendingPathComponent(zipFileName)

            do {
                try await zipBackupFolder(sourceURL: backupFolder, destinationURL: zipFileURL)
                print("Successfully zipped the backup folder at \(zipFileURL.path)")
                
                // Clean up the original backup folder after successful zipping
                try FileManager.default.removeItem(at: backupFolder)
            } catch {
                print("Failed to zip the backup folder: \(error.localizedDescription)")
                return .failure(error)
            }

            return .success(zipFileURL)
        
    }
    
    private func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.string(from: Date())
    }
    
    private func createBackupFolder(date: String) -> URL? {
        // 1. Get the cache directory (similar to externalCacheDir in Android)
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Failed to locate cache directory")
            return nil
        }
        
        // 2. Create the "Backup" parent directory
        let parentDirectory = cacheDirectory.appendingPathComponent("Backup")
        
        if fileManager.fileExists(atPath: parentDirectory.path) {
            // If parent directory exists, delete it recursively
            try? fileManager.removeItem(at: parentDirectory)
        }
        // Create the parent directory
        try? fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        
        // 3. Create the backup folder with the current date
        let backupFolder = parentDirectory.appendingPathComponent("Backup-\(date)")
        
        if fileManager.fileExists(atPath: backupFolder.path) {
            // If backup folder exists, delete it and recreate
            try? fileManager.removeItem(at: backupFolder)
        }
        // Create the backup folder
        try? fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        
        return backupFolder
    }
    
    private func createTerritoryFolder(backupFolder: URL, territory: TerritoryModel) -> URL {
        let territoryFolder = backupFolder.appendingPathComponent("T-\(territory.number)")
        
        if !fileManager.fileExists(atPath: territoryFolder.path) {
            try? fileManager.createDirectory(at: territoryFolder, withIntermediateDirectories: true)
        }
        
        return territoryFolder
    }
    
    private func saveTerritoryImage(folder: URL, territory: TerritoryModel) async -> Result<Bool, Error> {
        guard let imageUrl = URL(string: territory.getImageURL()) else {
            print("No image URL found for territory \(territory.number)")
            return Result.failure(CustomErrors.GenericError)
        }
        do {
            let image = try await ImagePipeline.shared.image(for: imageUrl)
            let imageData = image.jpegData(compressionQuality: 1.0)
            let imagePath = folder.appendingPathComponent("\(territory.number).jpg")
            print("Saving image to: \(imagePath.path)")
            try? imageData?.write(to: imagePath)
            return Result.success(true)
        } catch {
            return Result.failure(CustomErrors.GenericError)
        }
        
    }
    
    private func saveTerritoryTextFile(territory: TerritoryModel, territoryFolder: URL, doors: Int) {
        let text = "\(territory.description)\nDoors: \(doors)"
        let textFileURL = territoryFolder.appendingPathComponent("\(territory.number).txt")
        try? text.write(to: textFileURL, atomically: true, encoding: .utf8)
    }
    
    func zipBackupFolder(sourceURL: URL, destinationURL: URL) async throws {
        let fileManager = FileManager.default
        
        // Ensure the destination directory exists
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        guard let archive = Archive(url: destinationURL, accessMode: .create) else {
            throw NSError(domain: "com.zip.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create zip archive."])
        }
        
        let enumerator = fileManager.enumerator(at: sourceURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let relativePath = fileURL.relativePath(from: sourceURL)
            
            // Check if the item is a file (not a directory)
            if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
               let isRegularFile = values.isRegularFile, isRegularFile {
                try archive.addEntry(with: relativePath, relativeTo: sourceURL)
            }
        }
    }
    
    private func orderAllData(
        territories: [TerritoryModel],
        addressesList: [TerritoryAddressModel],
        houseList: [HouseModel],
        visits: [VisitModel]
    ) -> [TerritoryWithAddresses] {
        var list = [TerritoryWithAddresses]()
        
        for territory in territories {
            var addresses = [AddressWithHouses]()
            
            let filteredAddresses = addressesList.filter { $0.territory == territory.id }
            for address in filteredAddresses {
                var houses = [HouseWithVisit]()
                
                let filteredHouses = houseList.filter { $0.territory_address == address.id }
                for house in filteredHouses {
                    // Find the most recent visit that doesn't have a symbol of "NC"
                    let visit = visits
                        .filter { $0.house == house.id && $0.symbol != "NC" } // Adjust your symbol key here if necessary
                        .max(by: { $0.date < $1.date }) ?? visits
                        .filter { $0.house == house.id }
                        .max(by: { $0.date < $1.date })
                    
                    houses.append(HouseWithVisit(house: house, visit: visit))
                }
                
                addresses.append(AddressWithHouses(
                    address: address,
                    houses: houses.sorted(by: { $0.house.number < $1.house.number })
                ))
            }
            
            list.append(TerritoryWithAddresses(
                territory: territory,
                addresses: addresses.sorted(by: { $0.address.address < $1.address.address })
            ))
        }
        
        return list.sorted(by: { $0.territory.number < $1.territory.number })
    }

    func obtainForms(fields: [PDFAnnotation]) -> [FormS8] {
        print("Starting obtainForms with \(fields.count) fields")
        
        // Filter fields based on their form (1_, 2_, 3_, 4_)
        let form1 = fields.filter { $0.fieldName?.contains("1_") == true }
        let form2 = fields.filter { $0.fieldName?.contains("2_") == true }
        let form3 = fields.filter { $0.fieldName?.contains("3_") == true }
        let form4 = fields.filter { $0.fieldName?.contains("4_") == true }
        
        print("Form field counts: 1:\(form1.count), 2:\(form2.count), 3:\(form3.count), 4:\(form4.count)")
        
        // Helper function to extract fields by keyword within each form
        func extractFields(from form: [PDFAnnotation], keyword: String) -> [PDFAnnotation] {
            return form.filter { $0.fieldName?.contains(keyword) == true }
        }
        
        // Extract fields for each form
        let form1Street = extractFields(from: form1, keyword: "STREET").first
        let form1TerrNo = extractFields(from: form1, keyword: "Terr No").first
        let form1Houses = extractFields(from: form1, keyword: "HOUSE")
        let form1Dates = extractFields(from: form1, keyword: "FechaRow")
        let form1Symbols = extractFields(from: form1, keyword: "S")
        let form1Notes = extractFields(from: form1, keyword: "Nombre colocaciones y observaciones")
        let form1Name = extractFields(from: form1, keyword: "NOMBRE DEL PUBLICADOR").first

        let form2Street = extractFields(from: form2, keyword: "STREET").first
        let form2TerrNo = extractFields(from: form2, keyword: "Terr No").first
        let form2Houses = extractFields(from: form2, keyword: "HOUSE")
        let form2Dates = extractFields(from: form2, keyword: "FechaRow")
        let form2Symbols = extractFields(from: form2, keyword: "S")
        let form2Notes = extractFields(from: form2, keyword: "Nombre colocaciones y observaciones")
        let form2Name = extractFields(from: form2, keyword: "NOMBRE DEL PUBLICADOR").first
        
        // Similarly for form 3 and form 4
        let form3Street = extractFields(from: form3, keyword: "STREET").first
        let form3TerrNo = extractFields(from: form3, keyword: "Terr No").first
        let form3Houses = extractFields(from: form3, keyword: "HOUSE")
        let form3Dates = extractFields(from: form3, keyword: "FechaRow")
        let form3Symbols = extractFields(from: form3, keyword: "S")
        let form3Notes = extractFields(from: form3, keyword: "Nombre colocaciones y observaciones")
        let form3Name = extractFields(from: form3, keyword: "NOMBRE DEL PUBLICADOR").first

        let form4Street = extractFields(from: form4, keyword: "STREET").first
        let form4TerrNo = extractFields(from: form4, keyword: "Terr No").first
        let form4Houses = extractFields(from: form4, keyword: "HOUSE")
        let form4Dates = extractFields(from: form4, keyword: "FechaRow")
        let form4Symbols = extractFields(from: form4, keyword: "S")
        let form4Notes = extractFields(from: form4, keyword: "Nombre colocaciones y observaciones")
        let form4Name = extractFields(from: form4, keyword: "NOMBRE DEL PUBLICADOR").first
        
        

        // Create FormS8 instances for each form
        let forms = [
            FormS8(street: form1Street!, terrNo: form1TerrNo!, name: form1Name ?? PDFAnnotation(), houses: form1Houses, dates: form1Dates, symbols: form1Symbols, notes: form1Notes),
            FormS8(street: form2Street!, terrNo: form2TerrNo!, name: form2Name ?? PDFAnnotation(), houses: form2Houses, dates: form2Dates, symbols: form2Symbols, notes: form2Notes),
            FormS8(street: form3Street!, terrNo: form3TerrNo!, name: form3Name ?? PDFAnnotation(), houses: form3Houses, dates: form3Dates, symbols: form3Symbols, notes: form3Notes),
            FormS8(street: form4Street!, terrNo: form4TerrNo!, name: form4Name ?? PDFAnnotation(), houses: form4Houses, dates: form4Dates, symbols: form4Symbols, notes: form4Notes)
        ]

        print("Created \(forms.count) FormS8 instances")
        print("Form 1: \(forms[0].houses.count) houses, \(forms[0].dates.count) dates, \(forms[0].symbols.count) symbols, \(forms[0].notes.count) notes")
        return forms
    }
    
    func writeS8(
        parentFolder: URL,
        territoryNumber: String,
        address: AddressWithHouses,
        version: Int? = nil
    ) async {
        // Create the output PDF file in the parent folder
        let fileName = version == nil ? "\(address.address.address).pdf" : "\(address.address.address) (\(version!)).pdf"
        let outputFileURL = parentFolder.appendingPathComponent(fileName)

        // Create the file if it does not exist
        if !FileManager.default.fileExists(atPath: outputFileURL.path) {
            FileManager.default.createFile(atPath: outputFileURL.path, contents: nil)
        }

        // Load the PDF document template (assuming it's bundled)
        guard let pdfURL = Bundle.main.url(forResource: "s8NEW", withExtension: "pdf"),
              let pdfDocument = PDFDocument(url: pdfURL) else {
            print("Failed to load the PDF template")
            return
        }

        // Get the first page of the PDF
        guard let page = pdfDocument.page(at: 0) else {
            print("Failed to load the first page of the PDF")
            return
        }

        // Extract all the annotations (i.e., form fields)
        let fields = page.annotations.filter { $0.fieldName != nil }

        // Obtain the form structure
        let forms = obtainForms(fields: fields)

        // Write data into the form fields
        var formIndex = 0
        let houseDataChunks = address.houses.divideIn(24)

        for dataChunk in houseDataChunks {
            guard formIndex < forms.count else { break }
            let form = forms[formIndex]

            // Ensure the form has at least 24 rows for houses, dates, symbols, and notes
            guard form.houses.count >= 24, form.dates.count >= 24, form.symbols.count >= 24, form.notes.count >= 24 else {
                print("Form does not contain enough fields to handle the data")
                break
            }

            // Set the street and territory number
            form.street.widgetStringValue = address.address.address
            form.terrNo.widgetStringValue = territoryNumber

            // Iterate through each house in the chunk and update the form
            for (index, houseData) in dataChunk.enumerated() {
                guard index < form.houses.count else {
                    print("Data exceeds form row count")
                    break
                }

                // Set house number, date, symbol, and notes
                form.houses[index].widgetStringValue = houseData.house.number

                if let visit = houseData.visit {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd/yyyy"

                    form.dates[index].widgetStringValue = dateFormatter.string(from: Date(milliseconds: visit.date))
                    form.symbols[index].widgetStringValue = visit.symbol
                    form.notes[index].widgetStringValue = visit.notes
                }

                // Ensure the value is committed using setValue to reflect the changes
                form.houses[index].setValue(form.houses[index].widgetStringValue, forAnnotationKey: .widgetValue)
                form.dates[index].setValue(form.dates[index].widgetStringValue, forAnnotationKey: .widgetValue)
                form.symbols[index].setValue(form.symbols[index].widgetStringValue, forAnnotationKey: .widgetValue)
                form.notes[index].setValue(form.notes[index].widgetStringValue, forAnnotationKey: .widgetValue)
            }

            // Move to the next form if needed
            formIndex += 1
        }

        // Save the modified PDF
        pdfDocument.write(to: outputFileURL)
        print("Successfully saved the PDF at \(outputFileURL.path)")
    }
    
    private var numbersForm1Keys: [String] {
        var keys = [String]()
        for i in 1...24 {
            keys.append(houseNumber + "1_\(i)")
        }
        return keys
    }
    
    private var numbersForm2Keys: [String] {
        var keys = [String]()
        for i in 1...24 {
            keys.append(houseNumber + "2_\(i)")
        }
        return keys
    }
    
    private var numbersForm3Keys: [String] {
        var keys = [String]()
        for i in 1...24 {
            keys.append(houseNumber + "3_\(i)")
        }
        return keys
    }
    
    private var numbersForm4Keys: [String] {
        var keys = [String]()
        for i in 1...24 {
            keys.append(houseNumber + "4_\(i)")
        }
        return keys
    }
    
    
    
    struct HouseWithVisit {
        let house: HouseModel
        let visit: VisitModel?
    }

    struct AddressWithHouses {
        let address: TerritoryAddressModel
        let houses: [HouseWithVisit]
    }

    struct TerritoryWithAddresses {
        let territory: TerritoryModel
        let addresses: [AddressWithHouses]
    }

    struct FormS8 {
        let street: PDFAnnotation
        let terrNo: PDFAnnotation
        let name: PDFAnnotation
        let houses: [PDFAnnotation]
        let dates: [PDFAnnotation]
        let symbols: [PDFAnnotation]
        let notes: [PDFAnnotation]
    }
    
}
extension URL {
    func relativePath(from base: URL) -> String {
        let selfStr = self.standardized.path
        let baseStr = base.standardized.path
        
        if selfStr.hasPrefix(baseStr) {
            let index = selfStr.index(selfStr.startIndex, offsetBy: baseStr.count)
            return String(selfStr[index...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        
        return self.lastPathComponent
    }
}
