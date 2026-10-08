//
//  Fantasy_FitnessApp.swift
//  Fantasy Fitness
//
//  Created by Ryan Ferguson on 9/30/26.
//

import SwiftUI

@main
struct Fantasy_FitnessApp: App {
    init() {
        Theme.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
