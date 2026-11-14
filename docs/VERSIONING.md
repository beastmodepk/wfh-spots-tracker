# Versioning & updates — Work Spots (the house standard for all our apps)

## The two numbers

Every iOS build carries **two** versions. They do different jobs:

| Number | Where users see it | Example | Who changes it |
|---|---|---|---|
| **Marketing version** (`MARKETING_VERSION`) | App Store page, Settings | `1.2.0` | A human, in the release PR |
| **Build number** (`CURRENT_PROJECT_VERSION`) | TestFlight list, App Store Connect | `214` | **CI only — never by hand** |

Apple's rules: a build number must be **strictly higher than every previous
upload** for that app, even for the same marketing version. Reusing one is an
automatic rejection at upload. That is why CI owns it.

## Marketing version = Semantic Versioning

`MAJOR.MINOR.PATCH`

- **PATCH** `1.2.0 → 1.2.1` — bug fixes only, no new behaviour.
- **MINOR** `1.2.0 → 1.3.0` — new features, old data and habits still work.
- **MAJOR** `1.x → 2.0.0` — big redesign, or a change that breaks old data/flows.

How a release happens:

1. Work lands on feature branches; PRs merge to `main` freely.
   Every merge to `main` uploads a **TestFlight** build automatically
   (build number = GitHub run × 10 + attempt, set by `release.yml`).
2. When a set of changes is worth shipping publicly, open a small release PR
   that only bumps `MARKETING_VERSION`, then tag that merge `v<version>`
   (e.g. `v1.3.0`). The tag build is the one you submit.
3. In App Store Connect, attach that build to the version, fill "What's New",
   and **Submit for Review**. Keep the final release manual (not automatic
   after approval) while we are small — one deliberate tap beats a surprise.
4. After approval, use **phased release** (Apple's default 7-day ramp:
   1% → 2% → 5% → 10% → 20% → 50% → 100% of users per day). You can pause
   the ramp for up to 30 days if crash reports or reviews go bad.

## How updates reach users

- **TestFlight testers** — get a push/email when a build finishes processing
  (~15–30 min after upload); they update inside the TestFlight app.
  Builds **expire after 90 days**; a tester on an expired build must install
  a newer one. Internal testers (≤100, your own team) skip Beta App Review;
  external testers (≤10,000) need a light beta review per version.
- **App Store users** — nothing to do for most people: iOS auto-updates apps
  when the user's "App Updates" setting is on (the default). Everyone else
  updates manually in the App Store → profile → Update. A user can stay on an
  old version indefinitely — **we cannot force an update** from outside the app.
- **No rollback.** Apple cannot un-ship a version. A bad release is fixed
  *forward*: ship a PATCH build, expedite review if it's urgent, and pause
  the phased ramp meanwhile.

## Designing so old versions survive

Because users update on their own schedule, every release must tolerate the
previous ones:

- Local data migrations must be **additive and backward-compatible** — never
  rename/delete stored fields in a way an older build (or a downgrade of
  data) would choke on. Test upgrading from the last App Store version.
- When a backend arrives later: keep old API versions alive, and only then
  can we add a polite in-app "please update" nudge (App Store lookup) or, for
  a truly breaking change, a minimum-version gate. Local-first v1 has no
  server, so there is no gate — by design.
- Never ship a TestFlight build number scheme change mid-stream; the CI
  formula above is monotonic for the life of the repo.

## Per-app state of this standard

See the app-store pipeline standard document for
the live inventory: which apps have this pipeline, and what blocks each one.
