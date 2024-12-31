//
//  LoginView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
//
import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

struct LoginView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToFoodList = false
    @State private var errorMessage = ""
    @State private var logoOpacity = 0.0 // For fade-in animation
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    // Grey background
                    Color(.systemGray6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        // App Logo
                        Image("Tasty")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .opacity(logoOpacity)
                            .onAppear {
                                withAnimation(.easeIn(duration: 1.0)) {
                                    logoOpacity = 1.0
                                }
                            }
                            .padding(.top, 40)
                        
                        // Welcome Title
                        Text("Welcome to Tasty Trails")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.bottom, 20)
                        
                        // Input Fields
                        VStack(spacing: 15) {
                            TextField("Enter Email", text: $email)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                            SecureField("Enter Password", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        // Forgot Password
                            Button(action: { showForgotPassword = true }) {
                                Text("Forgot Password?")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                            .padding(.bottom, 10)
                            .sheet(isPresented: $showForgotPassword) {
                                ForgotPasswordView()
                            }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Buttons
                        VStack(spacing: 15) {
                            Button(action: login) {
                                Text("Login")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .cornerRadius(8)
                                    .shadow(color: .blue.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            
                            // "or" divider
                            Text("or")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: { showSignUp = true }) {
                                Text("Sign Up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .cornerRadius(8)
                                    .shadow(color: .green.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            .sheet(isPresented: $showSignUp) {
                                SignUpView(isUserLoggedIn: $isUserLoggedIn)
                            }
                            
//                            Button(action: googleSignIn) {
//                                HStack {
//                                    Image(systemName: "g.circle.fill")
//                                        .font(.title2)
//                                    Text("Sign in with Google")
//                                        .font(.headline)
//                                }
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color(.systemGray))
//                                .foregroundColor(.white)
//                                .cornerRadius(8)
//                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
//                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            isUserLoggedIn = true
        }
    }


    func googleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Firebase Client ID"
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            if let error = error {
                self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                  self.errorMessage = "Failed to retrieve ID token"
                  return
            }

            // Access token is a non-optional String
            let accessToken = user.accessToken.tokenString

            // Use Firebase Authentication with the credentials
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    self.errorMessage = "Firebase Authentication failed: \(error.localizedDescription)"
                    return
                }

                // Successful sign-in
                self.isUserLoggedIn = true
            }
        }


        func getRootViewController() -> UIViewController {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                fatalError("Unable to find root view controller")
            }
            return rootViewController
        }
    }
}
