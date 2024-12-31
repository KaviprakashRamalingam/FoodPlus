//
//  RecipeDetailView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/12/24.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe Image
                AsyncImage(url: URL(string: recipe.image)) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .frame(height: 200)
                        .cornerRadius(12)
                }

                // Title and Ready Time
                Text(recipe.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Ready in \(recipe.readyInMinutes) minutes")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Calorie Bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(.headline)

                    if let calories = extractCalories(from: recipe.summary) {
                        Text("\(calories) kcal")
                            .font(.subheadline)
                        ProgressView(value: CGFloat(calories), total: 1000)
                            .tint(.green)
                    } else {
                        Text("Calorie information not available.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this Recipe")
                        .font(.headline)
                    Text(recipe.summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .font(.body)
                        .foregroundColor(.gray)
                }

                // Instructions Placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.headline)
                    Text("Instructions for this recipe are currently unavailable.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Function to extract calorie information from the summary
    private func extractCalories(from summary: String) -> Int? {
        let pattern = "\\b(\\d+)\\s?kcal\\b"
        if let match = summary.range(of: pattern, options: .regularExpression) {
            let caloriesString = String(summary[match])
            return Int(caloriesString.filter { $0.isNumber })
        }
        return nil
    }
}
