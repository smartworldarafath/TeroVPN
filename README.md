# TeroVPN 🛡️

**Fast, Secure & Private VPN Client for Android**

TeroVPN combines high-throughput Fastly MASQUE HTTP/2 & HTTP/3 (QUIC) tunneling with the clean, modern design language of Proton VPN. Built with a native Go VPN core and a cross-platform Flutter frontend.

---

## ✨ Features

- **WireGuard MASQUE & HTTP/3 (QUIC) Tunneling**: Ultra-low latency and censorship-resistant encapsulation over Fastly's global edge network.
- **33 Global Edge Locations**: Direct routing across 33 countries (Argentina to United States) with automatic Anycast fastest-server selection.
- **Proton VPN Android Design System**: Built with Plus Jakarta Sans typography, deep `#12101E` dark mode, edge-to-edge status bar, dynamic atmospheric glow, and a sliding navigation dock.
- **50GB Multi-Account Session Rotation Pool**: Automatic rotating sessions to sustain high-speed bandwidth without manual token juggling.
- **Split Tunneling**: Granular per-app routing to bypass or enforce VPN tunnels on specific Android applications.
- **Security & Privacy**: Built-in NetShield ad-blocker, Kill Switch protection, and zero-logs architecture.

---

## 📱 Screenshots & Design

- **Home**: Real-time atmospheric glow, dynamic security lock, server connection card with quick connect/disconnect, and recent server history.
- **Countries**: 33 Fastly edge countries with vector flags, search filtering, server load indicators, and specialized filter chips (`All`, `Secure Core`, `P2P`, `Tor`).
- **Profiles**: Fast presets for 4K Streaming (US East), Low Latency Gaming (Amsterdam IX), and Secure P2P (Frankfurt), alongside live account pool rotation controls.
- **Settings**: Split tunneling, NetShield, Kill Switch, and connection protocol selectors.

---

## 📥 Download

Download the latest Android APK from the [Releases](https://github.com/smartworldarafath/TeroVPN/releases) section.

```powershell
adb install -r TeroVPN-Android-debug.apk
```

---

## 🛠️ Building from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.47+ recommended)
- [Android SDK](https://developer.android.com/studio) (API 34+ / 36)
- Java JDK 17 or 21

### Build Steps

1. Clone repository:
   ```bash
   git clone https://github.com/smartworldarafath/TeroVPN.git
   cd TeroVPN/app
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Build Android debug APK:
   ```bash
   flutter build apk --debug
   ```

The compiled APK will be output to `app/build/app/outputs/flutter-apk/app-debug.apk`.

---

## 📄 License

GPL-3.0 License. See [LICENSE](LICENSE) for details.
