//
//  ImagePickerView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    var title: String
    var subTitle: String
    var systemImage: String
    var tint: Color
    var onImageChange: (UIImage) -> ()
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.callout)
                    .padding (.top, 15)
                Text(subTitle)
                    .font(.caption)
                    .foregroundStyle (.gray)
            }
            .frame(width: size.width, height: size.height)
        }
    }
}


#Preview {
    VStack {
        ImagePickerView(title: "Drag & Drop", subTitle: "Tap to add an image", systemImage: "testTerritoryImage", tint: .blue) { image in
            
        }
    }
    .frame(maxWidth: 300, maxHeight: 250)
    .padding(.top, 20)
    .background {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.blue.opacity(0.08).gradient)
            RoundedRectangle (cornerRadius: 15, style: .continuous)
                .stroke(.blue, style: .init(lineWidth: 1, dash: [12]))
        }
    }
}
