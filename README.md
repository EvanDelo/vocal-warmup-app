# 🎵 Vocal Warmup

An offline-first, pure algorithmic piano vocal accompaniment and warmup web application built with Flutter and the Web Audio API.

Designed for vocalists, choir directors, and voice teachers who need a fast, responsive, and customizable pitch reference and warmup companion.

---

## ✨ Features

- **🎹 100% Algorithmic Piano Synthesis:**
  - Zero external MP3 or audio asset downloads.
  - Phase-aligned harmonic wave synthesis with smooth cosine-easing attack (eliminates clicks and blips).
  - Web Audio API hardware buffers running at 44.1 kHz with zero-latency playback.

- **⏱️ Precision Metronome & Articulation:**
  - Tempo control from **40 to 240 BPM**.
  - **Legato** (full sustain) and **Staccato** (percussive 35% gate) articulation modes.
  - Beat-proportional whole-note sustains for held top notes.

- **🎼 Classical & Contemporary Vocal Patterns:**
  - **5-Tone Scale:** `1 - 2 - 3 - 4 - 5 - 4 - 3 - 2 - 1`
  - **Octave Repeat:** `1 - 3 - 5 - 8 - 8 - 8 - 8 - 5 - 3 - 1`
  - **Octave Repeat (Sustained Top):** `1 - 3 - 5 - 8 - 8 - 8 - 8s - 5 - 3 - 1` *(4-beat whole note sustain at the peak)*
  - **Octave Repeat Descending:** `8 - 8 - 8 - 8 - 5 - 3 - 1`
  - **Octave and a Half (Bel Canto):** `1 - 3 - 5 - 8 - 10 - 12 - 11 - 9 - 7 - 5 - 4 - 2 - 1`
  - **Major Triad Arpeggio:** `1 - 3 - 5 - 8 - 5 - 3 - 1`
  - **Octave Jump:** `1 - 8 - 1`
  - **Descending 5-Tone:** `5 - 4 - 3 - 2 - 1`
  - **3-Tone Step:** `1 - 2 - 3 - 2 - 1`

- **🎙️ Voice Range Presets & Intelligent Peak Pitch Limiting:**
  - Standard voice classifications: **Bass**, **Baritone**, **Tenor**, **Alto**, **Mezzo**, **Soprano**, or **Custom**.
  - **Peak Sung Note Boundary:** The upper limit governs the highest note reached in any exercise pattern rather than just the starting root key.
  - **Auto-Reverse Mode:** Automatically steps up semitone by semitone, reverses at the top limit, and descends back down to the starting pitch.

- **🎹 4-Octave Interactive Visual Keybed:**
  - C2 to C6 interactive ivory and ebony piano keys with crimson felt detailing.
  - Tap any key on screen to immediately audition pitch.
  - Smooth camera auto-centering keeps the active pitch in view as exercises ascend and descend.

---

## 📱 Use on iPhone / iPad (Add to Home Screen)

This application is configured as a standalone **Progressive Web App (PWA)**:

1. Open your hosted GitHub Pages URL in **Safari** on your iOS device.
2. Tap the **Share** button (the square icon with the arrow pointing upward).
3. Scroll down and tap **"Add to Home Screen"**.
4. Tap **Add** in the top right corner.

The app will appear on your home screen and run full-screen without Safari browser bars, with sound synthesis working completely offline.

---

## 🚀 Local Development

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13.0 or later)
- Google Chrome or any modern web browser

### Running Locally
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/vocal-warmup.git
cd vocal-warmup

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

---

## 🌐 Automatic Deployment (GitHub Pages)

This repository includes a GitHub Actions workflow located at [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

To publish:
1. Push this repository to GitHub.
2. In your GitHub repository, navigate to **Settings** → **Pages**.
3. Under **Build and deployment** → **Source**, select **GitHub Actions**.
4. GitHub will automatically build and publish the web app to `https://<YOUR_USERNAME>.github.io/<REPO_NAME>/`.

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
