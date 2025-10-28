//
//  GameView.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/12/25.
//

import SwiftUI
import GameKit
import UIKit

struct StartAGameView: View {
    enum gameTypeEnum: String, CaseIterable, Identifiable {
        var id: Self { self }
        
        case cardGames = "Card Game"
        case boardGames = "Board Game"
    }
    
    enum boardGameTypes: String, CaseIterable, Identifiable {
        var id: Self { self }
        
        case sorry = "Sorry!"
        case risk = "Risk"
        case monopoly = "Monopoly"
    }
    
    enum cardGameTypes: String, CaseIterable, Identifiable {
        var id: Self { self }
        
        case solitare = "Solitare"
        case uno = "Uno"
        case spades = "Spades"
        case ginRummy = "Gin Rummy"
        case crazy8s = "Crazy Eights"
    }
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var gameSetup = GameSetupViewModel()
    @State private var gameName: String = ""
    @State private var numberOfPlayers: Int = 1
    @State private var showNameAlert: Bool = false
    @State private var containsPointToggle: Bool = false
    @State private var gameType: gameTypeEnum = .cardGames
    @State private var cardType: cardGameTypes = .solitare
    @State private var boardType: boardGameTypes = .sorry
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Details")) {
                    HStack {
                        TextField("Game Name", text: $gameSetup.name)
                        Button(action: {
                            showNameAlert = true
                        }) {
                            Image(systemName: "info.circle")
                        }
                    }
                    Stepper(value: $gameSetup.playerCount, in: 1...12) {
                        Text("Players: \(gameSetup.playerCount)")
                            .contentTransition(.numericText())
                    }
                    if gameSetup.playerCount > 1 && authViewModel.gameCenterDisplayName != nil {
                        NavigationLink("Invite Friends with GameCenter") {
                            SelectGameCenterFriendsView(viewModel: gameSetup)
                        }
                    }
                    Toggle("Counting Points", isOn: $gameSetup.includesPoints)
                        .toggleStyle(.switch)
                }
                
                Picker("Game Type", selection: $gameSetup.gameCategory) {
                    ForEach(StartAGameView.gameTypeEnum.allCases) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }
                .pickerStyle(.inline)

                if gameSetup.gameCategory == StartAGameView.gameTypeEnum.boardGames.rawValue {
                    Picker("Board Game", selection: Binding(
                        get: { gameSetup.boardGameType ?? StartAGameView.boardGameTypes.sorry.rawValue },
                        set: { gameSetup.boardGameType = $0 }
                    )) {
                        ForEach(StartAGameView.boardGameTypes.allCases) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                } else {
                    Picker("Card Game", selection: Binding(
                        get: { gameSetup.cardGameType ?? StartAGameView.cardGameTypes.solitare.rawValue },
                        set: { gameSetup.cardGameType = $0 }
                    )) {
                        ForEach(StartAGameView.cardGameTypes.allCases) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Get Ready!")) {
                    Group {
                        NavigationLink {
                            if gameSetup.playerCount > 1 {
                                AddPlayerNamesView().environmentObject(gameSetup)
                            } else if gameSetup.includesPoints {
                                AddPointValuesView().environmentObject(gameSetup)
                            } else {
                                EmptyView()
                            }
                        } label: {
                            Group {
                                if gameSetup.playerCount > 1 {
                                    Text("Continue Creating Your Game")
                                } else if gameSetup.includesPoints {
                                    Text("Continue Creating Your Game")
                                } else {
                                    HStack {
                                        Image(systemName: "flag.pattern.checkered.2.crossed")
                                        Text("Start Game")
                                    }
                                }
                            }
                            .transition(.blurReplace())
                            .onTapGesture {
                                if gameSetup.playerCount > 1 && gameSetup.includesPoints {
                                    Task {
                                        try? await gameSetup.saveToCloudKit()
                                    }
                                }
                            }
                        }
                        .disabled(gameSetup.name == "" ? true : false)
                    }
                    .fontWeight(.semibold)
                }
                .animation(.default, value: containsPointToggle)
                .animation(.default, value: gameSetup.includesPoints)
                .animation(.default, value: gameSetup.playerCount)
            }
            .navigationTitle("Start a Game")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .animation(.default, value: gameSetup.playerCount)
            .animation(.default, value: gameType)
            .animation(.default, value: cardType)
            .animation(.default, value: boardType)
            .animation(.default, value: containsPointToggle)
            .animation(.default, value: gameSetup.includesPoints)
            .alert("Name Your Game!", isPresented: $showNameAlert, actions: {
                Button("Sounds Good!") {
                    showNameAlert = false
                }
            }, message: {
                Text("Think of a good name for you to identify this game if you want to play it again.")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct AddPlayerNamesView: View {
    @EnvironmentObject var gameSetup: GameSetupViewModel
    
    var body: some View {
        Form {
            ForEach(0..<gameSetup.playerCount, id: \.self) { index in
                TextField("Player \(index + 1)", text: binding(for: index))
            }
            
            NavigationLink(destination: AddPointValuesView().environmentObject(gameSetup)) {
                Text("Next: Points")
            }
        }
        .navigationTitle("Add Players")
        .onAppear {
            if gameSetup.players.count != gameSetup.playerCount {
                gameSetup.players = Array(repeating: "", count: gameSetup.playerCount)
            }
        }
    }
    
    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                if index < gameSetup.players.count {
                    return gameSetup.players[index]
                } else {
                    return ""
                }
            },
            set: { newValue in
                if index < gameSetup.players.count {
                    gameSetup.players[index] = newValue
                }
            }
        )
    }
}

struct SelectGameCenterFriendsView: View {
    @ObservedObject var viewModel: GameSetupViewModel
    @State private var allFriends: [GKPlayer] = []
    @State private var noFriendsAnimation: Bool = true
    @State private var switchFriendIcon: Bool = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    if allFriends.isEmpty {
                        if #available(iOS 26.0, *) {
                            Image(systemName: switchFriendIcon ? "person" : "person.3")
                                .font(.system(size: 100))
                                .symbolEffect(.drawOn.individually, isActive: noFriendsAnimation)
                                .padding(.bottom, -10)
                                .contentTransition(.symbolEffect(.automatic))
                                .frame(height: 100)
                        } else {
                            Image(systemName: "person.3")
                                .font(.system(size: 100))
                                .symbolEffect(.bounce, isActive: noFriendsAnimation)
                                .padding(.bottom, -10)
                        }
                        
                        Text("No Friends Found!")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Invite your friends to ScoreKeeper to play with them, otherwise you can add their name manually without GameCenter!")
                            .padding(.horizontal, 20)
                            .multilineTextAlignment(.center)
                    } else {
                        List(allFriends, id: \.gamePlayerID) { (friend: GKPlayer) in
                            Button {
                                viewModel.toggleFriend(friend)
                            } label: {
                                HStack {
                                    Text(friend.displayName)
                                    Spacer()
                                    if viewModel.gameCenterFriends.contains(where: { $0.id == friend.gamePlayerID }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Game Center Friends")
        }
        .onAppear {
            Task {
                await loadFriends()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                noFriendsAnimation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                switchFriendIcon = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    fetchFriends()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: URL(string: "https://apps.apple.com/app/id6752631683")!
                )
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    
                }) {
                    Image(systemName: "gear")
                }
            }
        }
    }
    
    private func loadFriends() async {
        do {
            let friends = try await GKLocalPlayer.local.loadFriends()
            // Cast each friend to GKPlayer explicitly
            let players = friends.compactMap { $0 as? GKPlayer }
            
            await MainActor.run {
                allFriends = players
                print("Friends Fetched: \(allFriends.count)")
            }
        } catch {
            print("Failed to Load Friends: \(error)")
        }
    }
    
    func fetchFriends() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            let start = Date()
            await loadFriends()
            
            let elapsed = Date().timeIntervalSince(start)
            if elapsed < 0.5 {
                try? await Task.sleep(nanoseconds: UInt64((0.5 - elapsed) * 1_000_000_000))
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct AddPointValuesView: View {
    var body: some View {
        Text("points")
    }
}

struct StartAGameView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}

//struct SelectFriendView_Previews: PreviewProvider {
//    static var previews: some View {
//        SelectGameCenterFriendsView(viewModel: GameSetupViewModel())
//            .environmentObject(AuthViewModel())
//    }
//}
