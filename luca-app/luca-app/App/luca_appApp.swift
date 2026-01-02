//
//  luca_appApp.swift
//  luca-app
//
//  Created by Dane Troia on 9/29/25.
//

import SwiftUI
import SwiftData

@main
struct luca_appApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)

        }
        .modelContainer(sharedModelContainer)
    }
}
