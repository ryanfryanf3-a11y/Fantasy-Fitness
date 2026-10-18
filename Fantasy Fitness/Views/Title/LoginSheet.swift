//
//  LoginSheet.swift
//  Fantasy Fitness
//

import SwiftUI

/// Sign in with Apple, Google or email. Not wired to Supabase Auth yet: every
/// option succeeds immediately so the rest of the app can be exercised.
struct LoginSheet: View {
    let onLoggedIn: () -> Void

    @State private var email = ""
    @State private var password = ""

    private var canSubmitEmail: Bool { email.contains("@") && !password.isEmpty }

    var body: some View {
        SheetScaffold(title: "Log in", closeLabel: "Cancel") {
            Text("Your training log, gear and guild rank follow your account.")
                .font(.alegreyaSans(17))
                .foregroundStyle(Theme.inkSecondary)

            VStack(spacing: 14) {
                // Apple's guidelines: black button, Apple logo, "Sign in with Apple".
                Button(action: onLoggedIn) {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                        .font(.system(size: 19, weight: .semibold))
                }
                .buttonStyle(.chunky(CartoonPalette(fill: .black, border: .black, text: .white)))

                Button(action: onLoggedIn) {
                    HStack(spacing: 10) {
                        Text("G")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.sapphire)
                        Text("Continue with Google")
                            .font(.system(size: 19, weight: .semibold))
                    }
                }
                .buttonStyle(.chunky(CartoonPalette(fill: .white, border: Theme.outline, text: Theme.ink)))
            }
            .padding(.top, 20)

            HStack(spacing: 12) {
                DashedDivider()
                Text("or")
                    .font(.alegreyaSans(15, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary)
                DashedDivider()
            }
            .padding(.vertical, 22)

            VStack(spacing: 14) {
                ParchmentField(title: "Email", text: $email, prompt: "you@guild.com",
                               keyboard: .emailAddress, contentType: .username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                ParchmentField(title: "Password", text: $password, isSecure: true, contentType: .password)
            }

            Button("Log in with email", action: onLoggedIn)
                .buttonStyle(.chunky(.wax))
                .disabled(!canSubmitEmail)
                .padding(.top, 22)

            Text("New here? Signing in with any option creates your guild account.")
                .font(.alegreyaSans(14))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
    }
}

#Preview {
    Text("Title").sheet(isPresented: .constant(true)) { LoginSheet(onLoggedIn: {}) }
}
