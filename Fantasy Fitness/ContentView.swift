//
//  ContentView.swift
//  Fantasy Fitness
//
//  Created by Ryan Ferguson on 9/30/26.
//

import SwiftUI

enum AppTab: Hashable {
    case guildHall, quests, character, dungeons, tavern
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .guildHall

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Guild Hall", systemImage: "building.columns", value: .guildHall) {
                NavigationStack { PlaceholderScreen(title: "Guild Hall") }
            }
            Tab("Quests", systemImage: "scroll", value: .quests) {
                NavigationStack { QuestBoardView() }
            }
            Tab("Character", systemImage: "person.crop.square", value: .character) {
                NavigationStack { PlaceholderScreen(title: "Character") }
            }
            Tab("Dungeons", systemImage: "map", value: .dungeons) {
                NavigationStack { PlaceholderScreen(title: "Dungeons") }
            }
            Tab("Tavern", systemImage: "fork.knife", value: .tavern) {
                NavigationStack { PlaceholderScreen(title: "Tavern") }
            }
        }
        .tint(Theme.gold)
        // Dark scheme keeps the glass tab bar and status bar dark over the wood board.
        .preferredColorScheme(.dark)
    }
}

/// Stand-in for tabs that haven't been built yet.
private struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.pirata(40))
                .foregroundStyle(Theme.gold)
            Text("Coming soon")
                .font(.alegreyaSans(17, weight: .medium))
                .foregroundStyle(Theme.cream)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WoodBackground())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    ContentView()
}
