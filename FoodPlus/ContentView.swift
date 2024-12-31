//
//  ContentView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
import SwiftUI
//import Firebase

struct ContentView: View {
    // Simulate user authentication status
    @State private var isUserLoggedIn = false

    var body: some View {
        VStack {
            if isUserLoggedIn {
                FoodListView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                LoginView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
