//
//  SignUpView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/12/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var age = ""
    @State private var address = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var errorMessage = ""
    @State private var isSuccess = false
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                TextField("Full Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Age", text: $age)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .keyboardType(.numberPad)

                TextField("Address", text: $address)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                TextField("Email", text: $email)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                Toggle(isOn: $agreeToTerms) {
                    Text("I agree to the Terms and Conditions")
                        .font(.footnote)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: signUp) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(agreeToTerms ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!agreeToTerms)
                }

                if isSuccess {
                    Text("Account created successfully!")
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func signUp() {
        guard !name.isEmpty, !age.isEmpty, !address.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }
        
        // Check if terms are agreed
        guard agreeToTerms else {
            errorMessage = "You must agree to the Terms and Conditions to sign up."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        guard let ageValue = Int(age), ageValue > 0 else {
            errorMessage = "Please enter a valid age."
            return
        }

        errorMessage = ""
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            // Save user details to Firestore
            guard let userID = authResult?.user.uid else { return }
            let userDetails: [String: Any] = [
                "name": name,
                "age": ageValue,
                "address": address,
                "email": email,
                "createdAt": Timestamp()
            ]

            let db = Firestore.firestore()
            db.collection("users").document(userID).setData(userDetails) { error in
                if let error = error {
                    errorMessage = "Failed to save user details: \(error.localizedDescription)"
                } else {
                    isSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
