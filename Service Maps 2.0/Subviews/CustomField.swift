//
//  CustomField.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI


struct CustomField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding // Use FocusState for focus state
    var textfield: Bool
    var keyboardType: UIKeyboardType?
    var keyboardContentType: UITextContentType?
    var textAlignment: TextAlignment?
    var textfieldAxis: Axis?
    @State var disabled: Bool?
    var formatAsPhone: Bool?
    var disableAutocorrect: Bool?
    var expanded: Bool?
    var diableCapitalization: Bool?
    var maxValue: Int? = 255
    
    
    let placeholder: String
    
    @State var isSecure = true
    
    var body: some View {
        if textfield {
            TextField(placeholder, text: $text, axis: textfieldAxis ?? .horizontal)
                .disabled(disabled ?? false)
                .autocorrectionDisabled(disableAutocorrect ?? false)
                .textInputAutocapitalization(diableCapitalization ?? false ? .never : .sentences)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(16)
                .padding(.horizontal)
                .font(.system(size: 16, weight: .regular))
                .accentColor(.blue)
                .focused(isFocused) // Use the isFocused binding property of FocusState
                .gesture(TapGesture().onEnded {
                    // Handle tap action
                    isFocused.wrappedValue = true // Use the isFocused binding property of FocusState
                })
                .keyboardType(keyboardType ?? .default)
                .multilineTextAlignment(textAlignment ?? .leading)
                .frame(minHeight: 60)
                .optionalViewModifier { content in
                    if maxValue != nil {
                        content.onChange(of: text) { newValue in
                            if newValue.count > maxValue! {
                                text = String(newValue.prefix(maxValue!))
                            }
                        }
                    } else {
                        content
                    }
                }
                .optionalViewModifier { content in
                    if keyboardContentType != nil {
                        content
                            .textContentType(keyboardContentType!)
                    } else {
                        content
                    }
                }
                .optionalViewModifier { content in
                    if formatAsPhone != nil {
                        if formatAsPhone! {
                            content
                                .onChange(of: text) { newValue in
                                    text = newValue.formatPhoneNumber()
                                }
                        }
                    } else {
                        content
                    }
                }
                .optionalViewModifier { content in
                    if expanded != nil {
                        if expanded! {
                            content.lineLimit(5, reservesSpace: true)
                        } else {
                            content
                        }
                    } else {
                        content
                    }
                }
                //.textContentType(.oneTimeCode)
        } else {
            HStack {
                SecureTextField(placeholder: placeholder, text: $text, isSecure: $isSecure)
                    .customFieldModifier(
                        isFocused: isFocused,
                        textfieldAxis: textfieldAxis,
                        keyboardType: keyboardType,
                        keyboardContentType: keyboardContentType,
                        textAlignment: textAlignment,
                        text: $text,
                        formatAsPhone: formatAsPhone,
                        expanded: expanded,
                        disableAutocorrect: disableAutocorrect,
                        diableCapitalization: diableCapitalization,
                        disabled: disabled
                    )
                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: "eye")
                        .foregroundColor(.gray)
                }
            }
//            SecureField(placeholder, text: $text)
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(16)
//                .padding(.horizontal)
//                .font(.system(size: 16, weight: .regular))
//                .accentColor(.blue)
//                .focused(isFocused) // Use the isFocused binding property of FocusState
//                .gesture(TapGesture().onEnded {
//                    // Handle tap action
//                    isFocused.wrappedValue = true // Use the isFocused binding property of FocusState
//                })
//                .keyboardType(keyboardType ?? .default)
//                .multilineTextAlignment(textAlignment ?? .leading)
//                .frame(minHeight: 40)
//                .textContentType(.oneTimeCode)
//                .keyboardType(.asciiCapable)
        }
        
    }
    
}

struct SecureTextField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isSecure: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text).textContentType(.oneTimeCode)
                
            } else {
                TextField(placeholder, text: $text)
            }
        }.animation(.spring(), value: isSecure)
    }
}

extension View {
    func customFieldModifier(
        isFocused: FocusState<Bool>.Binding,
        textfieldAxis: Axis? = nil,
        keyboardType: UIKeyboardType? = nil,
        keyboardContentType: UITextContentType? = nil,
        textAlignment: TextAlignment? = nil,
        text: Binding<String>,
        formatAsPhone: Bool? = nil,
        expanded: Bool? = nil,
        disableAutocorrect: Bool? = nil,
        diableCapitalization: Bool? = nil,
        disabled: Bool? = nil
    ) -> some View {
        self.modifier(CustomFieldModifier(
            isFocused: isFocused,
            textfieldAxis: textfieldAxis,
            keyboardType: keyboardType,
            keyboardContentType: keyboardContentType,
            textAlignment: textAlignment,
            text: text,
            formatAsPhone: formatAsPhone,
            expanded: expanded,
            disableAutocorrect: disableAutocorrect,
            diableCapitalization: diableCapitalization,
            disabled: disabled
        ))
    }
}

struct CustomFieldModifier: ViewModifier {
    var isFocused: FocusState<Bool>.Binding
    var textfieldAxis: Axis?
    var keyboardType: UIKeyboardType?
    var keyboardContentType: UITextContentType?
    var textAlignment: TextAlignment?
    @Binding var text: String
    var formatAsPhone: Bool?
    var expanded: Bool?
    var disableAutocorrect: Bool?
    var diableCapitalization: Bool?
    var disabled: Bool?

    func body(content: Content) -> some View {
        content
            .disabled(disabled ?? false)
            .autocorrectionDisabled(disableAutocorrect ?? false)
            .textInputAutocapitalization(diableCapitalization ?? false ? .never : .sentences)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(16)
            .padding(.horizontal)
            .font(.system(size: 16, weight: .regular))
            .accentColor(.blue)
            .focused(isFocused)
            .gesture(TapGesture().onEnded {
                isFocused.wrappedValue = true
            })
            .keyboardType(keyboardType ?? .default)
            .multilineTextAlignment(textAlignment ?? .leading)
            .frame(minHeight: 60)
            .optionalViewModifier { content in
                if keyboardContentType != nil {
                    content.textContentType(keyboardContentType!)
                } else {
                    content
                }
            }
            .optionalViewModifier { content in
                if formatAsPhone != nil {
                    if formatAsPhone! {
                        content.onChange(of: text) { newValue in
                            text = newValue.formatPhoneNumber()
                        }
                    }
                } else {
                    content
                }
            }
            .optionalViewModifier { content in
                if expanded != nil {
                    if expanded! {
                        content.lineLimit(5, reservesSpace: true)
                    } else {
                        content
                    }
                } else {
                    content
                }
            }
            .textContentType(.oneTimeCode)
    }
}
