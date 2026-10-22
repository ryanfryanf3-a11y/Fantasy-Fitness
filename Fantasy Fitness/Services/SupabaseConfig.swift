//
//  SupabaseConfig.swift
//  Fantasy Fitness
//

import Foundation
import Supabase

/// Reads the project URL and anon key from `Config/Secrets.plist` (gitignored).
/// Copy `Secrets.example.plist` from the repo root to create it.
nonisolated struct SupabaseConfig {
    let url: URL
    let anonKey: String

    /// Nil when the file is missing or still holds the placeholder values;
    /// the app then runs in offline demo mode with sample data.
    static func load(from bundle: Bundle = .main) -> SupabaseConfig? {
        guard let fileURL = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: fileURL),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let urlString = (values["SUPABASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let key = (values["SUPABASE_ANON_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.contains("YOUR-"), !key.contains("YOUR-"), !key.isEmpty,
              let url = URL(string: urlString), url.scheme == "https"
        else { return nil }
        return SupabaseConfig(url: url, anonKey: key)
    }
}

enum Backend {
    /// Shared client, or nil in offline demo mode.
    static let client: SupabaseClient? = SupabaseConfig.load().map {
        SupabaseClient(supabaseURL: $0.url, supabaseKey: $0.anonKey)
    }

    /// Where Google sign-in returns to. Add it under Authentication → URL Configuration
    /// → Redirect URLs in the Supabase dashboard.
    static let authRedirectURL = URL(string: "fantasyfitness://login-callback")!
}
