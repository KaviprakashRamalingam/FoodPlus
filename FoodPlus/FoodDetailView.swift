//
//  FoodDetailView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
//
//  FoodDetailView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
import SwiftUI
import FirebaseAuth

struct FoodDetailView: View {
    let post: FoodPost
    @State private var comments: [String] = []
    @State private var newComment = ""
    @State private var errorMessage = ""
    @State private var showEmojiPicker = false
    @Environment(\.presentationMode) var presentationMode // Dismiss view

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Post Image with Padding and Rounded Corners
                AsyncImage(url: URL(string: post.imageURL)) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Post Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.description)
                        .font(.headline)
                        .lineLimit(3)

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        Text(post.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Text(post.timePosted, style: .relative)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                Divider()

                // Comments Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comments")
                        .font(.headline)
                        .padding(.horizontal)

                    if comments.isEmpty {
                        Text("No comments yet. Be the first to share your thoughts!")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(comments, id: \ .self) { comment in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.8))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(comment.prefix(1).uppercased())
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        )

                                    Text(comment)
                                        .font(.body)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                // Add a Comment Section
                VStack(spacing: 10) {
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                            .autocapitalization(.none)

                        Button(action: {
                            showEmojiPicker.toggle()
                        }) {
                            Image(systemName: "face.smiling")
                                .font(.title)
                                .padding()
                        }
                    }
                    .padding(.horizontal)

                    Button(action: addComment) {
                        Text("Post Comment")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                                       startPoint: .leading,
                                                       endPoint: .trailing))
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .padding(.top)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Post Details")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if let currentUserEmail = Auth.auth().currentUser?.email, currentUserEmail == post.userEmail {
                    Button(action: deletePost) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear(perform: fetchComments)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $newComment)
        }
    }

    private func addComment() {
        guard let postID = post.id else { return }
        let commentToAdd = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentToAdd.isEmpty else {
            errorMessage = "Comment cannot be empty."
            return
        }
        newComment = ""
        FoodPostService.shared.addComment(postID: postID, comment: commentToAdd) { result in
            switch result {
            case .success:
                comments.append(commentToAdd)
            case .failure(let error):
                errorMessage = "Failed to add comment: \(error.localizedDescription)"
            }
        }
    }

    private func fetchComments() {
        guard let postID = post.id else { return }
        FoodPostService.shared.fetchComments(postID: postID) { result in
            switch result {
            case .success(let fetchedComments):
                comments = fetchedComments
            case .failure(let error):
                errorMessage = "Failed to load comments: \(error.localizedDescription)"
            }
        }
    }

    private func deletePost() {
        guard let postID = post.id else { return }
        FoodPostService.shared.deleteFoodPost(postID: postID) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Emoji Picker
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    let emojis = ["😀", "😂", "😍", "👍", "🔥", "💯", "🥳", "👏", "🤔"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Pick an Emoji")
                .font(.headline)
                .padding()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 5), spacing: 20) {
                ForEach(emojis, id: \ .self) { emoji in
                    Button(action: {
                        selectedEmoji += emoji
                    }) {
                        Text(emoji)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
    }
}

