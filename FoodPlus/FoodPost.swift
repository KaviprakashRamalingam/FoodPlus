//
//  FoodPost.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
import Foundation
import FirebaseFirestore

struct FoodPost: Identifiable, Codable {
    @DocumentID var id: String? // Firestore assigns this automatically
    var imageURL: String
    var description: String
    var location: String
    var latitude: Double
    var longitude: Double
    var timePosted: Date
    var userEmail: String
    var comments: [String] = []
}
