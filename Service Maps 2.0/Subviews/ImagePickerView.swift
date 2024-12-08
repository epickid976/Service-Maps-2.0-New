//
//  ImagePickerView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import SwiftUI
import PhotosUI
import Nuke

//MARK: - Image Picker View

struct ImagePickerView: View {
    //MARK: - Properties
    var title: String
    var subTitle: String
    var systemImage: String
    var tint: Color
    var onImageChange: (UIImage) -> ()
    //View Properties
    @State var photoItem: PhotosPickerItem?
    @State var showImagePicker: Bool = false
    //Preview Image
    @Binding var previewImage: UIImage?
    //Loading
    @State var isLoading: Bool = false
    
    //MARK: - Initializer
    init(title: String, subTitle: String, systemImage: String, tint: Color, previewImage: Binding<UIImage?>, onImageChange: @escaping (UIImage) -> Void) {
        self.title = title
        self.subTitle = subTitle
        self.systemImage = systemImage
        self.tint = tint
        self.onImageChange = onImageChange
        _previewImage = previewImage
    }
    
    //MARK: - Body
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
            .opacity(previewImage == nil ? 1: 0)
            .frame(width: size.width, height: size.height)
            .overlay {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .aspectRatio(contentMode: .fit)
                        .padding(15)
                    
                }
            }
            //Displaying Loading UI
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding(10)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 5))
                }
            }
            //Animation
            .animation(.snappy, value: isLoading)
            .animation(.snappy, value: previewImage)
            .contentShape(.rect)
            //Implementing Drop Action and Retreving Dropped Image
            .dropDestination (for: Data.self, action: { items, location in
                HapticManager.shared.trigger(.lightImpact)
                if let firstItem = items.first, let droppedImage = UIImage(data: firstItem) {
                    //Sending the Image using the callback
                    generateImageThumbnail(droppedImage, size)
                    onImageChange(droppedImage)
                    return true
                }
                return false
            }, isTargeted: { _ in
                
            })
            .onTapGesture {
                HapticManager.shared.trigger(.lightImpact)
                showImagePicker.toggle()
            }
            //Implementation of Manual Image Picker
            .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            
            //Processing Selected Image
            .optionalViewModifier { contentView in
                if #available(iOS 17, *) {
                    contentView
                        .onChange(of: photoItem) { oldValue, newValue in
                            if let newValue {
                                extractImage(newValue, size)
                            }
                        }
                } else {
                    contentView
                        .onChange(of: photoItem) { newValue in
                            if let newValue {
                                extractImage(newValue, size)
                            }
                        }
                }
            }
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(.blue.opacity(0.08).gradient)
                    RoundedRectangle (cornerRadius: 15, style: .continuous)
                        .stroke(.blue, style: .init(lineWidth: 1, dash: [12]))
                }
            }
        }
    }
    
    //MARK: - Functions
    //Extracting image from PhotoItem
    func extractImage(_ photoItem: PhotosPickerItem, _ viewSize: CGSize) {
        Task.detached {
            guard let imageData = try? await photoItem.loadTransferable(type: Data.self) else { return }
            
            // UI Must be Updated on Main Thread
            await MainActor.run {
                if let selectedImage = UIImage (data: imageData) {
                    // Creating Preview
                    generateImageThumbnail(selectedImage, viewSize)
                    // Send Orignal Image to Callback
                    onImageChange(selectedImage)
                }
                // Clearing PhotoItem
                self.photoItem = nil
            }
        }
    }
    
    //Creating image thumbnail
    func generateImageThumbnail(_ image: UIImage, _ size: CGSize) {
        Task.detached {
            let thumbnailImage = await image.byPreparingThumbnail(ofSize: size)
            // UI Must be Updated on Main Thread
            await MainActor.run {
                previewImage = thumbnailImage
            }
        }
    }
}
