# Tiger Lillies Floral & Coffee — native iPhone prototype

A **SwiftUI iOS prototype** for the business at 205 Club Ln, Hamilton, GA. Built from your meeting notes and the WBL iOS project's **XcodeGen + builder.json + GitHub Actions** packaging convention, but as a **separate app**, not a rewrite of your WBL tracker.

**THIS IS ONLY A LOCAL PROTOTYPE.** It does **not** transmit orders, collect payment, contact real customers, synchronize with the live website, provide a multi-device staff login, or run a live rewards program. Do not give customers the impression that pickup requests created in the demo have been received. All actions take place on one device and can be erased by resetting the prototype.

## What's included

| Feature | Testable behavior |
|---|---|
| Black-and-white branding | Supplied logo on app surfaces and app icon, monochrome visual design |
| Browse and find products | Search; Flowers, Coffee, Plants & Gifts; starter catalog based on public site on Oct. 27, 2026 |
| Personalized and complex orders | Multiple items and quantities per order; notes per item and overall order; select requested pickup date/time |
| Last-minute pickup planning | Same-day future requested times can be selected; awaiting manual staff acceptance — no real capacity/availability guarantees |
| Modifications | Edit *placed* orders in the Bag; once accepted, contact the shop for changes (requires real messaging integration) |
| Ready for pickup tracking | Order states Placed → Accepted → Preparing → Ready → Completed; staff can advance these in owner mode |
| Stars | 1 star per whole dollar spent, calculated only when order is marked Completed; 100-star milestone illustrated, no redemption yet |
| Streaks | Counts unique, consecutive purchase days for completed orders |
| Custom orders saved | Save a product with its preferences as a named favorite; tap Add to bag next time |
| Notifications | In-app inbox for new products and order updates; optionally request iOS permission for local device notification when an order becomes Ready |
| Messaging | Customer/owner message simulation on **one device only**; no real delivery |
| Reviews | Post-completion review prompts, stored as private local feedback; no Google posting |
| Owner screen | Fast add/edit product, availability switch, inspect orders, advance status, read local feedback, reply to local message |
| Website vs. app sales | App shows completed test orders; website column accepts **manually entered** example totals, explicitly NOT live sales |
| Offline access | Stored JSON in iPhone Documents directory; app's local data remains available offline |

### Test the flow

1. **Shop →** choose `Oh My Gourd!` or `Cutie Cup`, add item notes and multiple quantities.
2. **Bag →** add customer name and future pickup time, tap **Place test order**.
3. **Orders →** see request, edit while Placed.
4. **More → Open owner demo → Orders →** Accept → Start preparing → Mark ready → Picked up.
5. **Orders →** review and rate the completed order; **Stars →** see earned points; **Owner studio → Insights →** see completed app sales and add sample website sales.
6. **More → Reset all local test data** to start over.

## Instant browser demo

Double-click `browser-preview.html` to open the interactive offline preview in Chrome, Edge or Safari. It includes the same major flows (shop, bag, orders, stars, messages and owner studio). Browser data is stored locally where permitted by the browser. For the actual iPhone source, follow the steps below.

## Install/build source

Prerequisites: Mac with Xcode 15+ or an iOS CI service, XcodeGen, iOS 17.2+ target. This ZIP is **source, not an IPA**.

```bash
brew install xcodegen
cd TigerLilliesApp
xcodegen generate
open TigerLillies.xcodeproj
```

Alternatively, upload the **contents** of the extracted `TigerLilliesApp` folder to a **new GitHub repository**, not your WBL repository. The preserved `.github/workflows` provide the same build route as the reference WBL app. Set `builder.json`'s `github.owner` and `github.repo` to your new repository. Scheme: **TigerLillies**. Bundle ID: **com.buildertest.tigerlilliesdemo** (change before distribution). Unsigned IPA builds do not automatically install without signing/provisioning.

No third-party SDKs, API keys, backends, or network connections are required for this prototype. Source files are directly under `TigerLillies/`.

## Production integration requirements

A real rollout would need a secure **staff authentication** system (owner demo is currently a button, not secure), hosted data and inventory, checkout/payment integration, genuine sales channel attribution, live order acknowledgement/capacity checks, server-side messaging/push notifications, optional loyalty account identification, tax/pricing logic, accessibility testing, consent/privacy policy, backup and offline synchronization/conflict handling. The live website currently handles orders; this demo **does not replace it**. Business owner must approve rewards ratios, discounts, order modification deadlines, pickup SLA, and customer notification wording before launch.

## Catalog and store attribution

Publicly listed products and sample starting prices are drawn from [Tiger Lillies' website](https://www.tigerlilliesfloral.com/) as viewed Oct. 27, 2026. The website lists, for example, the seasonal `Oh My Gourd!` drink from $6.25, `Cutie Cup` at $55, `Low and Lush` from $80, and a $25 mum special. Check current products, prices, and pickup policies before launching. The app uses symbols instead of product photos because no permissions or locally owned photos were supplied.

The black-and-white company logo was supplied by the requester. This project is an independent concept/demo, not an official published company app.

## Verification

Source syntax can be parsed with a Swift compiler on non-macOS hosts. A full Xcode/iOS SDK build and simulator/device test must be performed on macOS/CI before the prototype can be considered validated for an iPhone.
