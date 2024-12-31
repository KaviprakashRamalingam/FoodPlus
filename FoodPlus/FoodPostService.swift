//
//  FoodPostService.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
//import Firebase
//import FirebaseFirestore
//import FirebaseStorage
//
//class FoodPostService {
//    static let shared = FoodPostService()
//    private let db = Firestore.firestore()
//    private let storage = Storage.storage()
//
//    // Upload an image to Firebase Storage
//    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
//        let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
//
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            completion(.failure(NSError(domain: "Invalid image", code: 0)))
//            return
//        }
//
//        storageRef.putData(imageData, metadata: nil) { _, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            storageRef.downloadURL { url, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//
//                if let url = url {
//                    completion(.success(url.absoluteString))
//                }
//            }
//        }
//    }
//
//    // Save a FoodPost to Firestore
//    func saveFoodPost(foodPost: FoodPost, completion: @escaping (Result<Void, Error>) -> Void) {
//        do {
//            _ = try db.collection("foodPosts").addDocument(from: foodPost)
//            completion(.success(()))
//        } catch {
//            completion(.failure(error))
//        }
//    }
//}
//

import FirebaseFirestore

class FoodPostService {
    static let shared = FoodPostService()
    private let firestore = Firestore.firestore()

    // Provide read-only access to the database
    var db: Firestore {
        return firestore
    }
    func addComment(postID: String, comment: String, completion: @escaping (Result<Void, Error>) -> Void) {
            let postRef = db.collection("foodPosts").document(postID)
            postRef.updateData([
                "comments": FieldValue.arrayUnion([comment])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }

        // Fetch comments for a post
        func fetchComments(postID: String, completion: @escaping (Result<[String], Error>) -> Void) {
            let postRef = db.collection("foodPosts").document(postID)
            postRef.getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let data = snapshot?.data(), let comments = data["comments"] as? [String] {
                    completion(.success(comments))
                } else {
                    completion(.success([])) // Return empty array if no comments
                }
            }
        }
    // Save a FoodPost to Firestore
    func saveFoodPost(foodPost: FoodPost, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try firestore.collection("foodPosts").addDocument(from: foodPost)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Delete a FoodPost from Firestore
        func deleteFoodPost(postID: String, completion: @escaping (Result<Void, Error>) -> Void) {
            firestore.collection("foodPosts").document(postID).delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
}
