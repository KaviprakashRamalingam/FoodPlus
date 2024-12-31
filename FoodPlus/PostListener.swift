//
//  PostListener.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/12/24.
//
import Firebase
import FirebaseFirestore

class PostListener: ObservableObject {
    private let db = Firestore.firestore()

    func startListeningForNewPosts() {
        db.collection("foodPosts")
            .order(by: "timePosted", descending: true)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching new posts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, let firstDoc = documents.first else { return }
                let newPostData = firstDoc.data()
                if let description = newPostData["description"] as? String {
                    NotificationManager.shared.triggerNotification(
                        title: "New Post Available!",
                        body: description
                    )
                }
            }
    }
}

