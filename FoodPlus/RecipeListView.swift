//
//  RecipeListView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/12/24.
//
import SwiftUI

struct RecipeListView: View {
        let recipes: [Recipe]

        var body: some View {
            ScrollView {
                VStack {
                    ForEach(recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCard(recipe: recipe)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
