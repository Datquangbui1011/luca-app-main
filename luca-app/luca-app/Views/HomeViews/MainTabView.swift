//
//  MainTabView.swift
//  luca-app
//
//  Created by Đạt Bùi on 11/6/25.
//


import SwiftUI

struct MainTabView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        TabView {
            NavigationStack {
                HomeTab(isAuthenticated: $isAuthenticated)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            // Provide a NavigationStack at the tab level so pushed views keep the tab bar visible
            NavigationStack {
                AssessPatientView()
            }
            .tabItem {
                Label("Assess", systemImage: "stethoscope")
            }

            NavigationStack {
                CoachingFeatureView()
            }
            .tabItem {
                Label("Coaching", systemImage: "person.2")
            }

            NavigationStack {
                AccountManagementView(isAuthenticated: $isAuthenticated)
            }
            .tabItem {
                Label("Account", systemImage: "person.circle")
            }
        }
    }
}
