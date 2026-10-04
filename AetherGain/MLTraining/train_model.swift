#!/usr/bin/env swift
//
//  train_model.swift
//  AetherGain
//
//  Trains an image classifier from MLTraining/Training and writes
//  FoodClassifier.mlmodel next to the MLTraining folder.
//
//  Run from inside MLTraining:
//      swift train_model.swift
//
//  Folder layout
//  -------------
//  Training/<FoodName>/                      <- the class label
//  Training/<FoodName>/<variation>/          <- optional, any depth
//
//  Every image found anywhere below Training/<FoodName>/ trains as the single
//  label <FoodName>. Variation subfolders exist so you can keep "plain" and
//  "masala" dosa apart while you are collecting, without splitting the class.
//  The script copies everything into a flat staging directory before training,
//  because Create ML's labeledDirectories reads one level only.
//
//  IMPORTANT: <FoodName> must match a `name` in FoodDatabase.swift exactly.
//  The model emits the folder name as its label, and FoodDatabase.bestMatch
//  compares that label against those names.
//
//  If a variation has materially different macros (masala dosa is not plain
//  dosa), it needs its own FoodDatabase entry and its own top-level folder.
//  Keep it as a subfolder only when the macros are the same.
//

import CreateML
import Foundation

let fm = FileManager.default
let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic"]

let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let trainingDir = cwd.appendingPathComponent("Training")
let outputURL = cwd.deletingLastPathComponent()
    .appendingPathComponent("AetherGain")
    .appendingPathComponent("AetherGainFoodModel.mlmodel")

guard fm.fileExists(atPath: trainingDir.path) else {
    print("ERROR: Training/ not found. Run this script from inside MLTraining.")
    exit(1)
}

// MARK: - Flatten variation subfolders into one directory per class

let stagingDir = fm.temporaryDirectory
    .appendingPathComponent("AetherGainDataset-\(UUID().uuidString)")

func imageURLs(under directory: URL) -> [URL] {
    guard let walker = fm.enumerator(at: directory,
                                     includingPropertiesForKeys: [.isRegularFileKey],
                                     options: [.skipsHiddenFiles]) else { return [] }
    return walker.compactMap { $0 as? URL }
        .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
}

var classCounts: [String: Int] = [:]

do {
    try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)

    let classDirs = try fm.contentsOfDirectory(at: trainingDir,
                                               includingPropertiesForKeys: [.isDirectoryKey],
                                               options: [.skipsHiddenFiles])
        .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    for classDir in classDirs {
        let label = classDir.lastPathComponent
        let images = imageURLs(under: classDir)
        guard !images.isEmpty else {
            print("SKIPPED \(label): no images — an empty folder makes Create ML fail.")
            continue
        }

        let destination = stagingDir.appendingPathComponent(label)
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)

        for (index, image) in images.enumerated() {
            // Keep the variation in the file name so a misfiled photo is easy
            // to trace back after training.
            let variation = image.deletingLastPathComponent().lastPathComponent
            let suffix = (variation == label) ? "" : "_\(variation)"
            let name = "\(label)\(suffix)_\(String(format: "%03d", index + 1)).\(image.pathExtension)"
            try fm.copyItem(at: image, to: destination.appendingPathComponent(name))
        }
        classCounts[label] = images.count
    }
} catch {
    print("ERROR while preparing the dataset: \(error)")
    exit(1)
}

guard classCounts.count >= 2 else {
    print("ERROR: need at least two classes with images, found \(classCounts.count).")
    try? fm.removeItem(at: stagingDir)
    exit(1)
}

print("Dataset")
for (label, count) in classCounts.sorted(by: { $0.key < $1.key }) {
    print("  \(label.padding(toLength: 14, withPad: " ", startingAt: 0)) \(count) images")
}
print("  total: \(classCounts.values.reduce(0, +)) images in \(classCounts.count) classes")
print("")
print("Output: \(outputURL.path)")
print("Training, this takes a few minutes...")
print("")

// MARK: - Train

do {
    let data = MLImageClassifier.DataSource.labeledDirectories(at: stagingDir)
    let classifier = try MLImageClassifier(trainingData: data)

    let trainingAccuracy = (1.0 - classifier.trainingMetrics.classificationError) * 100
    let validationAccuracy = (1.0 - classifier.validationMetrics.classificationError) * 100
    print(String(format: "Training accuracy:   %.1f %%", trainingAccuracy))
    if validationAccuracy.isNaN {
        // With very few images per class the automatic split can leave the
        // validation set empty, and Create ML reports NaN. Train on more
        // photos before trusting the model.
        print("Validation accuracy: not measured — too few images for a split.")
    } else {
        print(String(format: "Validation accuracy: %.1f %%", validationAccuracy))
    }

    let metadata = MLModelMetadata(
        author: "Dhriti",
        shortDescription: "AetherGain food classifier trained on the client's own meals.",
        version: "1.0"
    )
    if fm.fileExists(atPath: outputURL.path) {
        try fm.removeItem(at: outputURL)
    }
    try classifier.write(to: outputURL, metadata: metadata)

    print("")
    print("Done. AetherGainFoodModel.mlmodel is in the AetherGain/ source folder.")
    print("That folder is a synchronized group, so Xcode picks the model up on")
    print("the next build — nothing to drag, nothing to tick.")

    if validationAccuracy.isNaN || validationAccuracy < 70 {
        print("")
        print("WARNING: below 70 % validation accuracy this model is not worth bundling.")
        print("A confidently wrong model is worse than the Vision fallback.")
        print("Add more photos per class, or drop the classes with the fewest.")
    }
} catch {
    print("ERROR during training: \(error)")
    try? fm.removeItem(at: stagingDir)
    exit(1)
}

try? fm.removeItem(at: stagingDir)
