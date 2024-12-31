//
//  NewPostView.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
import SwiftUI
import MapKit
import FirebaseAuth // Import to get the current user

struct NewPostView: View {
    @State private var searchCompleterDelegate: SearchCompleterDelegate?
    @State private var foodName = ""
    @State private var location = ""
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var searchResults = [MKLocalSearchCompletion]()
    @State private var showSuggestions = false
    @State private var isUploading = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false // Alert trigger

    @Environment(\.presentationMode) var presentationMode // Dismiss view

    private let searchCompleter = MKLocalSearchCompleter()

    var body: some View {
        VStack(spacing: 20) {
            // Food Name Input
            TextField("Enter food name", text: $foodName)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            // Location Input with Suggestions
            VStack(alignment: .leading) {
                TextField("Enter location", text: $location, onEditingChanged: { isEditing in
                    showSuggestions = isEditing
                })
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .onChange(of: location, perform: { query in
                    fetchLocationSuggestions(for: query)
                })

                if showSuggestions {
                    List(searchResults, id: \.self) { result in
                        Button(action: {
                            location = result.title
                            showSuggestions = false
                            updateMapCamera(for: result)
                        }) {
                            VStack(alignment: .leading) {
                                Text(result.title).font(.headline)
                                Text(result.subtitle).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            // Image Picker
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Button("Upload Image") {
                    showingImagePicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // Map
            Map(position: $cameraPosition, interactionModes: .all)
                .frame(height: 200)

            // Post Button
            Button("Post") {
                savePost()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isUploading ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isUploading)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Post")
                    .font(.headline)
            }
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("Post Saved"),
                message: Text("Your post was successfully saved."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            configureSearchCompleter()
        }
    }

    // MARK: - Save Post
    private func savePost() {
        guard let image = selectedImage else {
            errorMessage = "Please select an image."
            return
        }

        guard let userEmail = Auth.auth().currentUser?.email else {
            errorMessage = "User not logged in."
            return
        }

        isUploading = true
        errorMessage = ""

        geocodeLocation(location) { result in
            switch result {
            case .success(let coordinate):
                ImgurService.shared.uploadImage(self.selectedImage!) { uploadResult in
                    switch uploadResult {
                    case .success(let imageURL):
                        // Save the post with the uploaded image URL and user email
                        let foodPost = FoodPost(
                            imageURL: imageURL,
                            description: self.foodName,
                            location: self.location,
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude,
                            timePosted: Date(),
                            userEmail: userEmail
                        )
                        FoodPostService.shared.saveFoodPost(foodPost: foodPost) { saveResult in
                            self.isUploading = false
                            switch saveResult {
                            case .success:
                                self.showSuccessAlert = true // Trigger success alert
                            case .failure(let error):
                                self.errorMessage = "Failed to save post: \(error.localizedDescription)"
                            }
                        }
                    case .failure(let error):
                        self.isUploading = false
                        self.errorMessage = "Image upload failed: \(error.localizedDescription)"
                    }
                }
            case .failure(let error):
                self.isUploading = false
                self.errorMessage = "Failed to fetch coordinates: \(error.localizedDescription)"
            }
        }
    }


    // MARK: - Configure Search Completer
     func configureSearchCompleter() {
        let delegate = SearchCompleterDelegate { completions in
            self.searchResults = completions
        }
        searchCompleterDelegate = delegate
        searchCompleter.delegate = delegate
        searchCompleter.resultTypes = .address
    }

    // MARK: - Fetch Location Suggestions
    private func fetchLocationSuggestions(for query: String) {
        searchCompleter.queryFragment = query
    }

    // MARK: - Update Map Camera
    private func updateMapCamera(for result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
    
    func geocodeLocation(_ location: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let coordinate = placemarks?.first?.location?.coordinate {
                completion(.success(coordinate))
            } else {
                let error = NSError(domain: "GeocodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Location not found."])
                completion(.failure(error))
            }
        }
    }

}

class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let completionHandler: ([MKLocalSearchCompletion]) -> Void

    init(completionHandler: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.completionHandler = completionHandler
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completionHandler(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer failed: \(error.localizedDescription)")
    }
}
