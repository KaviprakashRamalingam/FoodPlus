//
//  ImgurService.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//
import Foundation
import UIKit

class ImgurService {
    static let shared = ImgurService()
    private let clientID = "219b0f2c240beef" // Replace with your Imgur Client ID
    private let uploadURL = "https://api.imgur.com/3/image"

    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Invalid image", code: 0)))
            return
        }

        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "POST"
        request.addValue("Client-ID \(clientID)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = createBody(boundary: boundary, data: imageData, mimeType: "image/jpeg", filename: "image.jpg")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let dataObject = json["data"] as? [String: Any],
                  let link = dataObject["link"] as? String else {
                completion(.failure(NSError(domain: "Imgur API error", code: 0)))
                return
            }

            completion(.success(link))
        }

        task.resume()
    }

    private func createBody(boundary: String, data: Data, mimeType: String, filename: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

