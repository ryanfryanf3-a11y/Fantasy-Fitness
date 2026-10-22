//
//  LoginSheet.swift
//  Fantasy Fitness
//

import AuthenticationServices
import CryptoKit
import SwiftUI

/// Sign in with Apple, Google or email through Supabase Auth. In offline demo mode
/// (no Config/Secrets.plist) every option goes straight in with sample data.
struct LoginSheet: View {
    let onLoggedIn: () -> Void

    @Environment(GameStore.self) private var store
    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var isWorking = false
    @State private var message: String?
    @State private var appleNonce = ""

    private var canSubmitEmail: Bool { email.contains("@") && password.count >= 6 }

    var body: some View {
        SheetScaffold(title: isCreatingAccount ? "Create account" : "Log in", closeLabel: "Cancel") {
            Text("Your training log, gear and guild rank follow your account.")
                .font(.alegreyaSans(17))
                .foregroundStyle(Theme.inkSecondary)

            if store.isDemo {
                Text("Demo mode: add Config/Secrets.plist to connect to Supabase.")
                    .font(.alegreyaSans(14, weight: .bold))
                    .foregroundStyle(Theme.waxRed)
                    .padding(.top, 8)
            }

            VStack(spacing: 14) {
                SignInWithAppleButton(isCreatingAccount ? .signUp : .signIn) { request in
                    appleNonce = Self.randomNonce()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = Self.sha256(appleNonce)
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.darkestWood.opacity(0.55)).offset(y: 5))

                Button {
                    run { await store.signInWithGoogle() }
                } label: {
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
            .disabled(isWorking)

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
                ParchmentField(title: "Password", text: $password, prompt: "At least 6 characters", isSecure: true,
                               contentType: isCreatingAccount ? .newPassword : .password)
            }

            if let message {
                Text(message)
                    .font(.alegreyaSans(15, weight: .bold))
                    .foregroundStyle(Theme.waxRed)
                    .padding(.top, 12)
            }

            Button {
                run {
                    isCreatingAccount
                        ? await store.signUp(email: email, password: password)
                        : await store.signIn(email: email, password: password)
                }
            } label: {
                if isWorking {
                    ProgressView().tint(Theme.cream)
                } else {
                    Text(isCreatingAccount ? "Create account" : "Log in with email")
                }
            }
            .buttonStyle(.chunky(.wax))
            .disabled(!canSubmitEmail || isWorking)
            .padding(.top, 18)

            Button(isCreatingAccount ? "Already have an account? Log in" : "New here? Create an account") {
                isCreatingAccount.toggle()
                message = nil
            }
            .font(.alegreyaSans(15, weight: .bold))
            .foregroundStyle(Theme.kicker)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.top, 8)
        }
    }

    // MARK: - Actions

    private func run(_ action: @escaping () async -> Bool) {
        isWorking = true
        message = nil
        Task {
            let succeeded = await action()
            isWorking = false
            if succeeded {
                onLoggedIn()
            } else {
                // Show the error here rather than as an alert behind the sheet.
                message = store.errorMessage ?? "Couldn't sign in. Try again."
                store.errorMessage = nil
            }
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8)
            else {
                message = "Apple didn't return a sign-in token."
                return
            }
            let nonce = appleNonce
            run { await store.signInWithApple(idToken: idToken, nonce: nonce) }
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                message = error.localizedDescription
            }
        }
    }

    // MARK: - Nonce (Apple requires a hashed nonce; Supabase verifies the raw one)

    private static func randomNonce(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in characters.randomElement(using: &generator)! })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    Text("Title").sheet(isPresented: .constant(true)) {
        LoginSheet(onLoggedIn: {})
            .environment(GameStore.preview)
    }
}
