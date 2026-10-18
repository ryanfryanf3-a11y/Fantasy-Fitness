//
//  SheetScaffold.swift
//  Fantasy Fitness
//

import SwiftUI

/// Parchment sheet with a title and a Done/close button; content scrolls.
struct SheetScaffold<Content: View>: View {
    let title: String
    var closeLabel = "Done"
    @ViewBuilder let content: Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.alegreya(28, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(closeLabel) { dismiss() }
                    .font(.alegreya(17, weight: .heavy))
                    .foregroundStyle(Theme.waxRed)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.parchment.ignoresSafeArea())
        .presentationCornerRadius(24)
        .environment(\.colorScheme, .light)
    }
}

/// Label + parchment text field, used by every form in the app.
struct ParchmentField: View {
    let title: String
    @Binding var text: String
    var prompt = ""
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.alegreyaSans(15, weight: .bold))
                .foregroundStyle(Theme.inkSecondary)
            Group {
                if isSecure {
                    SecureField(title, text: $text, prompt: Text(prompt))
                } else {
                    TextField(title, text: $text, prompt: Text(prompt))
                        .keyboardType(keyboard)
                }
            }
            .textContentType(contentType)
            .font(.alegreyaSans(18, weight: .medium))
            .foregroundStyle(Theme.ink)
            .tint(Theme.waxRed)
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.checkboxFill))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.outline, lineWidth: 2.5))
        }
    }
}
