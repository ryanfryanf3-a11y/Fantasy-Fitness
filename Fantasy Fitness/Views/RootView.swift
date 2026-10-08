//
//  RootView.swift
//  Fantasy Fitness
//

import SwiftUI

/// Title screen and onboarding sit outside the tab shell, gated by `hasCompletedOnboarding`.
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
                TitleScreenView(
                    hasSave: hasCompletedOnboarding,
                    onContinue: { go(to: .game) },
                    onNewGame: { go(to: .onboarding) }
                )
            case .onboarding:
                OnboardingView(
                    onFinish: {
                        hasCompletedOnboarding = true
                        go(to: .game)
                    },
                    onBack: { go(to: .title) }
                )
            case .game:
                ContentView()
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
