//
//  RecipesView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/12/24.
//
import SwiftUI 

struct RecipesView: View {
    @State private var query = ""
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Enter a dish name", text: $query)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .autocapitalization(.none)

                    Button(action: fetchRecipes) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Results or Loading/Error/Empty States
                if isLoading {
                    ProgressView()
                        .padding()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if recipes.isEmpty {
                    Text("No recipes found. Try a different query.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Recipe List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Find Recipes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func fetchRecipes() {
        guard !query.isEmpty else {
            errorMessage = "Please enter a dish name."
            return
        }

        isLoading = true
        errorMessage = ""
        recipes = []

        let apiKey = "2ec4a26ef0414d47ad30c75bcdf27ab1"
        let apiURL = "https://api.spoonacular.com/recipes/complexSearch?query=\(query)&apiKey=\(apiKey)&addRecipeInformation=true"

        guard let url = URL(string: apiURL) else {
            errorMessage = "Invalid API URL."
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let result = try JSONDecoder().decode(RecipeResponse.self, from: data)
                    recipes = result.results
                } catch {
                    errorMessage = "Failed to parse data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

    struct RecipeResponse: Codable {
        let results: [Recipe]
    }

    struct Recipe: Identifiable, Codable {
        let id: Int
        let title: String
        let image: String
        let readyInMinutes: Int
        let servings: Int
        let healthScore: Int
        let summary: String
        let pricePerServing: Double
        let sourceUrl: String
    }


    struct RecipeCard: View {
        let recipe: Recipe

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                // Recipe Image
                AsyncImage(url: URL(string: recipe.image)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .cornerRadius(10)
                } placeholder: {
                    Color.gray.opacity(0.2)
                        .frame(height: 200)
                        .cornerRadius(10)
                }

                // Recipe Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(.headline)

                    HStack {
                        Text("⏱ \(recipe.readyInMinutes) mins")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("🍴 Servings: \(recipe.servings)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("💲 $\(recipe.pricePerServing, specifier: "%.2f") per serving")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                        Text("❤️ Health Score: \(recipe.healthScore)")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                // Summary
                Text(recipe.summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

