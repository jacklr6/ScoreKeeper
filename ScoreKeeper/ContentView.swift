//
//  ContentView.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/12/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("appOpenCounter") private var appOpenCounter: Int = 0
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var tabSelection: Int = 2
    
    var body: some View {
        NavigationView {
            TabView(selection: $tabSelection) {
                Tab("Account", systemImage: "person.crop.circle.fill", value: 1) {
                    AccountView()
                }
                
                Tab("Home", systemImage: "house", value: 2) {
                    HomeView()
                }
                
                Tab("Start a Game", systemImage: "gamecontroller", value: 3) {
                    StartAGameView()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation {
                appOpenCounter += 1
            }
            authViewModel.loadExistingAccount()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
