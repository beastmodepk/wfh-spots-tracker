# Publishing Work Spots — App Store checklist

Owner steps are Parthey's (Apple requires the account holder); everything else is Alfred's.
Status (2026-11-12): CI builds the unsigned app green. Enrollment in the Apple Developer
Program is in progress.

## 1. Apple Developer Program (Parthey)
- Enroll as Individual via the Apple Developer app (identity verification + $99/yr).
- Done when the confirmation email arrives and developer.apple.com/account shows membership.

## 2. App record in App Store Connect (Parthey, ~2 minutes — Apple only allows the account holder)
App Store Connect → Apps → "+" → New App, with exactly:
- Platform: iOS
- Name: **Work Spots** (if taken, Alfred will suggest a variant before submission)
- Primary language: English (U.S.)
- Bundle ID: the one set in the Xcode project at that time (Alfred sets this first and confirms it here)
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

## 5. Release pipeline (Alfred)
- Set the real bundle ID in the project; generate the app icon; privacy policy page in `docs/`.
- Add a release workflow: on a version tag, archive with cloud signing
  (`-allowProvisioningUpdates` + API-key auth), export, and upload to TestFlight.
- Fill the listing via the API: description, keywords, categories (Food & Drink / Productivity),
  age rating, privacy = Data Not Collected (all data stays on-device), support + privacy URLs.
- Parthey tests via TestFlight; then submit for review (Alfred drives it via the API key,
  or leaves the final Submit click to Parthey — his choice at the time).

## Notes
- TestFlight builds last 90 days; App Store builds do not expire.
- The app is local-first: no accounts, no servers, no data leaves the phone. The future
  multi-user backend changes the privacy answers and must be reflected here before it ships.
