# Work Spots — iPhone app

**Work Spots** is an Untappd-style rating app for work-from-home /
work-from-anywhere spots: cafés, libraries and anywhere else with a table,
Wi-Fi and decent coffee. Discover spots, check in when you work from one,
rate it (half stars count), score it on the things that matter for working —
coffee, Wi-Fi, outlets, noise, seating, parking — and watch a community
rating build up from everyone's check-ins.

Native SwiftUI, **iPhone only**, iOS 17+, no third-party dependencies.

> **Status: structurally validated only — not yet compiled.**
> The project was assembled on a machine without Xcode. It has been
> structurally validated (see [VALIDATION.md](VALIDATION.md)); the first real
> compile is the GitHub Actions build (`.github/workflows/ios-build.yml`),
> which runs `xcodebuild` unsigned on a macOS runner. Treat the delivery as
> verified only once that workflow (or a local Xcode build) is green.

## What's in the app

Four tabs:

- **Discover** — the catalog of spots, searchable and filterable by town, by
  type (café / library / other) and by tag (light food, boutique, stretch).
  Each row shows the listed rating, the community rating once check-ins
  exist, price level and tags.
- **Top Rated** — spots ranked by community rating (average of all
  check-ins, ties broken by check-in count), plus the not-yet-rated spots.
- **Activity** — every check-in, newest first: who, where, the rating, when,
  and what they said.
- **Profile** — your display name (stamps your check-ins and added spots)
  and your stats: check-ins, spots tried, average rating given, would-return
  count.

From a spot's detail screen you get its hours, address, notes, a Google Maps
search link, the community scorecard breakdown, all its check-ins, and a big
**Check In** button. The check-in sheet takes a 0.5–5 half-star rating, the
six-part scorecard, what you had, a review, a would-return toggle, and a
date (defaults to now, editable). **Add a Spot** (the + on Discover) puts a
new spot anywhere into the catalog, unrated, stamped with your name.

## Open and build it

1. You need **Xcode 16 or later** on a Mac.
2. Open `WorkSpots/WorkSpots.xcodeproj`.
3. Select the **WorkSpots** target → *Signing & Capabilities* and pick your
   own team. Change the bundle identifier if you like — the project ships
   with the placeholder `com.workspots.app`.
4. Pick an iPhone (simulator or your device) and Run.

There is nothing else to install: no CocoaPods, no Swift packages, no
backend. The project uses an Xcode 16 file-system-synchronized group, so the
Swift files in `WorkSpots/WorkSpots/` are picked up automatically — adding a
file to that folder adds it to the build.

## Architecture

**Local-first.** All data lives on the device as one Codable JSON document
(`StoredData`: places, check-ins, profile) in Application Support, seeded on
first launch from `SeedData.swift`.

The seam for the future is deliberate:

- `WorkSpotsRepository` (in `Store.swift`) is the only persistence
  interface. `LocalJSONRepository` is today's implementation.
- `WorkSpotsStore` is an `ObservableObject` that owns the catalog,
  check-ins and profile, computes community ratings / scorecard averages /
  rankings / personal stats, and persists through the repository on every
  change.
- The SwiftUI views only talk to the store.

**Next phase — multi-user accounts and a backend:** implement a second
`WorkSpotsRepository` (or a sync service beside it) that talks to the server,
add sign-in, and let check-ins from all users feed the community ratings.
Check-ins already carry an `author` display name and spots an `addedBy`, so
the data model does not need to change shape — only where it is stored.

## The seed catalog

First launch seeds **26 spots** around Burlington and Chelmsford,
Massachusetts (plus two stretch picks in Lowell) — cafés and libraries
researched and rated for working from. The one Burlington café the list's
owner removed during review is deliberately excluded and does not appear
anywhere in this project. Listed ratings and hours are copied from the
research; where hours were never published they are left empty and the app
says "check before you go" rather than inventing them.

## Continuous integration

`.github/workflows/ios-build.yml` runs on every push and pull request on a
macOS runner:

```sh
xcodebuild build \
  -project WorkSpots/WorkSpots.xcodeproj \
  -scheme WorkSpots \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO
```

No certificates or secrets are needed for the unsigned build.
