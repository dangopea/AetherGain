#!/usr/bin/env python3
"""
prepare_dataset.py — fold an external image set into MLTraining/Training.

It does NOT download anything. Point it at a folder you already have: a
dataset you downloaded yourself under its own licence, or a folder of your
own photos. It cleans that folder up and files the images under the class
names this project uses.

    python3 prepare_dataset.py ~/Downloads/indian-food --make-map
    # edit mapping.json, then
    python3 prepare_dataset.py ~/Downloads/indian-food --map mapping.json

Expected source layout — one subfolder per class, any names:

    indian-food/
      masala_dosa/  *.jpg
      plain_rice/   *.jpg
      ...

What it does per image
    - opens and verifies it (corrupt files are skipped, not copied)
    - drops anything smaller than --min-size on the short side
    - drops near-duplicates using a difference hash, within and across classes
    - converts to RGB JPEG, longest side --max-size
    - writes to Training/<FoodDatabase name>/<class>_ext_NNN.jpg

It never overwrites a file that is already there, so your own photos are safe.

Class names in `mapping.json` must match a `name` in FoodDatabase.swift, since
that is what bestMatch() compares the model's label against.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import defaultdict

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is missing.  pip3 install Pillow")

EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".heic"}
HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.join(HERE, "Training")
FOOD_DB = os.path.join(HERE, os.pardir, "AetherGain", "Services", "FoodDatabase.swift")


# ---------------------------------------------------------------- FoodDatabase

def database_names() -> list[str]:
    """The `name` of every FoodMacros entry, in file order."""
    try:
        with open(FOOD_DB, encoding="utf-8") as handle:
            source = handle.read()
    except OSError:
        return []
    return re.findall(r'FoodMacros\(name:\s*"([^"]+)"', source)


def normalise(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def guess_mapping(source_classes: list[str], known: list[str]) -> dict[str, str]:
    """Best-effort source folder -> FoodDatabase name, for --make-map.

    Only offers a guess when the normalised names share a whole word, so a
    wrong guess is obvious rather than plausible. Everything else is left
    empty for you to fill in or delete.
    """
    by_word: dict[str, str] = {}
    for name in known:
        for word in normalise(name).split():
            by_word.setdefault(word, name)

    mapping: dict[str, str] = {}
    for folder in source_classes:
        words = normalise(folder).split()
        hit = ""
        for word in words:
            if word in by_word:
                hit = by_word[word]
                break
        mapping[folder] = hit
    return mapping


# ---------------------------------------------------------------- image tools

def dhash(image: Image.Image, size: int = 8) -> int:
    """Difference hash: resize to (size+1, size), compare adjacent pixels.

    Two images that differ only in compression, small crops or resizing land
    on the same hash, which is what we want for de-duplicating a scraped set.
    """
    grey = image.convert("L").resize((size + 1, size), Image.LANCZOS)
    pixels = grey.tobytes()
    bits = 0
    for row in range(size):
        offset = row * (size + 1)
        for col in range(size):
            bits = (bits << 1) | int(pixels[offset + col] > pixels[offset + col + 1])
    return bits


def hamming(a: int, b: int) -> int:
    return bin(a ^ b).count("1")


# ---------------------------------------------------------------- main passes

def collect(source_root: str) -> dict[str, list[str]]:
    """{source class folder: [image paths]} for immediate subfolders."""
    found: dict[str, list[str]] = {}
    for entry in sorted(os.listdir(source_root)):
        folder = os.path.join(source_root, entry)
        if not os.path.isdir(folder) or entry.startswith("."):
            continue
        images = []
        for root, dirs, files in os.walk(folder):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for name in sorted(files):
                if os.path.splitext(name)[1].lower() in EXTENSIONS and not name.startswith("."):
                    images.append(os.path.join(root, name))
        if images:
            found[entry] = images
    return found


def existing_hashes(out_root: str, max_side: int) -> tuple[set[int], list[int]]:
    """Hashes of what is already in Training/, so we never re-add a photo."""
    seen: list[int] = []
    for root, dirs, files in os.walk(out_root):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for name in files:
            if os.path.splitext(name)[1].lower() not in EXTENSIONS:
                continue
            try:
                with Image.open(os.path.join(root, name)) as image:
                    seen.append(dhash(image))
            except Exception:
                continue
    return set(seen), seen


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", help="folder with one subfolder per class")
    parser.add_argument("--map", dest="mapping", default=None,
                        help="JSON of {source folder: FoodDatabase name}")
    parser.add_argument("--make-map", action="store_true",
                        help="write a starter mapping.json and stop")
    parser.add_argument("--out", default=DEFAULT_OUT, help="Training/ directory")
    parser.add_argument("--cap", type=int, default=200,
                        help="maximum images to add per class (default 200)")
    parser.add_argument("--min-size", type=int, default=200,
                        help="skip images whose short side is under this (default 200)")
    parser.add_argument("--max-size", type=int, default=512,
                        help="longest side after resizing (default 512)")
    parser.add_argument("--hash-distance", type=int, default=4,
                        help="0 = byte-identical only, higher = more aggressive (default 4)")
    parser.add_argument("--dry-run", action="store_true", help="report, write nothing")
    args = parser.parse_args()

    if not os.path.isdir(args.source):
        sys.exit(f"{args.source} is not a folder.")

    sources = collect(args.source)
    if not sources:
        sys.exit("No class subfolders with images under that path.")

    known = database_names()

    if args.make_map:
        mapping = guess_mapping(list(sources), known)
        path = os.path.join(HERE, "mapping.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(mapping, handle, indent=2, ensure_ascii=False, sort_keys=True)
        filled = sum(1 for v in mapping.values() if v)
        print(f"Wrote {path}")
        print(f"{len(mapping)} source classes, {filled} guessed, "
              f"{len(mapping) - filled} left blank.")
        print("Edit it: put a FoodDatabase name on the right, or leave it blank to skip")
        print("that class. Names must match FoodDatabase.swift exactly.")
        if known:
            print(f"\nAvailable names ({len(known)}):")
            print("  " + ", ".join(known))
        return

    if not args.mapping:
        sys.exit("Need --map mapping.json (run --make-map first).")
    with open(args.mapping, encoding="utf-8") as handle:
        mapping = json.load(handle)

    unknown = sorted({v for v in mapping.values() if v and known and v not in known})
    if unknown:
        print("These targets have no entry in FoodDatabase.swift:")
        for name in unknown:
            print("  -", name)
        print("Add them to FoodDatabase.all or fix the spelling, then run again.\n")
        sys.exit(1)

    seen_hashes, hash_list = ([], []) if args.dry_run else existing_hashes(args.out, args.max_size)
    hash_list = list(hash_list)

    kept = defaultdict(int)
    skipped = defaultdict(lambda: defaultdict(int))

    for source_class, images in sources.items():
        target = mapping.get(source_class, "")
        if not target:
            skipped[source_class]["unmapped"] = len(images)
            continue

        destination = os.path.join(args.out, target)
        if not args.dry_run:
            os.makedirs(destination, exist_ok=True)

        index = 0
        for path in images:
            if kept[target] >= args.cap:
                skipped[source_class]["over cap"] += 1
                continue
            try:
                with Image.open(path) as image:
                    image.load()
                    if min(image.size) < args.min_size:
                        skipped[source_class]["too small"] += 1
                        continue
                    digest = dhash(image)
                    if any(hamming(digest, other) <= args.hash_distance for other in hash_list):
                        skipped[source_class]["duplicate"] += 1
                        continue

                    image = image.convert("RGB")
                    longest = max(image.size)
                    if longest > args.max_size:
                        scale = args.max_size / longest
                        image = image.resize((max(1, round(image.width * scale)),
                                              max(1, round(image.height * scale))),
                                             Image.LANCZOS)

                    if not args.dry_run:
                        while True:
                            index += 1
                            name = f"{target.lower().replace(' ', '_')}_ext_{index:03d}.jpg"
                            candidate = os.path.join(destination, name)
                            if not os.path.exists(candidate):
                                break
                        image.save(candidate, "JPEG", quality=90)

                    hash_list.append(digest)
                    kept[target] += 1
            except Exception as error:
                skipped[source_class][f"unreadable ({type(error).__name__})"] += 1

    print("Added" + (" (dry run, nothing written)" if args.dry_run else ""))
    width = max((len(k) for k in kept), default=10)
    for name in sorted(kept):
        print(f"  {name.ljust(width)}  {kept[name]:>4}")
    print(f"  {'total'.ljust(width)}  {sum(kept.values()):>4}")

    if skipped:
        print("\nSkipped")
        for source_class in sorted(skipped):
            reasons = ", ".join(f"{n} {why}" for why, n in sorted(skipped[source_class].items()))
            print(f"  {source_class}: {reasons}")

    if known:
        covered = {v for v in mapping.values() if v}
        print(f"\nCoverage: {len(covered)} of {len(known)} FoodDatabase entries have a class.")

    print("\nNext:  python3 check_dataset.py   then   swift train_model.swift")


if __name__ == "__main__":
    main()
