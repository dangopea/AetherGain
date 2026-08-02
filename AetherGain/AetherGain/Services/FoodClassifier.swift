//
//  FoodClassifier.swift
//  AetherGain
//
//  Optional CoreML food classifier with a Vision-built-in fallback.
//
//  If the app bundle contains a compiled model called `FoodClassifier.mlmodelc`
//  (Xcode compiles `.mlmodel` / `.mlpackage` into `.mlmodelc` at build time),
//  we use it via `VNCoreMLRequest` — much better food-specific labels
//  ("apple_pie", "sushi", "biryani"...) than Apple's generic taxonomy.
//
//  If no model is bundled, we fall back to `VNClassifyImageRequest` so the
//  feature still runs — labels will just be less food-specific.
//
//  To drop in a model: rename any Food-101 style `.mlmodel` file to
//  `FoodClassifier.mlmodel`, drag into the AetherGain group in Xcode, tick the
//  AetherGain target, rebuild. The code below finds it automatically.
//

import Foundation
import CoreML
import Vision
import UIKit

struct ClassifiedFood {
    let label: String
    let confidence: Float
}

enum FoodClassifierError: Error, LocalizedError {
    case invalidImage
    case classificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Couldn't read this image."
        case .classificationFailed(let msg): return "Vision failure: \(msg)"
        }
    }
}

enum FoodClassifier {

    // MARK: - Bundled model detection

    /// Lazily loaded VNCoreMLModel wrapper. `nil` means no food-specific model
    /// is bundled and we fall back to Apple's generic classifier.
    private static let bundledModel: VNCoreMLModel? = loadBundledModel()

    private static func loadBundledModel() -> VNCoreMLModel? {
        let bundle = Bundle.main
        let candidates: [URL?] = [
            bundle.url(forResource: "FoodClassifier", withExtension: "mlmodelc"),
            bundle.url(forResource: "FoodClassifier", withExtension: "mlmodel")
        ]

        for case let url? in candidates {
            do {
                let mlModel = try MLModel(contentsOf: url)
                let vn = try VNCoreMLModel(for: mlModel)
                print("[FoodClassifier] Bundled model loaded from \(url.lastPathComponent)")
                return vn
            } catch {
                print("[FoodClassifier] Failed to load bundled model at \(url): \(error)")
            }
        }
        print("[FoodClassifier] No bundled FoodClassifier model — using Vision default classifier.")
        return nil
    }

    static var isBundledModelAvailable: Bool { bundledModel != nil }

    // MARK: - Public entry point

    /// Runs the best available classifier for `image`. `completion` fires on
    /// an arbitrary queue with the top 15 classified labels by confidence.
    static func classify(image: UIImage,
                         completion: @escaping (Result<[ClassifiedFood], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(FoodClassifierError.invalidImage))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let model = bundledModel {
                runCoreMLModel(model, on: cgImage, completion: completion)
            } else {
                runVisionDefault(on: cgImage, completion: completion)
            }
        }
    }

    // MARK: - Runners

    private static func runCoreMLModel(_ model: VNCoreMLModel,
                                       on cgImage: CGImage,
                                       completion: @escaping (Result<[ClassifiedFood], Error>) -> Void) {
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let results = request.results as? [VNClassificationObservation] else {
                completion(.failure(FoodClassifierError.classificationFailed("No observations.")))
                return
            }
            let top = results
                .sorted { $0.confidence > $1.confidence }
                .prefix(15)
                .map { ClassifiedFood(label: normalize($0.identifier),
                                      confidence: $0.confidence) }
            completion(.success(Array(top)))
        }
        // Center-crop matches how most Food-101 models were trained.
        request.imageCropAndScaleOption = .centerCrop
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        } catch {
            completion(.failure(error))
        }
    }

    private static func runVisionDefault(on cgImage: CGImage,
                                         completion: @escaping (Result<[ClassifiedFood], Error>) -> Void) {
        let request = VNClassifyImageRequest()
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            let results = request.results ?? []
            let top = results
                .sorted { $0.confidence > $1.confidence }
                .prefix(15)
                .map { ClassifiedFood(label: normalize($0.identifier),
                                      confidence: $0.confidence) }
            completion(.success(Array(top)))
        } catch {
            completion(.failure(error))
        }
    }

    /// Food-101 labels come as snake_case ("apple_pie"). Normalize to human
    /// form ("apple pie") for display + FoodDatabase matching.
    private static func normalize(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
    }
}
