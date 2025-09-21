import Foundation
import AuthenticationServices
import CloudKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var userIdentifier: String?
    @Published var errorMessage: String?

    private let container = CKContainer.default()

    // MARK: - Sign in with Apple
    
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleID = auth.credential as? ASAuthorizationAppleIDCredential {
                self.userIdentifier = appleID.user
                self.isSignedIn = true
            }
        case .failure(let error):
            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - CloudKit Functions
    
    func saveToCloudKit() {
        let record = CKRecord(recordType: "UserData")
        record["message"] = "Hello from iCloud!" as CKRecordValue
        
        container.privateCloudDatabase.save(record) { _, error in
            if let error = error {
                Task { @MainActor in self.errorMessage = "Save failed: \(error.localizedDescription)" }
            }
        }
    }
    
    func fetchFromCloudKit() {
        let query = CKQuery(recordType: "UserData", predicate: NSPredicate(value: true))
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["message"]
        operation.resultsLimit = 50
        
        var fetched: [CKRecord] = []
        
        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                fetched.append(record)
            case .failure(let error):
                Task { @MainActor in self.errorMessage = "Fetch error: \(error.localizedDescription)" }
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .success:
                print("Fetched: \(fetched)")
            case .failure(let error):
                Task { @MainActor in self.errorMessage = "Query error: \(error.localizedDescription)" }
            }
        }
        
        container.privateCloudDatabase.add(operation)
    }
}
