import Foundation
import SwiftUI
import GameKit

@MainActor
class GameSetupViewModel: ObservableObject {
    struct GameCenterFriend: Identifiable, Codable {
        let id: String // GKPlayerID
        let displayName: String
    }
    
    @Published var id = UUID()
    @Published var name: String = ""
    @Published var type: String = "Card Game" // or board game
    @Published var playerCount: Int = 1
    @Published var players: [String] = []
    @Published var includesPoints: Bool = false
    @Published var gameCenterFriends: [GameCenterFriend] = []
    
    // Resets state if user cancels setup
    func reset() {
        id = UUID()
        name = ""
        type = "Card Game"
        playerCount = 1
        players = []
        includesPoints = false
        gameCenterFriends = []
    }
    
    // Example of adding friends manually
    func addFriend(_ player: GKPlayer) {
        let friend = GameCenterFriend(id: player.gamePlayerID,
                                      displayName: player.displayName)
        if !gameCenterFriends.contains(where: { $0.id == friend.id }) {
            gameCenterFriends.append(friend)
        }
    }
    
    // Final CloudKit save call placeholder
    func saveToCloudKit() async throws {
        // create CKRecord and save
        // you'll handle actual CK logic here
        print("Saving game: \(name) with \(players.count) players and \(gameCenterFriends.count) friends")
    }
}
