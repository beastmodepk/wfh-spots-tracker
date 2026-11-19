# Publishing Work Spots — App Store checklist

Owner steps are Parthey's (Apple requires the account holder); the remaining steps are handled separately.
Status (2026-11-18): Apple Developer account ENABLED. Release pipeline BUILT —
`.github/workflows/release.yml` (merge to main → signed archive → TestFlight),
app icon generated, privacy policy at `docs/PRIVACY.md`, versioning rules at
`docs/VERSIONING.md`. App Store Connect record CREATED 2026-11-18 under store
name "My Work Spots" (plain "Work Spots" was already taken); bundle ID
com.parthey.workspots registered same day. API key "Alfred CI" (Admin) created
and the four GitHub secrets added 2026-11-18 — steps 2–4 below are DONE.
Distribution DECIDED 2026-11-13: **Unlisted + $9.99 + promo codes** (section 6) —
hidden from App Store search, family get it free via promo codes.

## 1. Apple Developer Program (Parthey)
- Enroll as Individual via the Apple Developer app (identity verification + $99/yr).
- Done when the confirmation email arrives and developer.apple.com/account shows membership.

## 2. App record in App Store Connect (Parthey, ~2 minutes — Apple only allows the account holder)
App Store Connect → Apps → "+" → New App, with exactly:
- Platform: iOS
- Name: **Work Spots** (if taken, a variant will be suggested before submission)
- Primary language: English (U.S.)
- Bundle ID: **com.parthey.workspots** (set in the Xcode project 2026-11-12). If it is not in the
  dropdown yet, register it first at developer.apple.com → Certificates, Identifiers & Profiles →
  Identifiers → "+" → App IDs → App → description "Work Spots", Bundle ID (Explicit): com.parthey.workspots,
  no capabilities needed → Register. Then it appears in the dropdown.
- SKU: `workspots-ios-001`
- User Access: Full Access

## 3. App Store Connect API key (Parthey creates, CI uses)
- App Store Connect → Users and Access → Integrations (API Keys) → Generate API Key
  - Name: `Alfred CI`
  - Access: **Admin** (needed so CI can create signing certificates automatically)
- Note the **Key ID** and **Issuer ID** shown on that page.
- Download the `.p8` file (downloadable ONCE) and store it via Secure Vault — never chat, never email.

## 4. GitHub repo secrets (Parthey adds — deploy key cannot)
Repo → Settings → Secrets and variables → Actions → New repository secret:
- `ASC_KEY_ID` — from step 3
- `ASC_ISSUER_ID` — from step 3
- `ASC_KEY_P8` — full contents of the .p8 file
- `ASC_TEAM_ID` — developer.apple.com → Account → Membership details → Team ID

## 5. Release pipeline — BUILT 2026-11-13
- ✅ Real bundle ID in the project; app icon generated (1024px, pin + coffee cup);
  privacy policy page at `docs/PRIVACY.md`.
- ✅ Release workflow `.github/workflows/release.yml`: on merge to `main` (or tag
  `v*`) it sets the build number automatically, archives with cloud signing
  (`-allowProvisioningUpdates` + API-key auth), exports, uploads to TestFlight.
  Until the secrets exist it runs the unsigned build and skips upload with a warning.
- Still to do, once the API key exists: fill the listing via the API —
  description, keywords, categories (Food & Drink / Productivity), age rating,
  privacy = Data Not Collected (all data stays on-device), support + privacy URLs
  (privacy URL needs a hosted page — GitHub Pages on this repo is the easy host).
- Parthey tests via TestFlight; then submit for review (submission is driven via the API key,
  or leaves the final Submit click to Parthey — his choice at the time).
  Versioning + how updates reach users: `docs/VERSIONING.md`.

## 6. Distribution — Unlisted + $9.99 + promo codes (DECIDED 2026-11-13, Parthey)

Goal: family use the app free, indefinitely, with normal App Store updates —
while the public can't find it and is deterred from buying it if the link leaks.

Order matters; do these in sequence once steps 2–4 are done and a build is in
App Store Connect:

1. **Paid Apps Agreement (Parthey, account holder).** App Store Connect →
   Business → Agreements, Tax, and Banking → accept the Paid Apps Agreement
   and complete tax/banking. Without it the app can only be offered free.
2. **Price $9.99 (via API, or Parthey in Connect).** App → Pricing and
   Availability → Add Pricing → base country United States → **$9.99**.
   Apple generates the other storefront prices from that base.
3. **Manual release (important).** On the version page set release to
   **Manually release this version**. Do NOT auto-release: the app must not go
   live as a searchable public listing while the unlisted request is pending.
4. **Review Notes — paste exactly this** in the version's App Review
   Information → Notes field before submitting:
   > This app is intended for unlisted distribution to a small, limited
   > audience (the developer's family). A request for unlisted app
   > distribution will be submitted for this app. It is a finished app,
   > not a beta or prerelease.
5. **Submit for Review** (final Submit stays Parthey's tap, per house standard).
6. **Unlisted request (Parthey, account holder only).** After submitting to
   App Review, file https://developer.apple.com/contact/request/unlisted-app/
   Requests are declined if the app hasn't been submitted to App Review or is
   in a beta/prerelease state. On approval the distribution method changes to
   **Unlisted App** under Pricing and Availability (and stays unlisted for all
   future versions); the App Store link itself stays the same.
7. **Release the version** once BOTH App Review and the unlisted request are
   approved. Result: no search / categories / charts / recommendations —
   installable only via the direct link.
8. **Promo codes — family get it free (generated in Connect, Parthey sends).**
   App Store Connect → app → Promo Codes → request codes for the current
   version. Rules: up to **100 per version per platform**, each **single-use**,
   **expires 4 weeks after generation** — so generate only when a family
   member is ready to redeem, one fresh code per person. A redeemed app
   functions as if purchased: permanent ownership, free re-downloads, and
   normal updates for every future version (no new code needed per update).
   Family redeem path: App Store app → profile picture → Redeem Gift Card
   or Code → enter the code manually.
   Note: promo-code users can't leave an App Store rating/review — fine here.

Caveats, plainly: unlisted is *hidden, not private* — anyone who gets the
link can buy it at $9.99 (the price is the deterrent, not a lock; the app has
no login gate). Treat the link like a family secret. If real access control
is ever needed, it has to be built into the app.

## Notes
- TestFlight builds last 90 days; App Store builds do not expire.
- The app is local-first: no accounts, no servers, no data leaves the phone. The future
  multi-user backend changes the privacy answers and must be reflected here before it ships.
