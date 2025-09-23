//
//  ScoreKeeperApp.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/12/25.
//

import SwiftUI
import GameKit

@main
struct MyApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }

}

