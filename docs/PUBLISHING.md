# Publishing Work Spots — App Store checklist

Owner steps are Parthey's (Apple requires the account holder); everything else is Alfred's.
Status (2026-11-13): Apple Developer account ENABLED. Release pipeline BUILT —
`.github/workflows/release.yml` (merge to main → signed archive → TestFlight;
runs as an unsigned dry run until the secrets below exist), app icon generated,
privacy policy at `docs/PRIVACY.md`, versioning rules at `docs/VERSIONING.md`.
Remaining gates are steps 2–4 below, all Parthey's.

## 1. Apple Developer Program (Parthey)
- Enroll as Individual via the Apple Developer app (identity verification + $99/yr).
- Done when the confirmation email arrives and developer.apple.com/account shows membership.

## 2. App record in App Store Connect (Parthey, ~2 minutes — Apple only allows the account holder)
App Store Connect → Apps → "+" → New App, with exactly:
- Platform: iOS
- Name: **Work Spots** (if taken, Alfred will suggest a variant before submission)
- Primary language: English (U.S.)
- Bundle ID: **com.parthey.workspots** (set in the Xcode project 2026-11-12). If it is not in the
  dropdown yet, register it first at developer.apple.com → Certificates, Identifiers & Profiles →
  Identifiers → "+" → App IDs → App → description "Work Spots", Bundle ID (Explicit): com.parthey.workspots,
  no capabilities needed → Register. Then it appears in the dropdown.
- SKU: `workspots-ios-001`
- User Access: Full Access

## 3. App Store Connect API key (Parthey creates, Alfred uses)
- App Store Connect → Users and Access → Integrations (API Keys) → Generate API Key
  - Name: `Alfred CI`
  - Access: **App Manager** (Admin also works and enables fully automatic signing)
- Note the **Key ID** and **Issuer ID** shown on that page.
- Download the `.p8` file (downloadable ONCE) and hand it to Alfred via Secure Vault — never chat, never email.

## 4. GitHub repo secrets (Parthey adds — deploy key cannot)
Repo → Settings → Secrets and variables → Actions → New repository secret:
- `ASC_KEY_ID` — from step 3
- `ASC_ISSUER_ID` — from step 3
- `ASC_KEY_P8` — full contents of the .p8 file
- `ASC_TEAM_ID` — developer.apple.com → Account → Membership details → Team ID

## 5. Release pipeline (Alfred) — BUILT 2026-11-13
- ✅ Real bundle ID in the project; app icon generated (1024px, pin + coffee cup);
  privacy policy page at `docs/PRIVACY.md`.
- ✅ Release workflow `.github/workflows/release.yml`: on merge to `main` (or tag
  `v*`) it sets the build number automatically, archives with cloud signing
  (`-allowProvisioningUpdates` + API-key auth), exports, uploads to TestFlight.
  Until the secrets exist it runs the unsigned build and skips upload with a warning.
- Still Alfred's, once the API key exists: fill the listing via the API —
  description, keywords, categories (Food & Drink / Productivity), age rating,
  privacy = Data Not Collected (all data stays on-device), support + privacy URLs
  (privacy URL needs a hosted page — GitHub Pages on this repo is the easy host).
- Parthey tests via TestFlight; then submit for review (Alfred drives it via the API key,
  or leaves the final Submit click to Parthey — his choice at the time).
  Versioning + how updates reach users: `docs/VERSIONING.md`.

## Notes
- TestFlight builds last 90 days; App Store builds do not expire.
- The app is local-first: no accounts, no servers, no data leaves the phone. The future
  multi-user backend changes the privacy answers and must be reflected here before it ships.
