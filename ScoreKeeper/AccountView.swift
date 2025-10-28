//
//  AccountView.swift
//  ScoreKeeper
//
//  Created by Jack Rogers on 9/12/25.
//

import SwiftUI
import AuthenticationServices
import CloudKit

struct AccountView: View {
    @AppStorage("appOpenCounter") private var appOpenCounter: Int = 0
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var profilePictureAnimation: Bool = true
    @State private var infoTextAnimation: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if #available(iOS 26.0, *) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 140, weight: .light))
                        .symbolEffect(.drawOn.individually, isActive: profilePictureAnimation)
                        .padding(.bottom, -10)
                } else {
                    Image(systemName: "person.circle")
                        .font(.system(size: 100))
                        .padding(.bottom, -10)
                }
                
                if authViewModel.isSignedIn {
                    if let name = authViewModel.fullName {
                        Text("Welcome")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, -15)
                        Text("\(name)")
                            .font(.title2)
                    } else {
                        Text("Welcome back")
                    }
                    
                    if let email = authViewModel.email {
                        Text("\(email)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, -15)
                    }
                    
                    Button("Save sample data to CloudKit") {
                        authViewModel.saveToCloudKit()
                    }
                    
                    Button("Sign Out") {
                        authViewModel.signOutLocal()
                    }
                } else {
                    if appOpenCounter >= 1 {
                        Text("Sign In")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        SignInWithAppleButton(.signIn, onRequest: { req in authViewModel.configureRequest(req) }, onCompletion: { result in authViewModel.handleAuthorizationResult(result) })
                            .signInWithAppleButtonStyle(.black)
                            .frame(width: 280, height: 45)
                    } else {
                        Text("Sign Up")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        SignInWithAppleButton(.signIn, onRequest: { req in authViewModel.configureRequest(req) }, onCompletion: { result in authViewModel.handleAuthorizationResult(result) })
                            .signInWithAppleButtonStyle(.black)
                            .frame(width: 280, height: 45)
                    }
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
                
                if !authViewModel.isSignedIn {
                    if infoTextAnimation {
                        Text("An account is needed to store games in your iCloud account, otherwise it will be stored locally on your iPhone.")
                            .padding(.horizontal, 30)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
            .navigationTitle("Account")
            .toolbar {
                if authViewModel.isSignedIn {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            authViewModel.fetchUserProfile()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    profilePictureAnimation = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation {
                        infoTextAnimation = true
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
