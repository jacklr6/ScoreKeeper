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
import CloudKit

@MainActor
class GameSetupViewModel: ObservableObject {
    struct GameCenterFriend: Identifiable, Codable {
        let id: String
        let displayName: String
    }
    
    private let database = CKContainer.default().privateCloudDatabase
    
    @Published var id = UUID()
    @Published var name: String = ""
    @Published var type: String = "Card Game"
    @Published var playerCount: Int = 1
    @Published var players: [String] = []
    @Published var includesPoints: Bool = false
    @Published var gameCenterFriends: [GameCenterFriend] = []
    @Published var errorMessage: String?
    
    @Published var gameCategory: String = StartAGameView.gameTypeEnum.cardGames.rawValue
    @Published var cardGameType: String? = nil
    @Published var boardGameType: String? = nil
    
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
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "Game", recordID: recordID)
        
        record["name"] = name as CKRecordValue
        record["playerCount"] = playerCount as CKRecordValue
        record["includesPoints"] = includesPoints as CKRecordValue
        record["gameCategory"] = gameCategory as CKRecordValue

        if let cardType = cardGameType {
            record["cardGameType"] = cardType as CKRecordValue
        }
        if let boardType = boardGameType {
            record["boardGameType"] = boardType as CKRecordValue
        }
        
        if !players.isEmpty {
            record["players"] = players as CKRecordValue
        }
        
        let friendIDs = gameCenterFriends.map { $0.id }
        if !friendIDs.isEmpty {
            record["friendIDs"] = friendIDs as CKRecordValue
        }
        
        let friendNames = gameCenterFriends.map { $0.displayName }
        if !friendNames.isEmpty {
            record["friendNames"] = friendNames as CKRecordValue
        }
        
        do {
            try await database.save(record)
            print("✅ Game saved successfully to CloudKit")
        } catch {
            print("❌ Error saving game to CloudKit: \(error)")
            throw error
        }
    }
}
