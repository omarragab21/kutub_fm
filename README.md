<div align="center">

![Kutub FM](https://img.shields.io/badge/Kutub%20FM-Arabic%20Knowledge%20Audio%20Platform-F2CA50?style=for-the-badge&labelColor=B71C1C&color=F2CA50)
![Flutter](https://img.shields.io/badge/Flutter-Cross--Platform%20Mobile-B71C1C?style=for-the-badge&logo=flutter&logoColor=white)
![Architecture](https://img.shields.io/badge/Clean%20Architecture%20%2B%20MVVM-Scalable-F2CA50?style=for-the-badge&logo=datadog&logoColor=black)
![Audio](https://img.shields.io/badge/Audio%20Engine-Background%20Ready-B71C1C?style=for-the-badge&logo=googlepodcasts&logoColor=white)
![Status](https://img.shields.io/badge/Status-Foundation%20for%20Production-F2CA50?style=for-the-badge&labelColor=7A0F12&color=F2CA50)

# Kutub FM

**Kutub FM is an Arabic-first mobile platform for audiobooks, podcasts, live radio, and synchronized reading experiences.**

**كتب FM هي منصة موبايل عربية للكتب الصوتية، البودكاست، الراديو المباشر، وتجربة القراءة المتزامنة مع الصوت.**

</div>

## Table of Contents
- [Executive Summary](#executive-summary)
- [Product Vision](#product-vision)
- [Target Audience](#target-audience)
- [What Makes Kutub FM Valuable](#what-makes-kutub-fm-valuable)
- [Feature Breakdown](#feature-breakdown)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Visual Identity](#visual-identity)
- [Current Status: Honest Assessment](#current-status-honest-assessment)
- [Why This Can Be Presented as Enterprise-Level](#why-this-can-be-presented-as-enterprise-level)
- [Installation](#installation)
- [Development Notes](#development-notes)
- [Roadmap](#roadmap)

## Executive Summary
Kutub FM is not positioned as a simple audio player or a basic Flutter showcase. The project aims to become a **unified Arabic digital knowledge platform** where users can discover, consume, and interact with long-form and short-form spoken content through a single product experience.

The repository already reflects that ambition in its engineering direction:

- It uses a **feature-first modular structure**.
- It separates code into **presentation, domain, and data layers** in several features.
- It includes a **shared audio engine** instead of isolated playback logic per screen.
- It centralizes navigation, theming, and shell-level behavior inside `lib/core`.
- It is organized in a way that can scale from mock-driven product validation into backend-backed production development.

بالعربي: المشروع ليس "شاشة تشغيل صوت" فقط، بل قاعدة منتج حقيقية لمنصة محتوى صوتي عربية يمكن تطويرها تدريجيًا إلى تطبيق إنتاجي واسع النطاق.

## Product Vision
The core vision of Kutub FM is to solve a real gap in Arabic digital content consumption: users often move between separate apps for audiobooks, podcasts, live radio, reading apps, and community interaction. Kutub FM brings those journeys together in a single Arabic-first product.

The long-term product direction can be summarized as:

- **Discover** meaningful Arabic audio content
- **Listen** to books, podcasts, and live radio
- **Read** along with synchronized text when available
- **Resume** content seamlessly across features
- **Engage** socially with readers and listeners
- **Scale** toward intelligent recommendations and AI-assisted knowledge navigation

## Target Audience
Kutub FM is built for:

- Arabic-speaking users interested in culture, literature, history, philosophy, religion, self-development, and meaningful content
- Users who prefer listening over traditional reading in parts of their day
- Users who want a richer experience than a standard media player
- Product teams or stakeholders exploring a serious Arabic media-tech concept

## What Makes Kutub FM Valuable
### Product Value
- It combines multiple content formats inside one coherent experience.
- It is designed for Arabic content consumption rather than treating Arabic as a secondary language layer.
- It opens the door for hybrid reading and listening experiences that are still underdeveloped in Arabic products.

### Engineering Value
- The codebase is already structured around extensibility.
- Shared infrastructure exists for audio, navigation, and app-wide UI behavior.
- Several features are isolated enough to be independently expanded or connected to real services later.

### Portfolio / GitHub Value
- It demonstrates architectural thinking, not just UI implementation.
- It shows product breadth across audio, reading, radio, and community use cases.
- It can be presented as a serious foundation for an Arabic content-tech platform.

## Feature Breakdown
The repository currently contains a broad product surface. Some modules are already connected to real remote data, while others are implemented with local or mock data to validate UX and architecture.

| Feature | What It Does | Current State |
| --- | --- | --- |
| `Splash / Onboarding` | Entry flow and first-use introduction | Implemented |
| `Auth` | Session state and logout flow | Demo shell, not production auth |
| `Home` | Categories and recommended books discovery | Implemented with mock repository data |
| `Audio Library` | Browse audio categories and featured items | Implemented with local/mock data |
| `Audio Player` | Dedicated audiobook listening experience | Implemented |
| `Book Reader` | Read-along experience with transcript syncing | Implemented using bundled assets |
| `Podcast` | Episode browsing, details, playback, comments | Implemented with mock data |
| `FM Radio` | Browse and stream live Egyptian radio stations | Implemented with remote API integration |
| `Reader Sessions` | Community-style posts and comments | Implemented with mock social feed |
| `Reels` | Short-form vertical media discovery | UI/UX prototype with mock data |
| `Profile / Settings` | User profile and preferences surfaces | Implemented with mock repository data |
| `Global Mini Player` | Shared playback surface across the app | Implemented |

### Detailed Feature Notes
#### 1. Audiobook Experience
- A dedicated audio player screen exists for long-form listening.
- The player is backed by a shared central audio provider.
- The codebase already models audiobook entities, metadata, progress, and playback state.

#### 2. Read-Along Experience
- The `book_reader` feature is one of the strongest parts of the project conceptually.
- It supports synchronized reading behavior with transcript-based segment matching.
- It includes seeking, active text synchronization, speed control, and a reading-focused interface.
- In the current repository, this experience is powered by bundled assets such as `assets/audio_book.mp3` and `assets/transcript.json`.

#### 3. Live Radio
- The radio feature is not just static UI.
- It fetches Egyptian radio stations through a remote REST integration.
- It resolves playable stream URLs and hands playback to the shared audio layer.
- This is currently the clearest example of a live data-driven module in the repository.

#### 4. Podcasts
- The podcast module includes list and details flows.
- It supports playback and comments UX.
- Current episode content is mock-backed, which is acceptable at this stage but should be connected to a real content source in production.

#### 5. Reader Sessions / Community Layer
- This feature explores a social dimension around reading and listening.
- Users can create posts, view discussion-like cards, and add comments.
- The implementation is currently local/mock-driven, but the feature is important because it expands the product beyond passive content consumption.

#### 6. Mini Player and Shared Audio Context
- Kutub FM uses a shared mini-player inside the app shell.
- This creates continuity between content surfaces and avoids isolated playback experiences.
- From a product perspective, this is a strong sign of app-level design maturity.

## Architecture
Kutub FM follows a **practical Clean Architecture + MVVM approach**. It is not an over-engineered academic implementation; it is a product-oriented adaptation that aims to keep the codebase understandable and scalable.

### Architectural Principles
- **Feature-first organization**
  Each major product area lives inside its own feature module.

- **Separation of concerns**
  UI, business-facing models, and data-access code are separated where relevant.

- **Core abstraction layer**
  Shared concerns are extracted into `lib/core` instead of being duplicated inside features.

- **Stateful presentation model**
  ViewModels and Providers sit close to the UI layer and expose screen state in a way that supports iterative product development.

### Clean Architecture + MVVM Mapping
| Layer | Role in Kutub FM | Examples |
| --- | --- | --- |
| `Presentation` | UI screens, widgets, presentation state, user interaction handling | pages, widgets, providers, view models |
| `Domain` | Product models and business-facing contracts | entities and repository interfaces |
| `Data` | Repository implementations, mock sources, service classes | repositories, API services, transcript loaders |
| `Core` | Cross-cutting infrastructure | theme, routes, navigation, audio service, mini-player shell |

### Example Data Flow
For a feature such as home discovery:

```text
Screen -> ViewModel -> Repository -> Data Source -> Entities -> UI Render
```

For audio playback:

```text
UI Screen / Mini Player
        ->
AudioProvider
        ->
AudioService
        ->
just_audio player
        ->
Background audio / media session state
```

### Why This Architecture Matters
- It prevents feature logic from being trapped inside screens.
- It supports replacing mock repositories with real APIs later.
- It makes shared playback behavior available across multiple features.
- It allows the product to grow without turning into one large `main.dart`-style app.

## Project Structure
The project is organized around `core` and `features`, which is the right direction for a product with multiple user journeys.

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

### Structural Interpretation
- `core/audio` is a key strategic area because it centralizes playback for books, reading audio, podcasts, and radio.
- `core/layout` and `core/navigation` help enforce app-level consistency.
- `features/*/domain`, `features/*/data`, and `features/*/presentation` show the architectural intent clearly in several modules.
- Some features are still simpler than others, but the structure is strong enough for continued expansion.

## Tech Stack
| Area | Technology | Why It Matters |
| --- | --- | --- |
| Mobile Framework | `Flutter`, `Dart` | Cross-platform UI and product delivery |
| State Management | `Provider`, `ChangeNotifier` | Primary state approach used in the current implementation |
| State Evolution Path | `flutter_bloc` | Already included in dependencies for future scaling of complex flows |
| Audio Playback | `just_audio` | Core playback engine |
| Background Playback | `just_audio_background` | Media session and background audio handling |
| Audio Focus / Session | `audio_session` | Better playback behavior on device |
| Networking | `Dio`, `http` | Remote integrations such as radio station discovery |
| Localization | `flutter_localizations` | Arabic-first app setup |
| Typography | `google_fonts` | Custom visual identity and Arabic presentation polish |
| Document Support | `syncfusion_flutter_pdf` | Foundation for richer reading flows |
| Media Support | `video_player`, `youtube_player_flutter`, `youtube_explode_dart` | Present in the stack for richer media evolution |

### State Management Clarification
This point matters because many READMEs overclaim here.

- The project currently **uses Provider/ChangeNotifier in practice**.
- `flutter_bloc` is **installed but not the primary active pattern yet**.
- That does not weaken the project. It simply means the current codebase is in a **Provider-led implementation stage with room for BLoC adoption where complexity demands it**.

## Visual Identity
Kutub FM already shows a recognizable visual direction instead of generic default Flutter styling.

### Primary Design Signals
- **Gold / Yellow accent**
  Used to communicate premium knowledge, warmth, and literary value

- **Red energy layer**
  Useful for attention, live audio, urgency, and media intensity

- **Dark premium surfaces**
  The UI is designed around dark backgrounds and high-contrast accents

### Current Theme References
The shared app theme includes colors such as:

| Token | Value |
| --- | --- |
| `primary` | `#F2CA50` |
| `primaryContainer` | `#D4AF37` |
| `background` | `#131313` |
| `onPrimary` | `#3C2F00` |

This supports the project identity you requested: **yellow + red premium media brand language**.

## Current Status: Honest Assessment
This section is intentionally direct.

Kutub FM can be described as **enterprise-level in architectural ambition and product scope**, but it is **not yet a fully production-complete enterprise application**. That distinction is important and healthy.

### What Is Strong Today
- The codebase is already larger and more modular than a typical sample app.
- Shared audio logic is centralized rather than copied across screens.
- Multiple user journeys exist in the same repository.
- The app has a real branded direction.
- There is already at least one real external integration in the radio feature.

### What Is Still Mock / Prototype / Early-Stage
| Area | Current Reality |
| --- | --- |
| Authentication | Demo-oriented provider state; not real backend auth |
| Home content | Mock repository data |
| Podcasts | Mock-backed episode data |
| Profile | Mock repository data |
| Reader sessions | Mock social feed and local interactions |
| Reels | Mock/generated content |
| Read-along assets | Bundled local assets, not remote content delivery |
| Testing | Minimal automated testing currently visible in repo |

### Testing Reality
At the time of writing, the repository includes a very small widget smoke test:

- `test/widget_test.dart` checks that the app boots and renders the splash screen

This is useful as a sanity check, but it is not enough for a production-grade release pipeline.

### What Is Missing Before Calling It Production-Ready
- Real authentication and session persistence
- Backend APIs for books, podcasts, profile, and community features
- Error monitoring and analytics
- Better automated testing coverage
- Offline strategy for downloads and resume state
- CI/CD pipeline documentation
- Environment configuration strategy
- Security and content moderation policies

## Why This Can Be Presented as Enterprise-Level
This is the subtle part.

You can present Kutub FM as an **enterprise-level mobile application foundation** because:

- The **problem space** is broad and commercially meaningful
- The **architecture** is modular and maintainable
- The **audio system** is centralized and app-wide
- The **feature map** already spans discovery, playback, reading, live streaming, profile, and community
- The repository is clearly designed for **growth**, not just for a coding challenge

The honest framing is:

> Kutub FM is an enterprise-minded Arabic audio platform with a scalable architecture and a wide product surface, currently in the stage of evolving from advanced prototype / product foundation into a fully production-backed application.

That is a strong, credible, and technically honest description.

## Installation
### Prerequisites
- Flutter SDK installed
- Dart SDK `3.11+`
- Android Studio, Xcode, or VS Code with Flutter tooling
- A device, simulator, or emulator

### Clone and Run
```bash
git clone https://github.com/<your-username>/kutub_fm.git
cd kutub_fm
flutter pub get
flutter run
```

### Recommended Validation Commands
```bash
flutter analyze
flutter test
```

### Bundled Assets Used by the Current Demo
The current repository includes local assets that support the demo experience:

- `assets/audio_book.mp3`
- `assets/book.pdf`
- `assets/transcript.json`

These make the project easy to run locally without depending on a full backend.

## Development Notes
### Architectural Notes
- The app boots through a `MultiProvider` setup in `main.dart`.
- Audio session configuration and background audio initialization are handled at startup.
- Navigation is route-based and coordinated through shared route definitions and navigation state helpers.

### Product Notes
- Arabic is the primary locale configured in the app.
- The UI title is Arabic-first: `كتب FM`.
- The product direction mixes utility, culture, and media immersion.

### Practical Notes for Future Contributors
- Replace mock repositories feature by feature instead of rewriting the app.
- Keep the shared audio layer centralized.
- Preserve feature boundaries when adding real APIs.
- Introduce stronger test coverage alongside backend integration work.

## Roadmap
The roadmap below reflects a realistic evolution path for Kutub FM.

### Platform Roadmap
- ☁️ User accounts, persistent sessions, and cloud sync
- 📥 Offline downloads for books, podcasts, and transcripts
- 🔔 Notifications for new episodes, books, and live programs
- 💳 Subscription and monetization flows
- 🛠️ Admin/CMS integration for content operations

### Intelligence Roadmap
- 🤖 AI-based recommendations for books, podcasts, and radio programs
- 🧠 Semantic search across titles, topics, speakers, and transcript segments
- ✍️ AI-generated summaries and key takeaways in Arabic
- 🗣️ Smarter read-along alignment and narration-aware UX
- 🏷️ Automatic content tagging and topic clustering

### Community Roadmap
- 👥 Real reader/listener communities
- 💬 Rich threaded discussions and moderation
- ❤️ Saved quotes, highlights, and shareable insight cards
- 📚 Group listening or shared reading sessions

## Suggested One-Line Positioning
If you want a concise line for GitHub, portfolio, or stakeholder decks, use this:

> **Kutub FM is a scalable Arabic mobile platform built with Flutter that unifies audiobooks, podcasts, live radio, and synchronized reading in a Clean Architecture + MVVM codebase.**

## Final Note
Kutub FM is already strong enough to be taken seriously. The right way to present it is not by pretending it is finished, but by showing that:

- the **product idea is ambitious and relevant**
- the **engineering direction is disciplined**
- the **architecture is ready for real growth**
- the **current repository is a serious foundation, not a throwaway demo**

That combination is exactly what makes a project valuable on GitHub.
