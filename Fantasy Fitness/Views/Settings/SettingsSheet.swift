//
//  SettingsSheet.swift
//  Fantasy Fitness
//

import SwiftUI

/// Placeholder settings (profile, sync, units). Reachable from Title and Guild Hall.
struct SettingsSheet: View {
    /// Shown only once signed in (from the Guild Hall).
    var onLogOut: (() -> Void)? = nil

    var body: some View {
        SheetScaffold(title: "Settings") {
            VStack(spacing: 0) {
                row("Profile", detail: "Coming soon", systemImage: "person.fill")
                row("Sync", detail: "Coming soon", systemImage: "arrow.triangle.2.circlepath")
                row("Units", detail: "lb", systemImage: "scalemass.fill")
            }

            if let onLogOut {
                Button("Log out", action: onLogOut)
                    .buttonStyle(.chunky(.wood))
                    .padding(.top, 28)
            }
        }
        .presentationDetents([.medium])
    }

    private func row(_ title: String, detail: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.cream)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.kicker))
            Text(title)
                .font(.alegreyaSans(18, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(detail)
                .font(.alegreyaSans(16))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(minHeight: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.inkSecondary.opacity(0.25)).frame(height: 1)
        }
    }
}

#Preview {
    Text("Title").sheet(isPresented: .constant(true)) { SettingsSheet(onLogOut: {}) }
}
