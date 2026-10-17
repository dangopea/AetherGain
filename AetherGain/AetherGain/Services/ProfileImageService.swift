







import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage

enum ProfileImageService {


    static func upload(image: UIImage) async throws -> URL {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ProfileImage", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in."])
        }
        let resized = image.resized(maxDimension: 600)
        guard let data = resized.jpegData(compressionQuality: 0.75) else {
            throw NSError(domain: "ProfileImage", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't encode image."])
        }
        let ref = Storage.storage().reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let long = max(size.width, size.height)
        guard long > maxDimension else { return self }
        let scale = maxDimension / long
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
