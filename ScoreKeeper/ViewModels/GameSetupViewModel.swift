//
//  GameSetupViewModel.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/18/25.
//

import Foundation
import SwiftUI
import GameKit
import Combine

@MainActor
class GameSetupViewModel: ObservableObject {
    struct GameCenterFriend: Identifiable, Codable {
        let id: String
        let displayName: String
    }
    
    @Published var id = UUID()
    @Published var name: String = ""
    @Published var type: String = "Card Game"
    @Published var playerCount: Int = 1
    @Published var players: [String] = []
    @Published var includesPoints: Bool = false
    @Published var gameCenterFriends: [GameCenterFriend] = []
    
    func reset() {
        id = UUID()
        name = ""
        type = "Card Game"
        playerCount = 1
        players = []
        includesPoints = false
        gameCenterFriends = []
    }
    
    func addFriend(_ player: GKPlayer) {
        let friend = GameCenterFriend(id: player.gamePlayerID,
                                      displayName: player.displayName)
        if !gameCenterFriends.contains(where: { $0.id == friend.id }) {
            gameCenterFriends.append(friend)
        }
    }
    
    func saveToCloudKit() async throws {
        print("Saving game: \(name) with \(players.count) players and \(gameCenterFriends.count) friends")
    }
}
