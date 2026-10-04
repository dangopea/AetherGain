//
//  FoodClassifierRegions.swift
//  AetherGain
//
//  Multi-region classification: name several foods in one photo without an
//  object-detection model.
//
//  The bundled classifier answers one question — "which single dish is this?"
//  A thali has rice in one bowl, dal in another and a chapati beside them, so
//  a single answer is wrong by construction. Proper object detection would fix
//  that, but it needs a bounding box drawn by hand around every ingredient in
//  every training image; at roughly four ingredients across five hundred
//  photos that is two thousand boxes before the first training run.
//
//  This is the cheaper approximation. Vision's saliency request returns the
//  prominent regions of an image with no training at all. Crop to each region,
//  run the existing classifier on the crop, and keep the best label per
//  region. Separate bowls on a plate come back as separate foods.
//
//  It cannot split a mixed bowl, where the foods are not spatially separate —
//  that case is what the ingredient text parser in MealViewModel is for.
//

import Foundation
import CoreGraphics
import UIKit
import Vision

struct RegionCandidate: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    /// Normalised, origin at top-left, so it can be drawn straight onto a
    /// SwiftUI image without flipping.
    let boundingBox: CGRect
    var matchedFood: String?
}

extension FoodClassifier {

    /// Minimum confidence a region's top label needs before it is offered.
    /// Below this the region is more likely to be a plate edge or a hand.
    static let regionConfidenceFloor: Float = 0.25

    /// Classifies up to `maxRegions` salient regions and returns one candidate
    /// per distinct food, best confidence first. Falls back to classifying the
    /// whole image when saliency finds nothing.
    static func classifyRegions(image: UIImage,
                                maxRegions: Int = 4,
                                completion: @escaping (Result<[RegionCandidate], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(FoodClassifierError.invalidImage))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let regions = salientRegions(in: cgImage, limit: maxRegions)

            guard !regions.isEmpty else {
                // No distinct regions: treat the photo as a single dish.
                classify(image: image) { result in
                    completion(result.map { classified in
                        classified.prefix(1).map {
                            RegionCandidate(label: $0.label,
                                            confidence: $0.confidence,
                                            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1),
                                            matchedFood: FoodDatabase.bestMatch(
                                                fromLabels: [($0.label, $0.confidence)])?.name)
                        }
                    })
                }
                return
            }

            var found: [RegionCandidate] = []
            let lock = NSLock()
            let group = DispatchGroup()

            for box in regions {
                guard let crop = cgImage.cropping(to: pixelRect(for: box, in: cgImage)) else { continue }
                group.enter()
                classify(image: UIImage(cgImage: crop)) { result in
                    defer { group.leave() }
                    guard case .success(let classified) = result,
                          let best = classified.first,
                          best.confidence >= regionConfidenceFloor else { return }

                    let matched = FoodDatabase.bestMatch(
                        fromLabels: [(best.label, best.confidence)])?.name
                    let candidate = RegionCandidate(label: best.label,
                                                    confidence: best.confidence,
                                                    boundingBox: topLeftRect(for: box),
                                                    matchedFood: matched)
                    lock.lock()
                    found.append(candidate)
                    lock.unlock()
                }
            }

            group.notify(queue: .global(qos: .userInitiated)) {
                // One entry per food. Two bowls of the same dal are one food,
                // and the higher-confidence region wins.
                var bestByFood: [String: RegionCandidate] = [:]
                for candidate in found {
                    let key = candidate.matchedFood ?? candidate.label
                    if let existing = bestByFood[key], existing.confidence >= candidate.confidence {
                        continue
                    }
                    bestByFood[key] = candidate
                }
                completion(.success(bestByFood.values.sorted { $0.confidence > $1.confidence }))
            }
        }
    }

    // MARK: - Saliency

    /// Prominent regions, Vision coordinates (normalised, origin bottom-left).
    private static func salientRegions(in cgImage: CGImage, limit: Int) -> [CGRect] {
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        } catch {
            return []
        }
        guard let observation = request.results?.first as? VNSaliencyImageObservation,
              let objects = observation.salientObjects else { return [] }

        return objects
            // A region under 4 % of the frame is too small to be a portion,
            // so discard those before taking the best ones.
            .filter { $0.boundingBox.width * $0.boundingBox.height >= 0.04 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { $0.boundingBox }
    }

    // MARK: - Geometry

    /// Vision box -> pixel rect for cropping, with 8 % padding so the crop
    /// keeps a little context, clamped to the image.
    private static func pixelRect(for box: CGRect, in cgImage: CGImage) -> CGRect {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let padX = box.width * 0.08
        let padY = box.height * 0.08

        let x = (box.origin.x - padX) * width
        // Vision's origin is bottom-left, CGImage's is top-left.
        let y = (1 - box.origin.y - box.height - padY) * height
        let w = (box.width + padX * 2) * width
        let h = (box.height + padY * 2) * height

        return CGRect(x: max(0, x),
                      y: max(0, y),
                      width: min(w, width - max(0, x)),
                      height: min(h, height - max(0, y)))
    }

    /// Vision box -> normalised rect with the origin at the top-left.
    private static func topLeftRect(for box: CGRect) -> CGRect {
        CGRect(x: box.origin.x,
               y: 1 - box.origin.y - box.height,
               width: box.width,
               height: box.height)
    }
}
