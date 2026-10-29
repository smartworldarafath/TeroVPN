# TeroVPN Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and deliver **TeroVPN**, an Android VPN application combining the exact Fastly MASQUE HTTP/2-3 tunneling engine from `firefox-vpn-client` with the official Proton VPN Android UI and complete TeroVPN branding.

**Architecture:** Flutter client application communicating with a native Go VPN core process (`CoreService.kt` / `libgojni.so`) via Android's `VpnService` TUN interface and local REST API (`127.0.0.1:10820`). The UI replicates Proton VPN's Jetpack Compose design language using Plus Jakarta Sans typography, seamless edge-to-edge layouts, and animated sliding transitions across Home, Countries, Profiles, and Settings.

**Tech Stack:**
- **Frontend / Client:** Flutter 3.47.5, Dart 3.13.4, `flutter_svg`, `google_fonts`, `http`
- **Native Android / Engine:** Kotlin, Android `VpnService`, Android SDK 36, precompiled Go VPN Core (`libgojni.so` / `core.aar`)
- **VPN Protocol:** WireGuard MASQUE / Fastly HTTP/2 & HTTP/3 (QUIC) tunneling with 50GB multi-account session rotation

**Spec Reference:** Proton VPN Android Redesign Reference & Mozilla Fastly Masque Edge Network (33 supported countries).

---

## Global Constraints

- **Branding:** Strictly branded as **TeroVPN** (`com.terovpn.android`). Zero Proton or Firefox naming, logos, or package strings in the finished app.
- **VPN Functionality:** Must retain real VPN tunnel behavior (no mock/simulated VPN).
- **Country Network:** Must support all 33 Fastly Edge countries from `firefox-vpn-client` with high-resolution vector SVG flags.
- **Visual Fidelity:** 100% faithful to Proton VPN Android app (transparent status bar at pixel 0, Plus Jakarta Sans typography, `#12101E` background, `#6D4AFF` interaction purple, mathematically centered sliding dock pill).
- **Security:** Zero hardcoded API keys, tokens, or credentials.

---

## Plan Tasks

### Task 1: Project Scaffolding & TeroVPN Branding Setup
**Files:**
- Create: `app/pubspec.yaml`
- Create: `app/lib/main.dart`
- Create: `app/assets/flags/` (all 33 country SVGs copied from `firefox-vpn-client`)
- Create: `app/assets/icons/` (app logos and custom Proton-style vector icons)
- Create: `app/android/app/src/main/AndroidManifest.xml`
- Create: `app/android/app/build.gradle.kts`
- Modify: `app/android/settings.gradle.kts`

- [ ] Initialize new Flutter app with package name `com.terovpn.android` and app title `TeroVPN`.
- [ ] Configure `pubspec.yaml` with required dependencies: `flutter_svg`, `google_fonts`, `http`, `intl`, `path_provider`.
- [ ] Copy all 33 country SVG flags into `app/assets/flags/` and declare asset folders in `pubspec.yaml`.
- [ ] Set application label to `TeroVPN` in `AndroidManifest.xml` with required Android VPN permissions (`BIND_VPN_SERVICE`, `INTERNET`, `ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE`).
- [ ] Run `flutter pub get` and verify that assets and dependencies resolve cleanly.

---

### Task 2: Native Android VpnService & Go Core Integration
**Files:**
- Create: `app/android/app/src/main/kotlin/com/terovpn/android/CoreService.kt`
- Create: `app/android/app/src/main/kotlin/com/terovpn/android/MainActivity.kt`
- Create: `app/android/app/src/main/jniLibs/` (extract `libgojni.so` and native architectures for `arm64-v8a`, `armeabi-v7a`, `x86_64`)
- Create: `app/android/app/libs/core.aar`
- Test: Verify native library linkage and `CoreService` manifest registration.

- [ ] Extract compiled Go core libraries (`core.aar` and native `jniLibs/`) from `firefox-vpn-client` release `v1.0.5`.
- [ ] Implement `CoreService.kt` extending Android `VpnService` to manage TUN interface allocation and route traffic through the Go core.
- [ ] Configure `MainActivity.kt` with Flutter `MethodChannel('app/android')` for starting, stopping, and checking VPN status.
- [ ] Add foreground notification channel (`terovpn_channel`) in `CoreService.kt` showing "TeroVPN is active" with disconnect action.
- [ ] Verify Android gradle build compiles with native dependencies without errors.

---

### Task 3: Core API Client & Controller Layer (Dart)
**Files:**
- Create: `app/lib/core/models.dart`
- Create: `app/lib/core/core_api.dart`
- Create: `app/lib/core/core_controller.dart`
- Create: `app/lib/core/android_core.dart`
- Create: `app/lib/core/ports.dart`
- Test: `app/test/core_api_test.dart`

- [ ] Implement `models.dart` with `Location`, `Protocol`, `VpnState`, `SessionStats`, and `AccountInfo` data classes.
- [ ] Implement `core_api.dart` providing HTTP REST client communicating with local Go core on `127.0.0.1:10820` using `local-api.token`.
- [ ] Implement `core_controller.dart` managing connection lifecycle (connect, disconnect, select country, ping locations, monitor traffic speed).
- [ ] Implement `android_core.dart` wrapping Android `MethodChannel` for native VPN service intent authorization and lifecycle.
- [ ] Write unit tests for `core_api.dart` to verify REST request parsing and location filtering.

---

### Task 4: Proton Design System & UI Components
**Files:**
- Create: `app/lib/theme/proton_theme.dart`
- Create: `app/lib/theme/proton_colors.dart`
- Create: `app/lib/theme/proton_typography.dart`
- Create: `app/lib/ui/components/country_flag.dart`
- Create: `app/lib/ui/components/server_load_bar.dart`
- Create: `app/lib/ui/components/filter_chip_button.dart`
- Create: `app/lib/ui/components/details_sheet.dart`

- [ ] Define `ProtonColors` tokens (`background: #12101E`, `surface: #181628`, `primary: #6D4AFF`, `activePill: #573BC7`, `connected: #2CFFCC`, `disconnected: #DC3251`).
- [ ] Configure `ProtonTypography` with Plus Jakarta Sans (Regular, SemiBold, Bold, ExtraBold).
- [ ] Implement `CountryFlag` widget rendering rounded SVG flags (32x22px, border radius 4px, subtle border) with error fallbacks.
- [ ] Implement `ServerLoadBar` widget displaying server traffic percentage bar with color tiers (green, yellow, red).
- [ ] Implement `FilterChipButton` widget matching Proton's exact chip design (height 42px, radius 12px, clean icon + text).
- [ ] Implement `DetailsSheet` slide-up modal showing live download/upload speeds, latency, IP address, and HTTP/3 protocol info.

---

### Task 5: Home Screen Implementation
**Files:**
- Create: `app/lib/ui/home/home_screen.dart`
- Create: `app/lib/ui/home/vpn_status_view.dart`
- Create: `app/lib/ui/home/vpn_connection_card.dart`
- Create: `app/lib/ui/home/recents_list.dart`
- Create: `app/lib/ui/home/world_map_atmosphere.dart`

- [ ] Implement `WorldMapAtmosphere` with top-aligned vector world map and dynamic radial gradient glow (red when disconnected, green when connected) starting flush at y=0.
- [ ] Implement `VpnStatusView` featuring dynamic padlock icon (disconnected red, spinning violet connecting indicator, neon cyan connected badge) and state labels.
- [ ] Implement `VpnConnectionCard` with country flag, server name, city, HTTP/3 protocol badge, Quick Connect / Disconnect button, and Change Server row.
- [ ] Implement `RecentsList` displaying recent locations (Netherlands, Germany, United States) with flags, ping latency, and load bars.
- [ ] Wire all buttons to `CoreController` for real connection lifecycle.

---

### Task 6: Countries Screen Implementation
**Files:**
- Create: `app/lib/ui/countries/countries_screen.dart`
- Create: `app/lib/ui/countries/country_item_row.dart`
- Create: `app/lib/ui/countries/country_search_bar.dart`

- [ ] Implement `CountriesScreen` with large bold `Countries` title and search icon in the top header.
- [ ] Implement horizontal filter chips row (`All`, `Secure Core`, `P2P`, `Tor`) with correct icons and active state switching.
- [ ] Add subtitle text `All countries (33)` without cluttering info badges.
- [ ] Implement `Fastest country` row at the top with turquoise lightning badge (`#1C9C7C`).
- [ ] Implement `CountryItemRow` for all 33 Fastly Edge countries from `firefox-vpn-client` (Argentina to United States), rendering real SVG flags, bold labels, and options menu.
- [ ] Implement live search filtering updating the country list in real time as user types.
- [ ] Wire country selection to update current server on Home and navigate back smoothly.

---

### Task 7: Profiles Screen & 50GB Multi-Account Rotation
**Files:**
- Create: `app/lib/ui/profiles/profiles_screen.dart`
- Create: `app/lib/ui/profiles/profile_card.dart`
- Create: `app/lib/ui/profiles/account_pool_card.dart`

- [ ] Implement `ProfilesScreen` featuring quick configuration profiles (Streaming US, Low Latency Gaming, Secure P2P Germany).
- [ ] Implement `AccountPoolCard` managing the 50GB/month multi-account rotation from `firefox-vpn-client` with "Add Account" and "Rotate Now" actions.
- [ ] Wire profile selection to apply proxy location and protocol configuration in `CoreController`.

---

### Task 8: Settings Screen & Features
**Files:**
- Create: `app/lib/ui/settings/settings_screen.dart`
- Create: `app/lib/ui/settings/settings_row.dart`
- Create: `app/lib/ui/settings/split_tunneling_screen.dart`

- [ ] Implement `SettingsScreen` matching Proton's sections:
  - **Account:** TeroVPN Unlimited Pass status.
  - **Features:** NetShield ad-blocker toggle, Kill Switch toggle, Split Tunneling.
  - **Connection:** Protocol selection (Smart / HTTP/3 QUIC / WireGuard MASQUE), VPN Accelerator.
  - **General:** Dark Theme, App Icon.
  - **Support:** Support Center, Report Issue, Debug Logs.
  - **App Info:** Version 1.0.0, Third-party licenses.
- [ ] Implement `SplitTunnelingScreen` allowing user to exclude installed apps from VPN routing using Android package manager query.

---

### Task 9: Sliding Dock Navigation & Shell
**Files:**
- Create: `app/lib/ui/shell/main_navigation_shell.dart`
- Create: `app/lib/ui/shell/proton_dock.dart`
- Create: `app/lib/ui/shell/dock_indicator_pill.dart`

- [ ] Implement `MainNavigationShell` with a horizontal `PageView` (physics: `BouncingScrollPhysics`) for seamless sliding transitions between Home, Countries, Profiles, and Settings.
- [ ] Implement `ProtonDock` with 4 navigation items (`Home`, `Countries`, `Profiles`, `Settings`) using Proton-style icons and labels.
- [ ] Implement `DockIndicatorPill` with animated horizontal slide (`Curves.easeOutCubic`) centered on the active tab's icon.
- [ ] Ensure edge-to-edge transparent system status bar and navigation bar integration (`SystemChrome.setEnabledSystemUIMode`).

---

### Task 10: Verification, Testing & Build Output
**Files:**
- Test: `app/test/widget_test.dart`
- Build Output: `out/TeroVPN-Android-debug.apk`

- [ ] Run `flutter analyze` and resolve any linter or typing warnings.
- [ ] Run unit and widget tests with `flutter test`.
- [ ] Build the Android debug APK using `flutter build apk --debug`.
- [ ] Verify that the APK installs and launches with full TeroVPN branding, 33 server locations, SVG flags, and working VPN connection mechanisms.
- [ ] Clean up temporary clone folders (`_firefox_vpn_client_temp`, `_protonvpn_temp`).
