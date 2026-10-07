//
//  SettingsSheet.swift
//  Fantasy Fitness
//

import SwiftUI

/// Placeholder settings (profile, sync, units). Reachable from Title and Guild Hall.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.alegreya(28, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.alegreya(17, weight: .heavy))
                    .foregroundStyle(Theme.waxRed)
                    .frame(minWidth: 44, minHeight: 44)
            }

            VStack(spacing: 0) {
                row("Profile", detail: "Coming soon", systemImage: "person.fill")
                row("Sync", detail: "Coming soon", systemImage: "arrow.triangle.2.circlepath")
                row("Units", detail: "lb", systemImage: "scalemass.fill")
            }
            .padding(.top, 16)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.parchment)
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
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
    Text("Title").sheet(isPresented: .constant(true)) { SettingsSheet() }
}
