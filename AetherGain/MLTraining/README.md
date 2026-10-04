# Training FoodClassifier

Ten classes are set up, and every folder name matches a `name` in
`FoodDatabase.swift` exactly: Banana, Biryani, Chapati, Dal, Dosa, Egg, Idli,
Paneer, Pizza, Rice. That match is the whole point — the model emits the folder
name as its label, and `FoodDatabase.bestMatch` resolves that label to macros.
A model that recognises "beignets" is useless if the macro table has never
heard of it.

## Variations

```
Training/Dosa/                 photos that need no distinction
Training/Dosa/plain/           a variation
Training/Dosa/masala/          another variation
```

Every image anywhere below `Training/Dosa/` trains as the single label `Dosa`.
Subfolders are for keeping your own collection tidy and for making the class
cover the real spread of what the dish looks like — a set dosa, a folded dosa,
one on a steel plate, one on a table. More visual variety inside a class makes
the classifier more robust, so this is worth doing.

**When a variation needs its own class instead:** if the macros genuinely
differ, a subfolder is the wrong tool, because everything under `Dosa/` is
logged with Dosa's macros. Masala dosa has a potato filling and is not plain
dosa nutritionally. In that case:

1. Add an entry to `FoodDatabase.all`, next to the existing ones:

   ```swift
   FoodMacros(name: "Masala dosa", calories: 195, protein: 4.0, carbs: 30.0,
              fat: 6.5, defaultServingG: 150,
              aliases: ["masala dosa", "potato dosa"]),
   ```

2. Create `Training/Masala dosa/` as a top-level folder and put the photos
   there.

`check_dataset.py` compares every class folder against `FoodDatabase.swift` and
tells you if a name has no entry.

## 1 · Collect photos

25 to 40 per class, spread over a few days: different plates, different light,
from above and at an angle. Your own phone photos beat pictures from the web —
you can describe the data source in the IA, and they look like the photos the
client will actually take. Screenshots cropped tightly to the dish work fine;
a screenshot of a whole search-results grid does not, because the model would
learn the grid.

Drop them into the matching folder. File names do not matter.

A class you have no photos for should be **deleted** — an empty folder makes
Create ML fail. Eight well-filled classes beat twelve half-empty ones.

## 1b · Folding in an existing image set

`prepare_dataset.py` files an external set of images into `Training/` under the
names this project uses. It downloads nothing — point it at a folder you
already have, either a dataset you obtained yourself under its own licence or a
folder of your own photos.

Source layout: one subfolder per class, named however the source names them.

```bash
pip3 install Pillow                       # once
python3 prepare_dataset.py ~/Downloads/indian-food --make-map
#   writes mapping.json:  {"masala_dosa": "Dosa", "unknown_thing": ""}
#   edit it — a FoodDatabase name on the right, blank to skip that class
python3 prepare_dataset.py ~/Downloads/indian-food --map mapping.json --dry-run
python3 prepare_dataset.py ~/Downloads/indian-food --map mapping.json
```

Per image it verifies the file, drops anything under 200 px on the short side,
drops near-duplicates with a difference hash (within the source and against
what is already in `Training/`), converts to RGB JPEG and resizes the longest
side to 512. It refuses to run if a target name has no entry in
`FoodDatabase.swift`, and it never overwrites a file that is already there, so
your own photos are safe. `--cap` limits how many it adds per class; the
default 200 keeps the set roughly balanced.

Running it twice adds nothing the second time.

**Licensing matters here.** Use a dataset whose licence permits what you are
doing and say in the IA where the images came from. Scraping image search
results is not a licence.

## 2 · Check

```bash
cd MLTraining
python3 check_dataset.py
```

Counts images per class and per variation, flags empty classes, thin classes,
class imbalance, and folder names that do not exist in `FoodDatabase.swift`.

## 3 · Train

```bash
swift train_model.swift
```

A few minutes on Apple silicon. It flattens the variation subfolders into a
temporary staging directory, trains, prints training and validation accuracy,
and writes `AetherGainFoodModel.mlmodel` one level up, next to `MLTraining/`.

**Do not bundle a model below 70 % validation accuracy.** A confidently wrong
model is worse than the Vision fallback, which at least degrades gracefully.
Add photos or drop the weakest classes instead.

## 4 · Bundle it

Nothing to do. This project uses an Xcode synchronized group, so every file in
`AetherGain/` is part of the app target automatically, and `train_model.swift`
writes the model straight into that folder. Just rebuild. On the first meal
photo the Xcode console must print:

```
[FoodClassifier] Bundled model loaded from AetherGainFoodModel.mlmodelc
```

If it prints "No bundled FoodClassifier model" instead, the file is not where
the code looks — it must be `AetherGain/AetherGainFoodModel.mlmodel`, spelled exactly
that way, because `loadBundledModel()` searches for that name.

That synchronized group is also why `MLTraining/` lives **next to** the
`.xcodeproj` and not inside `AetherGain/`. Left inside, Xcode would try to
compile `train_model.swift` into the iOS app, and `import CreateML` does not
exist on iOS, so the build would fail. The 133 training photos would also be
copied into the app bundle. Keep this folder out of `AetherGain/`.

## 5 · For the IA

This is a design decision with a justification, so it belongs in criteria D
and E: a ready-made Food-101 model knows 101 mostly American restaurant dishes,
almost none of which appear in this app's macro table, so it would recognise
food the app cannot price. Instead the classifier was trained on exactly the
dishes the client logs. The trade-off is that it knows only those classes, and
everything else falls through to the Vision fallback — which is why that
fallback stays in the code.
