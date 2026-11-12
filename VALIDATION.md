# Validation

**Compile status: structurally validated only — not compiled.**

This project was assembled on a Linux machine with **no Xcode and no Swift
toolchain** (`swiftc` and `xcodebuild` are both absent), so nothing here has
been compiled, run, or tested by a compiler. The first real compile is the
GitHub Actions workflow in `.github/workflows/ios-build.yml` (macOS runner,
unsigned `xcodebuild`), or a local build in Xcode 16+.

What follows is the structural validation that *was* possible, run with a
Python checker against the exact tree in the initial commit.
Date of run: 2026-11-12.

## Results — 39/39 checks passed

### `project.pbxproj` (Xcode 16 format, objectVersion 77)

- Braces balanced, raw and with quoted strings stripped (25/25); parentheses
  balanced (13/13); brackets balanced (0/0).
- No merge-conflict markers.
- **Every object defined exactly once** — 15 objects, zero duplicate
  definitions. (Checked explicitly: a duplicate definition can survive a
  brace/dangling-reference check and still make strict parsers reject the
  file.)
- **Every referenced object ID is defined** — 15 distinct 24-hex IDs
  referenced, zero dangling.
- `rootObject` resolves to the `PBXProject`.
- Exactly one `PBXNativeTarget`; exactly one
  `PBXFileSystemSynchronizedRootGroup`, listed in the target's
  `fileSystemSynchronizedGroups`, and its path (`WorkSpots`) exists on disk.
- `TARGETED_DEVICE_FAMILY = 1` (iPhone only) in both target configurations;
  iOS deployment target 17.0 at project and target level; bundle id
  `com.workspots.app` in both target configurations;
  `GENERATE_INFOPLIST_FILE = YES` in both; product type is application.
- No Swift package references — zero third-party dependencies.
- The shared scheme `WorkSpots` exists under `xcshareddata/xcschemes`, its
  `BlueprintIdentifier` is the target's object ID, and it references
  `container:WorkSpots.xcodeproj`.

### Swift sources

- All 13 expected files exist inside the synchronized folder
  (`WorkSpotsApp`, `Models`, `SeedData`, `Store`, `ContentView`,
  `DiscoverView`, `PlaceDetailView`, `CheckInView`, `ActivityView`,
  `TopRatedView`, `ProfileView`, `AddPlaceView`, `RatingControls`), and
  there are no stray or missing `.swift` files.
- Braces and parentheses balanced in every file.
- `@main` entry point constructs the store and injects it as an
  environment object.
- `WorkSpotsRepository` protocol exists with `LocalJSONRepository` as its
  implementation; the store is an `ObservableObject`.
- All three asset-catalog `Contents.json` files parse as valid JSON.
- A manual conservative-API review was done while writing: `ObservableObject`
  + `@Published` instead of the `@Observable` macro, JSON persistence instead
  of SwiftData, no exotic or post-iOS-17 APIs, and three initially-drafted
  constructs were replaced with plainer equivalents before delivery
  (closure-form `LabeledContent`, enumerated `ForEach`, and axis-growing
  text fields).

### Seed catalog

- Exactly **26** places, numbered 1–26 in order, names unique.
- Spot checks confirm the catalog spans the full researched list, from
  True North Coffee through Peak Coffee and Tea, including Chelmsford
  Public Library and Commune All Day Cafe.
- Exactly 2 places carry the `stretch` tag (the Lowell pair).
- **The café the list's owner removed during review appears nowhere in this
  project** — its name string was searched across every file in the tree
  and returned zero hits.

### CI

- `.github/workflows/ios-build.yml` runs on `macos-15`, checks out the repo,
  and runs the unsigned build for scheme `WorkSpots` against
  `WorkSpots/WorkSpots.xcodeproj` with `CODE_SIGNING_ALLOWED=NO`.

## Known first-build risks (in order)

1. **Hand-written pbxproj details.** The file follows the Xcode 16
   synchronized-group format and passes the structural checks above, but no
   Xcode has parsed it yet. If the first CI run fails, the project file is
   the first suspect — open it in Xcode on a Mac and let Xcode repair /
   re-save it, then commit the result.
2. **Uncompiled Swift.** Conservative, dependency-free SwiftUI, but a typo
   or a subtle API mismatch can only be found by the compiler. The CI build
   is the arbiter.
3. **Empty app icon set.** `AppIcon.appiconset` declares the standard slots
   with no image files (a placeholder). Xcode warns; add real icon PNGs
   before any App Store submission.
4. **Signing is intentionally unconfigured** (empty team, automatic
   signing, placeholder bundle id `com.workspots.app`). Building unsigned
   in CI works; running on a personal device needs the owner's team and
   bundle id set in Xcode.
