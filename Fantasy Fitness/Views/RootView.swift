//
//  RootView.swift
//  Fantasy Fitness
//

import SwiftUI

/// Title screen and onboarding sit outside the tab shell. After logging in, players who
/// haven't finished onboarding (stored on their Supabase profile) go there first.
struct RootView: View {
    private enum Route {
        case title, onboarding, game
    }

    @Environment(GameStore.self) private var store
    @State private var route: Route = .title

    var body: some View {
        Group {
            switch route {
            case .title:
                TitleScreenView(onLoggedIn: {
                    go(to: store.player.hasCompletedOnboarding ? .game : .onboarding)
                })
            case .onboarding:
                NavigationStack {
                    OnboardingView(onFinish: { go(to: .game) }, onBack: logOut)
                }
            case .game:
                ContentView(onLogOut: logOut)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Something went wrong", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func logOut() {
        Task {
            await store.signOut()
            go(to: .title)
        }
    }

    private func go(to newRoute: Route) {
        withAnimation(.easeInOut(duration: 0.3)) { route = newRoute }
    }
}

#Preview {
    RootView()
        .environment(GameStore.preview)
}
