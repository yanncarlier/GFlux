# Project Story: GFlux 🌌

## Inspiration
GFlux was born from a simple question: *What if an AI didn't feel like a chatbot, but like a fluid extension of our own thoughts?* Most voice assistants today are "stuttery"—they listen, wait, process, and then speak. We wanted to build something that felt like **flux**: a continuous, bidirectional stream of intelligence. Inspired by the "flow state" in creative work, GFlux aims to be an agent that disappears into the background while remaining instantly accessible.

## What it does
GFlux is a premium multimodal AI agent that provides real-time, bidirectional voice interactions. Key features include:
- **Low-Latency Voice Interaction**: Users can speak naturally to Gemini, and the agent responds in real-time without traditional "turn-based" delays.
- **Multimodal Flexibility**: While focused on audio, GFlux is built to handle text and future vision inputs natively.
- **Adaptive UI**: A minimal, high-aesthetic interface that pulses and glows in sync with the agent's state, providing intuitive visual feedback.

## How we built it
The core of GFlux is built on the **Flutter** framework for fluid 60fps performance on mobile. The "brain" is powered by the **Gemini Multimodal Live API** via a stateful WebSocket connection.

To handle real-time audio on hardware, we implemented a custom audio pipeline:
- **Input**: Captured at 16kHz Mono PCM 16-bit using the `record` package.
- **Output**: Handled via `flutter_sound`, processing 24kHz Mono PCM chunks received over the WebSocket.
- **Latency Logic**: We used a sequential buffering strategy. The duration $d$ of each audio chunk is calculated to ensure perfect timing:
  $$d = \frac{L}{r \cdot b \cdot c}$$
  Where:
  - $L$ = Length of the byte buffer
  - $r$ = Sample rate (24,000 Hz)
  - $b$ = Bytes per sample (2 for 16-bit)
  - $c$ = Number of channels (1 for Mono)

## Challenges we ran into
Building for "Live" interaction meant we couldn't hide behind loading spinners.
1. **Audio Race Conditions**: Initially, incoming audio chunks would "overlap," causing the player to crash or skip on real hardware. We solved this by building a custom **Sequential Playback Queue** that manages the timing between chunks with millisecond precision.
2. **WebSocket Handshakes**: Configuring the initial handshake for `AUDIO` response modalities required precise JSON structures that differed slightly from standard REST APIs.
3. **Hardware Stability**: Testing on real Android hardware (Samsung SM A326B) revealed ADB stability issues and permission hurdles that aren't present in emulators, requiring a more robust service-based architecture.

## Accomplishments that we're proud of
- **Stable Hardware Deployment**: Moving the project from an emulator to real hardware while maintaining high-fidelity audio.
- **The Queue System**: Developing a non-blocking playback queue that manages real-time PCM data without stuttering.
- **Zero-Secret Repo**: Successfully implementing a secure `.env` and `.gitignore` structure to ensure the project is open-source ready without exposing private API keys.

## What we learned
We delved deep into the mechanics of **Digital Signal Processing (DSP)** and WebSocket states. We learned that "Real-Time" is as much about managing the *user's perception* of time (via UI animations) as it is about the raw speed of the model. We also gained a massive appreciation for the nuance of PCM byte alignment in raw audio streams.

## What's next for GFlux
The current version of GFlux is just the foundation. Our roadmap includes:
- **Vision Integration**: Enabling the camera to allow Gemini to "see" the user's world in real-time.
- **Reactive Waveforms**: Implementing a custom painter to visualize voice frequencies using Fast Fourier Transforms (FFT).
- **Cloud Run Hosting**: Moving the transient state management to a Google Cloud Run backend for multi-user session persistence.
- **Haptic Harmony**: Adding subtle haptic pulses that match the cadence of Gemini's voice.

---
*GFlux: Intelligence in motion.*
