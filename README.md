<div align="center">

![Kutub FM](https://img.shields.io/badge/Kutub%20FM-Arabic%20Audio%20Platform-F2CA50?style=for-the-badge&labelColor=B71C1C&color=F2CA50)

![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-B71C1C?style=for-the-badge&logo=flutter&logoColor=white)
![Architecture](https://img.shields.io/badge/Clean%20Architecture%20%2B%20MVVM-F2CA50?style=for-the-badge&logo=datadog&logoColor=black)
![State](https://img.shields.io/badge/Provider%20%2F%20flutter_bloc-Enterprise%20Ready-B71C1C?style=for-the-badge&logo=flutter&logoColor=white)
![Audio](https://img.shields.io/badge/Background%20Audio-just__audio%20Stack-F2CA50?style=for-the-badge&logo=musicbrainz&logoColor=black)

# Kutub FM

**An enterprise-grade Arabic mobile platform for audiobooks, podcasts, live radio, and synchronized reading experiences.**

**منصة عربية متكاملة للكتب الصوتية، البودكاست، الراديو المباشر، وتجربة القراءة المتزامنة مع الصوت في تطبيق واحد.**

</div>

## Overview
Kutub FM is a Flutter-based audio knowledge platform designed for Arabic-speaking users who care about culture, learning, and meaningful content consumption. The product vision goes beyond a simple media player: it aims to deliver a unified Arabic-first experience where users can listen, read, discover, and engage with spoken knowledge across multiple content formats.

From an engineering perspective, the project is structured as a scalable mobile codebase with modular feature boundaries, a shared audio engine, reusable core services, and a presentation layer organized around MVVM principles. This makes Kutub FM suitable for product evolution, backend expansion, and enterprise-level feature growth.

## Why This Project Is More Than a Simple App
- 🧱 **Modular feature-first structure** that separates concerns and keeps the codebase maintainable as the product grows.
- 🧠 **Clean Architecture + MVVM approach** for clearer responsibilities across presentation, domain, data, and shared core layers.
- 🎵 **Centralized audio orchestration** for audiobooks, podcasts, reading audio, and live radio in a single playback pipeline.
- 🧭 **Reusable app shell, navigation, and mini-player** for a consistent cross-feature user experience.
- 🌍 **Arabic-first UX** with localized content flows, RTL-friendly design direction, and content models tailored to Arab users.
- 🚀 **Enterprise-minded foundation** that supports future backend services, AI features, analytics, subscriptions, and offline expansion.

## Core Features
- 🎧 **Audiobook playback**
  Discover and play curated Arabic audio content with a dedicated player, progress tracking, and playback controls.

- 📖 **Read-along mode**
  Experience synchronized reading with audio playback, transcript navigation, speed control, and contextual reading support.

- 📻 **Live FM radio**
  Browse and stream live Egyptian radio stations through a REST-based integration with a radio directory service.

- 🎙️ **Podcast experience**
  Explore podcast episodes, open detailed episode pages, play audio, and interact with episode discussions.

- 💬 **Reader sessions and social interaction**
  Community-oriented reading sessions include post creation, reader activity, comments, and discussion-driven engagement.

- 🧩 **Feature-based media ecosystem**
  The repository already includes dedicated modules for audio library, audio player, podcasts, radio, profile, onboarding, reels, and reader journeys.

- 🔊 **Global mini-player**
  A shared playback surface keeps the active audio context accessible while users navigate the app.

- 🎨 **Branded UI direction**
  The current design system already reflects a strong visual identity centered around warm gold/yellow accents and high-energy red highlights.

## Architecture
### Clean Architecture + MVVM
Kutub FM follows a practical **Clean Architecture + MVVM** setup adapted for Flutter:

- **Presentation layer**
  Flutter pages, widgets, providers, and view models manage UI rendering and presentation state.

- **Domain layer**
  Entities and repository contracts define the business-facing models and feature boundaries.

- **Data layer**
  Repositories, services, and local/mock or remote data sources provide feature data and integration logic.

- **Core layer**
  Shared concerns such as navigation, theming, app shell, and audio playback orchestration live in `lib/core`.

### Architecture Mapping
| Layer | Responsibility | Examples in This Repository |
| --- | --- | --- |
| `core` | Shared infrastructure and cross-cutting concerns | audio engine, routes, theme, navigation, app shell |
| `features/*/presentation` | Views + ViewModels/Providers | screens, widgets, `ChangeNotifier`-based state |
| `features/*/domain` | Business entities and contracts | book, podcast, radio, profile, and reader entities |
| `features/*/data` | Repositories and services | mock data, transcript loaders, radio API service |

### MVVM in Practice
- **View**: Flutter screens and UI widgets
- **ViewModel**: `ChangeNotifier`-driven providers and view models
- **Model**: Domain entities, DTOs, and repository-backed data structures

> Note: the current implementation is primarily **Provider/ChangeNotifier-based**, while `flutter_bloc` is already included in the dependency stack for future state-management scaling where more complex workflows justify it.

## Tech Stack
| Area | Technologies | Notes |
| --- | --- | --- |
| Mobile Framework | `Flutter`, `Dart` | Cross-platform mobile development |
| State Management | `Provider`, `ChangeNotifier`, `flutter_bloc` | Provider is active today; `flutter_bloc` is included for scalable evolution |
| Audio Service Layer | Custom `AudioService`, `just_audio`, `just_audio_background`, `audio_session` | Unified playback, background audio, media session handling |
| Networking | `Dio`, `http`, REST API integrations | Used for remote content integration such as live radio discovery |
| Localization & UI | `flutter_localizations`, `google_fonts`, Material 3 | Arabic-first experience and custom typography |
| Documents & Reading | `syncfusion_flutter_pdf`, transcript JSON loaders | Supports read-along and document-linked experiences |

## Project Structure
```text
lib/
├── core/
│   ├── audio/
│   ├── layout/
│   ├── navigation/
│   ├── routes/
│   └── theme/
├── features/
│   ├── audio_library/
│   ├── audio_player/
│   ├── auth/
│   ├── book_details/
│   ├── book_reader/
│   ├── home/
│   ├── onboarding/
│   ├── podcast/
│   ├── profile/
│   ├── radio/
│   ├── reader_sessions/
│   ├── reels/
│   └── splash/
└── main.dart
```

## Engineering Highlights
- **Shared audio domain**
  One centralized audio provider/service handles multiple playback modes: audiobook, reading audio, podcast, and FM radio.

- **Feature isolation**
  Most user journeys are implemented as standalone feature modules, improving maintainability and onboarding for new contributors.

- **Scalable core services**
  Navigation, theming, and playback are abstracted into reusable core modules instead of being scattered across screens.

- **Product-ready extensibility**
  The structure supports gradual replacement of mock data with real backend services without requiring a UI rewrite.

## Current Implementation Status
Kutub FM already includes production-oriented structure and a broad product surface. At the moment, the repository combines:

- **Live integration**
  Egyptian FM stations are fetched through a remote radio directory API.

- **Bundled or mock-driven modules**
  Some audiobook, podcast, profile, and community flows currently use local/mock data to accelerate product design and UX validation.

This is a valid and professional stage for a growing product: the architecture is prepared for backend expansion while the user experience is being shaped in parallel.

## Installation
### Prerequisites
- Flutter SDK installed
- Dart SDK `3.11+`
- Android Studio, Xcode, or a configured Flutter-compatible IDE
- A connected device or emulator

### Setup
```bash
git clone https://github.com/<your-username>/kutub_fm.git
cd kutub_fm
flutter pub get
flutter run
```

### Optional Verification
```bash
flutter analyze
```

## Product Vision
Kutub FM is built for the Arabic knowledge economy. The long-term goal is to unify reading, listening, discovery, and community into a single digital experience that feels culturally relevant, technically robust, and commercially scalable.

## Roadmap
- 🤖 **AI-powered recommendations**
  Personalized content suggestions based on listening behavior, reading interests, and user intent.

- 🧠 **Semantic discovery**
  AI-assisted search across books, podcasts, quotes, topics, and spoken segments.

- ✍️ **Smart summaries and highlights**
  Auto-generated episode summaries, chapter insights, and key takeaways in Arabic.

- 🗣️ **Advanced narration intelligence**
  AI-enhanced read-along alignment, pronunciation support, and contextual voice experiences.

- ☁️ **Cloud sync**
  Cross-device resume, bookmarks, reading progress, saved lists, and listening history.

- 📥 **Offline-first media**
  Downloadable books, podcast episodes, and synchronized reading assets for on-the-go access.

- 🔐 **Enterprise-grade backend capabilities**
  Authentication hardening, subscriptions, analytics, moderation, content management, and operational observability.

## Suggested Positioning
If you are presenting Kutub FM on GitHub, in a portfolio, or to stakeholders, the strongest positioning is:

> **Kutub FM is an enterprise-level Arabic audio content platform built with Flutter, combining audiobooks, podcasts, live radio, and synchronized reading in a scalable Clean Architecture + MVVM codebase.**

## Repository Notes
- The app title displayed in the UI is Arabic-first: `كتب FM`.
- The visual direction is centered around **gold/yellow prominence** and **red energy accents**, matching a premium media brand feel.
- The repository is a strong foundation for turning a rich prototype into a production-ready digital content product.
