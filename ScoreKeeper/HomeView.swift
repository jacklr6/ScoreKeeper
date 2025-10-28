//
//  HomeView.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/12/25.
//

import SwiftUI
import GameKit

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("home view!")
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}
