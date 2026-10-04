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
//  The bundled model file must be called `AetherGainFoodModel.mlmodel`.
//  MLTraining/train_model.swift writes it straight into this folder, which is
//  an Xcode synchronized group, so it joins the target on the next build.
//

import Foundation
import CoreML
import Vision
import UIKit
import ImageIO

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
        // Named AetherGainFoodModel, not FoodClassifier: a .mlmodel generates a
        // Swift class after the file name, which would collide with this enum.
        let candidates: [URL?] = [
            bundle.url(forResource: "AetherGainFoodModel", withExtension: "mlmodelc"),
            bundle.url(forResource: "AetherGainFoodModel", withExtension: "mlmodel")
        ]

        // The Simulator has no Neural Engine and emulates Metal, so a model left
        // on .all cannot build an inference context. Devices try .all first.
        let configurations: [MLComputeUnits] = {
            #if targetEnvironment(simulator)
            return [.cpuOnly]
            #else
            return [.all, .cpuOnly]
            #endif
        }()

        for case let url? in candidates {
            for units in configurations {
                do {
                    let config = MLModelConfiguration()
                    config.computeUnits = units
                    let mlModel = try MLModel(contentsOf: url, configuration: config)
                    let vn = try VNCoreMLModel(for: mlModel)
                    print("[FoodClassifier] Bundled model loaded from \(url.lastPathComponent) (computeUnits: \(units))")
                    return vn
                } catch {
                    print("[FoodClassifier] Failed to load bundled model at \(url) with \(units): \(error)")
                }
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

        // .cgImage drops the orientation flag, so a portrait photograph would
        // otherwise be classified sideways.
        let orientation = cgOrientation(from: image.imageOrientation)

        DispatchQueue.global(qos: .userInitiated).async {
            if let model = bundledModel {
                runCoreMLModel(model, on: cgImage, orientation: orientation, completion: completion)
            } else {
                runVisionDefault(on: cgImage, orientation: orientation, completion: completion)
            }
        }
    }

    private static func cgOrientation(from ui: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch ui {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }

    // MARK: - Runners

    private static func runCoreMLModel(_ model: VNCoreMLModel,
                                       on cgImage: CGImage,
                                       orientation: CGImagePropertyOrientation,
                                       completion: @escaping (Result<[ClassifiedFood], Error>) -> Void) {
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error {
                // The model loaded but this request could not run (most often a
                // missing inference context). Degrade to Apple's classifier
                // rather than telling the user the photo failed.
                print("[FoodClassifier] bundled request failed, using Vision default: \(error)")
                runVisionDefault(on: cgImage, orientation: orientation, completion: completion)
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
            print("[FoodClassifier] bundled model returned: "
                  + top.prefix(3).map { "\($0.label) \(String(format: "%.2f", $0.confidence))" }
                        .joined(separator: ", "))
            completion(.success(Array(top)))
        }
        // Center-crop matches how most Food-101 models were trained.
        request.imageCropAndScaleOption = .centerCrop
        do {
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:]).perform([request])
        } catch {
            print("[FoodClassifier] perform() threw, using Vision default: \(error)")
            runVisionDefault(on: cgImage, orientation: orientation, completion: completion)
        }
    }

    private static func runVisionDefault(on cgImage: CGImage,
                                         orientation: CGImagePropertyOrientation,
                                         completion: @escaping (Result<[ClassifiedFood], Error>) -> Void) {
        let request = VNClassifyImageRequest()
        do {
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:]).perform([request])
            let all = request.results ?? []

            // Apple ships calibrated precision/recall curves with this classifier, so
            // hasMinimumRecall(_:forPrecision:) filters far better than a raw threshold.
            let strict = all.filter { $0.hasMinimumRecall(0.5, forPrecision: 0.7) }
            let medium = all.filter { $0.hasMinimumRecall(0.5, forPrecision: 0.5) }

            // The tiers set the order, they do not discard. Apple's taxonomy is
            // hierarchical: a pizza yields both "food" and the less precise "pizza",
            // and only the latter matches anything in the macro table.
            var ordered: [VNClassificationObservation] = []
            var seen = Set<String>()
            for tier in [strict, medium, all] {
                for obs in tier.sorted(by: { $0.confidence > $1.confidence })
                where !seen.contains(obs.identifier) {
                    ordered.append(obs)
                    seen.insert(obs.identifier)
                }
            }

            let top = ordered
                .prefix(15)
                .map { ClassifiedFood(label: normalize($0.identifier),
                                      confidence: $0.confidence) }
            print("[FoodClassifier] Vision default: \(all.count) observations, "
                  + "\(strict.count) high precision, \(medium.count) medium. Returning: "
                  + top.map { "\($0.label) \(String(format: "%.2f", $0.confidence))" }
                        .joined(separator: ", "))
            completion(.success(Array(top)))
        } catch {
            print("[FoodClassifier] Vision default ALSO failed: \(error)")
            completion(.failure(error))
        }
    }

    /// Normalizes classifier labels for both display and `FoodDatabase`
    /// alias matching. Apple's built-in classifier uses `snake_case` and a
    /// few hyphens (e.g. `hot-dog`); Food-101 style models use `snake_case`
    /// throughout. We collapse both, lowercase, and trim.
    private static func normalize(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
    }
}
