






















import Foundation
import CoreGraphics
import UIKit
import Vision

struct RegionCandidate: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float


    let boundingBox: CGRect
    var matchedFood: String?
}

extension FoodClassifier {



    static let regionConfidenceFloor: Float = 0.25




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


            .filter { $0.boundingBox.width * $0.boundingBox.height >= 0.04 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { $0.boundingBox }
    }





    private static func pixelRect(for box: CGRect, in cgImage: CGImage) -> CGRect {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let padX = box.width * 0.08
        let padY = box.height * 0.08

        let x = (box.origin.x - padX) * width

        let y = (1 - box.origin.y - box.height - padY) * height
        let w = (box.width + padX * 2) * width
        let h = (box.height + padY * 2) * height

        return CGRect(x: max(0, x),
                      y: max(0, y),
                      width: min(w, width - max(0, x)),
                      height: min(h, height - max(0, y)))
    }


    private static func topLeftRect(for box: CGRect) -> CGRect {
        CGRect(x: box.origin.x,
               y: 1 - box.origin.y - box.height,
               width: box.width,
               height: box.height)
    }
}
