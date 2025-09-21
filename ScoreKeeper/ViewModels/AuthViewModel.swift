//
//  AuthViewModel.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/12/25.
//

import Foundation
import AuthenticationServices
import CloudKit
import Combine
import SwiftUI

@MainActor
class AuthViewModel: NSObject, ObservableObject {
    @Published var userIdentifier: String?
    @Published var fullName: String?
    @Published var email: String?
    @Published var isSignedIn: Bool = false
    @Published var needsProfileCompletion: Bool = false
    @Published var errorMessage: String?

    private let container = CKContainer.default()
    private let defaultsKey = "appleUserID"

    override init() {
        super.init()
        loadExistingAccount()
    }

    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    // Call from SignInWithAppleButton's onCompletion:
    func handleAuthorizationResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                processAppleCredential(credential)
            } else {
                Task { @MainActor in
                    self.errorMessage = "Received unexpected credential type."
                }
            }
        case .failure(let error):
            Task { @MainActor in
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }

    private func processAppleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        let userID = credential.user
        self.userIdentifier = userID
        UserDefaults.standard.set(userID, forKey: defaultsKey)

        var gotNewInfo = false
        if let nameComponents = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            self.fullName = formatter.string(from: nameComponents)
            gotNewInfo = true
        }
        if let mail = credential.email {
            self.email = mail
            gotNewInfo = true
        }

        if gotNewInfo {
            saveUserProfile()
            self.needsProfileCompletion = false
        } else {
            fetchUserProfile()
        }
        
        withAnimation {
            self.isSignedIn = true
        }
    }

    func loadExistingAccount() {
        guard let savedID = UserDefaults.standard.string(forKey: defaultsKey) else {
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: savedID) { [weak self] state, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let err = error {
                    self.errorMessage = "getCredentialState error: \(err.localizedDescription)"
                    self.signOutLocal()
                    return
                }
                switch state {
                case .authorized:
                    self.userIdentifier = savedID
                    self.fetchUserProfile()
                    withAnimation {
                        self.isSignedIn = true
                    }
                case .revoked, .notFound:
                    print("[AuthVM] Credential revoked / not found")
                    self.signOutLocal()
                default:
                    break
                }
            }
        }
    }

    func fetchUserProfile() {
        guard let userID = userIdentifier else {
            print("[AuthVM] fetchUserProfile: no userIdentifier")
            return
        }

        let recordID = CKRecord.ID(recordName: userID)
        print("[AuthVM] Fetching UserProfile for recordID: \(recordID.recordName)")

        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let ckErr = error as? CKError {
                    if ckErr.code == .unknownItem {
                        print("[AuthVM] No UserProfile record in CloudKit (unknownItem)")
                        self.needsProfileCompletion = true
                        return
                    } else {
                        self.errorMessage = "CloudKit fetch error: \(ckErr.localizedDescription)"
                        print("[AuthVM] CloudKit fetch error: \(ckErr)")
                        return
                    }
                }

                if let err = error {
                    self.errorMessage = "Fetch error: \(err.localizedDescription)"
                    print("[AuthVM] Fetch error: \(err)")
                    return
                }

                if let record = record {
                    withAnimation {
                        self.fullName = record["fullName"] as? String
                        self.email = record["email"] as? String
                        print("[AuthVM] Loaded from CloudKit: \(self.fullName ?? "-"), \(self.email ?? "-")")
                        self.needsProfileCompletion = (self.fullName == nil && self.email == nil)
                    }
                } else {
                    // No record returned (safe-guard)
                    self.needsProfileCompletion = true
                    print("[AuthVM] No record returned (nil).")
                }
            }
        }
    }

    func saveUserProfile(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let userID = userIdentifier else {
            completion?(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userIdentifier"])))
            return
        }

        let recordID = CKRecord.ID(recordName: userID)
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] existing, fetchError in
            Task { @MainActor in
                guard let self = self else { return }

                var record: CKRecord
                if let existing = existing {
                    record = existing
                } else {
                    record = CKRecord(recordType: "UserProfile", recordID: recordID)
                }
                
                withAnimation {
                    if let name = self.fullName { record["fullName"] = name as CKRecordValue }
                    if let mail = self.email { record["email"] = mail as CKRecordValue }
                }

                self.container.privateCloudDatabase.save(record) { saved, saveError in
                    Task { @MainActor in
                        if let saveError = saveError {
                            self.errorMessage = "Save failed: \(saveError.localizedDescription)"
                            print("[AuthVM] Save failed: \(saveError)")
                            completion?(.failure(saveError))
                        } else {
                            print("[AuthVM] Profile saved/updated in CloudKit")
                            self.needsProfileCompletion = false
                            completion?(.success(()))
                        }
                    }
                }
            }
        }
    }

    func signOutLocal() {
        withAnimation {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
            userIdentifier = nil
            fullName = nil
            email = nil
            isSignedIn = false
            needsProfileCompletion = false
            errorMessage = nil
        }
    }
    
    func saveToCloudKit() {
        let record = CKRecord(recordType: "UserData")
        record["ownerID"] = userIdentifier as CKRecordValue?
        print(record)
        
        container.privateCloudDatabase.save(record) { _, error in
            if let error = error {
                Task { @MainActor in self.errorMessage = "Save failed: \(error.localizedDescription)" }
            }
        }
    }
}
