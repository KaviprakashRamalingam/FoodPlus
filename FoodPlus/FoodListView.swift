//
//  FoodListView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import CoreLocation

struct FoodListView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var foodPosts: [FoodPost] = []
    @State private var filteredPosts: [FoodPost] = []
    @State private var errorMessage = ""
    @State private var searchLocation = ""
    @State private var searchCoordinates: CLLocationCoordinate2D?
    @State private var showOptions = false
    @State private var showProfile = false
    @State private var showRecipes = false

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search by location", text: $searchLocation, onCommit: fetchCoordinates)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .autocapitalization(.none)

                    Button(action: fetchCoordinates) {
                        Image(systemName: "magnifyingglass")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Food Posts
                ScrollView {
                    if filteredPosts.isEmpty {
                        VStack {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No food posts available near this location!")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(filteredPosts) { post in
                                NavigationLink(destination: FoodDetailView(post: post)) {
                                    FoodCardView(post: post)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
                .refreshable {
                    fetchPosts() // Pull-to-refresh
                }
            }
            .toolbar {
                // Options button on the left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showOptions = true // Show the bottom sheet
                    }) {
                        Text("Options")
                    }
                }

                // Centered title
                ToolbarItem(placement: .principal) {
                    Text("Tasty Trails")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                // Post button on the right
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewPostView()) {
                        Text("Post")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(foodPosts: foodPosts)
            }
            .sheet(isPresented: $showRecipes) {
                RecipesView()
            }
            .actionSheet(isPresented: $showOptions) {
                ActionSheet(
                    title: Text("Options"),
                    message: Text("What would you like to do?"),
                    buttons: [
                        .default(Text("Profile & Rewards")) {
                            showProfile = true
                        },
                        .default(Text("Recipes")) {
                            showRecipes = true
                        },
                        .destructive(Text("Logout")) {
                            logout()
                        },
                        .cancel()
                    ]
                )
            }
            .onAppear(perform: fetchPosts)
        }
    }

    // Fetch Posts from Firestore
    func fetchPosts() {
        FoodPostService.shared.db.collection("foodPosts")
            .order(by: "timePosted", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
                    return
                }
                foodPosts = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: FoodPost.self)
                } ?? []
                filterPosts() // Apply the filter based on search location
            }
    }

    // Filter Posts by Distance
    func filterPosts() {
        guard let searchCoordinates = searchCoordinates else {
            filteredPosts = foodPosts
            return
        }

        let userLocation = CLLocation(latitude: searchCoordinates.latitude, longitude: searchCoordinates.longitude)
        filteredPosts = foodPosts.filter { post in
            let postLocation = CLLocation(latitude: post.latitude, longitude: post.longitude)
            let distance = userLocation.distance(from: postLocation) / 1609.34 // Convert to miles
            print(post.location)
            print(distance)
            print(userLocation)
            print(postLocation)
            print(searchCoordinates)
            return distance <= 5 // Within 5 miles
        }
    }

    // Fetch Coordinates of the Search Location
    func fetchCoordinates() {
        if searchLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchCoordinates = nil
            filterPosts() // Reset filter to show all posts
            return
        }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchLocation) { placemarks, error in
            if let error = error {
                errorMessage = "Failed to find location: \(error.localizedDescription)"
                return
            }

            if let coordinate = placemarks?.first?.location?.coordinate {
                searchCoordinates = coordinate
                filterPosts() // Re-filter posts with the new location
            } else {
                errorMessage = "Location not found."
            }
        }
    }

    // Logout Function
    func logout() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ProfileView: View {
    @State private var name = "Loading..."
    @State private var age = "Loading..."
    @State private var address = "Loading..."
    @State private var errorMessage = ""

    let foodPosts: [FoodPost]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                ZStack {
                    Color.blue
                        .edgesIgnoringSafeArea(.top)
                        .frame(height: 200)
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text(name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Age: \(age) | Address: \(address)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

                // Rewards Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rewards")
                        .font(.title3)
                        .fontWeight(.bold)

                    // Posts Milestone
                    ProgressView(value: Double(foodPosts.count), total: 10)
                        .padding(.vertical)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(height: 10)
                    
                    Text("You've made \(foodPosts.count) posts!")
                        .font(.subheadline)
                    
                    if foodPosts.count >= 5 {
                        HStack {
                            Image(systemName: "star.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.yellow)
                            Text("🎉 Top Contributor Badge Unlocked!")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)

                // Achievements Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(.title3)
                        .fontWeight(.bold)

                    if foodPosts.count >= 10 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.red)
                            Text("🔥 10-Post Milestone Achieved!")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("Post more to unlock new achievements!")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)

                // Additional Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Info")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Keep sharing more posts to explore exciting rewards and features!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
            .padding()
        }
        .onAppear(perform: fetchUserDetails)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Fetch User Details
    private func fetchUserDetails() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User not logged in."
            return
        }

        let userID = currentUser.uid

        // Assuming you have a Firestore collection named "users"
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                errorMessage = "Failed to fetch user details: \(error.localizedDescription)"
                return
            }

            if let document = document, document.exists {
                let data = document.data() ?? [:]
                name = data["name"] as? String ?? "Unknown"
                if let ageNumber = data["age"] as? Int {
                    age = String(ageNumber)
                } else {
                    age = "Unknown"
                }
                address = data["address"] as? String ?? "Unknown"
            } else {
                errorMessage = "No user details found."
            }
        }
    }
}

struct BarChartView: View {
    let postsCount: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<postsCount, id: \..self) { index in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 20, height: CGFloat((index + 1) * 10))
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 150)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

struct FoodCardView: View {
    let post: FoodPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with consistent size and rounded corners
            AsyncImage(url: URL(string: post.imageURL)) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .clipped()
            } placeholder: {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
                .frame(height: 200)
                .cornerRadius(10)
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(post.description)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse") // Location icon
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(post.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(post.timePosted, style: .relative)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                               startPoint: .top,
                               endPoint: .bottom)
            )
            .cornerRadius(10)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.vertical, 8)
    }
}
