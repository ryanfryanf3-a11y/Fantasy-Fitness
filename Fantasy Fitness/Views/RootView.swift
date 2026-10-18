//
//  RootView.swift
//  Fantasy Fitness
//

import SwiftUI

/// Title screen and onboarding sit outside the tab shell. Logging in goes to onboarding
/// the first time (gated by `hasCompletedOnboarding`) and straight to the Guild Hall after.
struct RootView: View {
    private enum Route {
        case title, onboarding, game
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var route: Route = .title

    var body: some View {
        Group {
            switch route {
            case .title:
                TitleScreenView(onLoggedIn: {
                    go(to: hasCompletedOnboarding ? .game : .onboarding)
                })
            case .onboarding:
                NavigationStack {
                    OnboardingView(
                        onFinish: {
                            hasCompletedOnboarding = true
                            go(to: .game)
                        },
                        onBack: { go(to: .title) }
                    )
                }
            case .game:
                ContentView(onLogOut: { go(to: .title) })
            }
        }
        .preferredColorScheme(.dark)
    }

    private func go(to newRoute: Route) {
        withAnimation(.easeInOut(duration: 0.3)) { route = newRoute }
    }
}

#Preview {
    RootView()
}
