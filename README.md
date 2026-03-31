# Vibely Chatting App

Vibely is an iOS chat and social-discovery app built with **SwiftUI**, **Firebase**, and **Cloudinary**. It includes authentication, user profiles, real-time messaging, and a “Find” flow for discovering users.

## Features

- Email/password authentication, plus phone OTP wiring in the auth layer.
- Onboarding flow with username setup and persisted session restore.
- Real-time chat list and message updates with Firestore listeners.
- User search by username/phone (Firestore queries).
- Profile editing with image upload (profile/cover/gallery style image types).
- Cloudinary-backed media upload and Firebase Callable Function image delete.
- Gemini-powered callable function for lightweight mood emoji detection.

## Tech Stack

### iOS App
- SwiftUI (UI + navigation)
- MVVM + Clean-ish layering (`Domain`, `Data`, `Presentation`, `AppDI`)
- Firebase iOS SDK (Auth, Firestore, Functions)
- Cloudinary iOS SDK
- Swift Package Manager for dependencies

### Backend / Infra
- Firebase Firestore + Security Rules
- Firebase Cloud Functions (Node.js 22)
- Cloudinary media storage
- Google Generative AI SDK (`@google/generative-ai`) in Firebase Functions

## Project Structure

```text
Vibely/
  AppDI/                # Dependency wiring (AppContainer)
  Data/                 # Repository + DTO + mapper + external services
  Domain/               # Entities, value objects, repository contracts, use cases
  Presentation/         # SwiftUI features, view models, shared components
  Managers/             # Environment + service helpers (Cloudinary, haptics, mood)
functions/              # Firebase Cloud Functions (Node.js)
firebase.json           # Firebase project config
firestore.rules         # Firestore rules
storage.rules           # Storage rules
```

## Prerequisites

- macOS with latest stable Xcode supporting SwiftUI
- iOS Simulator or physical iPhone
- Firebase project
- Cloudinary account
- Node.js 22+ (for `functions/`)
- Firebase CLI (`npm i -g firebase-tools`)

## iOS Setup

1. **Clone the repo**
   ```bash
   git clone <your-repo-url>
   cd Vibely-Chatting-App
   ```

2. **Configure Firebase for iOS**
   - Create an iOS app in Firebase Console.
   - Download `GoogleService-Info.plist`.
   - Place it at `Vibely/GoogleService-Info.plist` (this project already contains one path reference).

3. **Set Gemini API key in xcconfig**
   - Copy the template file and create your local secrets config.
   - Template file in repo:
     - `Secrets.template.xcconfig ` (note: filename currently includes a trailing space).
   - Add:
     ```xcconfig
     GEMINI_API_KEY = your_actual_api_key
     ```
   - Ensure your Xcode build config includes this secrets file.

4. **Open the Xcode project**
   ```bash
   open Vibely.xcodeproj
   ```

5. **Resolve packages and run**
   - Let Xcode resolve Swift packages.
   - Select target `Vibely`.
   - Build and run on simulator/device.

## Firebase Functions Setup

From repo root:

```bash
cd functions
npm install
```

Run emulator:

```bash
npm run serve
```

Deploy functions:

```bash
npm run deploy
```

### Required function configuration

The Cloud Functions code expects Firebase runtime config values for:

- `gemini.key`
- `cloudinary.cloud_name`
- `cloudinary.api_key`
- `cloudinary.api_secret`

Example (run from repo root):

```bash
firebase functions:config:set \
  gemini.key="YOUR_GEMINI_KEY" \
  cloudinary.cloud_name="YOUR_CLOUD_NAME" \
  cloudinary.api_key="YOUR_CLOUDINARY_API_KEY" \
  cloudinary.api_secret="YOUR_CLOUDINARY_API_SECRET"
```

Then redeploy functions.

## Security & Secrets Notes

- Do **not** commit real API keys.
- Keep iOS secrets in local `xcconfig` files.
- Keep Firebase/Cloudinary secrets in secure function config or secret manager.
- Review `firestore.rules` and `storage.rules` before production rollout.

## Current Cloudinary Defaults in App Code

The iOS client currently contains default Cloudinary upload values in `CloudinaryService.swift` (cloud name, upload preset, folder). You should replace these with your own account values for production.

## Helpful Commands

From project root:

```bash
# List files quickly
rg --files

# Functions
cd functions && npm install
cd functions && npm run serve
cd functions && npm run deploy
```

## Roadmap Ideas

- Add unit/UI tests for view models and repositories.
- Move all secret/config values to environment-specific config.
- Add CI pipeline for lint/build/function deploy checks.
- Add richer moderation and abuse prevention around chat + AI signals.

---

If you want, I can also generate:
- a **contributor-focused README** (development workflow, branch strategy, commit style), or
- a **user-facing README** (screenshots, feature walkthrough, store-ready copy).
