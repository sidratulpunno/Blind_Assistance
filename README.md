# 🦯 Blind Assistance Flutter App

A smart Flutter application designed to assist visually impaired individuals with real-time
navigation and scene understanding using speech input, AI-based image analysis (Google Gemini), and
offline object detection (TensorFlow Lite).

---

##App Screenshot
![App Screenshot](https://github.com/sidratulpunno/Blind_Assistance/blob/main/assets/images/app%20screenshot.png?raw=true)

## ✨ Features

### 🔊 Speech-Based Mode Selection

The app listens for voice commands using a speech-to-text engine and supports the following
commands:

- `give direction` → AI-based step-by-step navigation.
- `describe` → Describe the surroundings using AI.
- `offline direction` → Offline navigation using object detection.
- `stop direction` → Stops all processing.

---

### 🧭 Navigation Mode (Offline)

- Uses **TensorFlow Lite** and **MobileNet SSD** to detect objects in real time.
- Captures continuous camera frames using the `camera` package.
- Uses `google_mlkit_commons` for efficient object detection.
- Speaks detected objects using `flutter_tts`.
- Warns the user if objects are too close.

---

### 🌐 Give Direction Mode (Online AI)

- Takes a photo every second using the `camera` package.
- Sends images to **Google Gemini** via the `google_generative_ai` package.
- Gemini responds with step-by-step walking directions and obstacle warnings.
- Instructions are read aloud using `flutter_tts`.

---

### 📝 Description Mode

- Captures the scene (like in direction mode).
- Sends images to **Gemini** and receives a full description of the surroundings.
- The response is narrated using `flutter_tts`.

---

## 🧠 AI Training (for Better Accuracy)

- Trained a custom Gemini model in **Google AI Studio**.
- Used 100 frequently encountered real-world images to improve output precision and context
  awareness.

---

## 📦 Packages Used

| Purpose               | Package                                  |
|-----------------------|------------------------------------------|
| Voice Commands        | `speech_to_text`                         |
| Text-to-Speech        | `flutter_tts`                            |
| Camera Access         | `camera`                                 |
| Object Detection (ML) | `google_mlkit_commons`, `tflite_flutter` |
| AI-Based Response     | `google_generative_ai`                   |
| File & Path Handling  | `path`, `path_provider`, `cross_file`    |
| Local Storage         | `shared_preferences`                     |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed
- Android/iOS device or emulator
- API keys for Gemini (Google AI Studio)

### Installation

```bash
git clone https://github.com/sidratulpunno/Blind_Assistance_Flutter.git
cd Blind_Assistance_Flutter
flutter pub get
flutter run
