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
    let onLogOut: () -> Void

    @State private var selectedTab: AppTab = .guildHall

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Guild Hall", systemImage: "building.columns", value: .guildHall) {
                NavigationStack {
                    GuildHallView(onOpenQuests: { selectedTab = .quests }, onLogOut: onLogOut)
                }
            }
            Tab("Quests", systemImage: "scroll", value: .quests) {
                NavigationStack { QuestBoardView() }
            }
            Tab("Character", systemImage: "person.crop.square", value: .character) {
                NavigationStack { CharacterSheetView() }
            }
            Tab("Dungeons", systemImage: "map", value: .dungeons) {
                NavigationStack { DungeonMapView() }
            }
            Tab("Tavern", systemImage: "fork.knife", value: .tavern) {
                NavigationStack { TavernView() }
            }
        }
        .tint(Theme.gold)
        // Dark scheme keeps the glass tab bar and status bar dark over the wood board.
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView(onLogOut: {})
}
