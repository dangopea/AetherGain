#!/usr/bin/env python3
"""
Checks the training set before train_model.swift runs.

Layout
------
Training/<FoodName>/                 the class label
Training/<FoodName>/<variation>/     optional, counted towards the same label

Every image below Training/<FoodName>/ trains as the single label <FoodName>.
The class name must match a `name` in FoodDatabase.swift exactly, otherwise the
model emits a label that bestMatch() cannot resolve to any macros.
"""

import os
import re
import sys

EXTENSIONS = {".jpg", ".jpeg", ".png", ".heic"}
MIN_PER_CLASS = 25          # below this Create ML's validation split gets noisy
MIN_PER_VARIATION = 5
IMBALANCE_FACTOR = 3        # largest class vs smallest

HERE = os.path.dirname(os.path.abspath(__file__))
TRAINING = os.path.join(HERE, "Training")
FOOD_DB = os.path.join(HERE, os.pardir, "AetherGain", "Services", "FoodDatabase.swift")


def database_names():
    """Names defined in FoodDatabase.swift, or None if the file is missing."""
    try:
        with open(FOOD_DB, encoding="utf-8") as handle:
            source = handle.read()
    except OSError:
        return None
    return {m.lower() for m in re.findall(r'FoodMacros\(name:\s*"([^"]+)"', source)}


def count_images(directory):
    """(total, {variation: count}) for everything below `directory`."""
    per_variation = {}
    total = 0
    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        images = [f for f in files
                  if os.path.splitext(f)[1].lower() in EXTENSIONS
                  and not f.startswith(".")]
        if not images:
            continue
        relative = os.path.relpath(root, directory)
        label = "(top level)" if relative == "." else relative
        per_variation[label] = len(images)
        total += len(images)
    return total, per_variation


def main():
    if not os.path.isdir(TRAINING):
        sys.exit("Training/ is missing.")

    known = database_names()
    classes = sorted(d for d in os.listdir(TRAINING)
                     if os.path.isdir(os.path.join(TRAINING, d)) and not d.startswith("."))
    if not classes:
        sys.exit("No class folders under Training/.")

    problems, notes, counts = [], [], {}
    width = max(len(c) for c in classes)

    for name in classes:
        total, variations = count_images(os.path.join(TRAINING, name))
        counts[name] = total

        print(f"{name.ljust(width)}  {total:>4} images")
        if len(variations) > 1 or "(top level)" not in variations:
            for variation, n in sorted(variations.items()):
                print(f"{' ' * width}    {variation}: {n}")
                if n < MIN_PER_VARIATION:
                    notes.append(f"{name}/{variation}: only {n} images — "
                                 f"too few to teach the variation anything")

        if total == 0:
            problems.append(f"{name}: empty — Create ML fails on an empty class, "
                            f"delete the folder or fill it")
        elif total < MIN_PER_CLASS:
            notes.append(f"{name}: {total} images, {MIN_PER_CLASS} recommended")

        if known is not None and name.lower() not in known:
            problems.append(f"{name}: no entry with this name in FoodDatabase.swift — "
                            f"the model would emit a label nothing can resolve")

    print("-" * (width + 14))
    print(f"{'total'.ljust(width)}  {sum(counts.values()):>4} images in {len(classes)} classes")

    populated = {k: v for k, v in counts.items() if v}
    if len(populated) >= 2:
        smallest, largest = min(populated.values()), max(populated.values())
        if largest > smallest * IMBALANCE_FACTOR:
            weakest = min(populated, key=populated.get)
            notes.append(f"imbalance: largest class has {largest} images, "
                         f"{weakest} has {smallest} — the model will favour the big ones")
    if len(populated) < 2:
        problems.append("fewer than two classes have images — nothing to train")

    if problems:
        print("\nFix first:")
        for p in problems:
            print("  -", p)
    if notes:
        print("\nWorth improving:")
        for n in notes:
            print("  -", n)

    if problems:
        sys.exit(1)
    print("\nGood to go:  swift train_model.swift")


if __name__ == "__main__":
    main()
