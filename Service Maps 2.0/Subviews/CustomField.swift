//
//  CustomField.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation
import SwiftUI

//MARK: - Custom Field

struct CustomField: View {
    // MARK: - Properties
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
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
    @State private var isSecure = true

    // MARK: - Body
    var body: some View {
        Group {
            if textfield {
                TextField(placeholder, text: $text, axis: textfieldAxis ?? .horizontal)
                    .glassFieldStyle(
                        isFocused: isFocused,
                        keyboardType: keyboardType ?? .default,
                        keyboardContentType: keyboardContentType,
                        textAlignment: textAlignment ?? .leading,
                        disableAutocorrect: disableAutocorrect ?? false,
                        diableCapitalization: diableCapitalization ?? false,
                        expanded: expanded ?? false,
                        disabled: disabled ?? false,
                        maxValue: maxValue
                    )
                    .onChange(of: text) { newValue in
                            if formatAsPhone == true {
                                text = newValue.formatPhoneNumber()
                            }

                            if let max = maxValue, text.count > max {
                                text = String(text.prefix(max))
                            }
                        }
            } else {
                HStack(spacing: 8) {
                    SecureTextField(placeholder: placeholder, text: $text, isSecure: $isSecure)
                        .glassFieldStyle(
                            isFocused: isFocused,
                            keyboardType: keyboardType ?? .default,
                            keyboardContentType: keyboardContentType,
                            textAlignment: textAlignment ?? .leading,
                            disableAutocorrect: disableAutocorrect ?? false,
                            diableCapitalization: diableCapitalization ?? false,
                            expanded: expanded ?? false,
                            disabled: disabled ?? false,
                            maxValue: maxValue
                        )
                        .onChange(of: text) { newValue in
                                if formatAsPhone == true {
                                    text = newValue.formatPhoneNumber()
                                }

                                if let max = maxValue, text.count > max {
                                    text = String(text.prefix(max))
                                }
                            }

                    Button(action: { isSecure.toggle() }) {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .toolbar {
            if isFocused.wrappedValue {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        HapticManager.shared.trigger(.lightImpact)
                        isFocused.wrappedValue = false
                        resignFirstResponderManually()
                    }
                    .tint(.primary)
                    .bold()
                }
            }
        }
    }
}

//MARK: - Secure Text Field
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

//MARK: - Custom Field Modifier
extension View {
    func glassFieldStyle(
        isFocused: FocusState<Bool>.Binding,
        keyboardType: UIKeyboardType? = nil,
        keyboardContentType: UITextContentType? = nil,
        textAlignment: TextAlignment = .leading,
        disableAutocorrect: Bool = false,
        diableCapitalization: Bool = false,
        expanded: Bool = false,
        disabled: Bool = false,
        maxValue: Int? = nil
    ) -> some View {
        self
            .disabled(disabled)
            .autocorrectionDisabled(disableAutocorrect)
            .textInputAutocapitalization(diableCapitalization ? .never : .sentences)
            .keyboardType(keyboardType ?? .default)
            .multilineTextAlignment(textAlignment)
            .focused(isFocused)
            .padding()
            .glassBackground()
            .font(.system(size: 16, weight: .regular))
            .frame(minHeight: 60)
            .optionalViewModifier { content in
                if expanded {
                    content.lineLimit(5, reservesSpace: true)
                } else {
                    content
                }
            }
            .optionalViewModifier { content in
                if let type = keyboardContentType {
                    content.textContentType(type)
                } else {
                    content
                }
            }
    }
}

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.05))
                            .blur(radius: 0.3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassBackground(cornerRadius: cornerRadius))
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
