[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)


# Grok AI Chat (PowerShell)

A feature-rich PowerShell interface for interacting with xAI’s Grok models, supporting customizable personas, TTS, image generation, and seamless auto-updates.

---

## Features

- **Customizable AI Personas** – Tailor your chat experience with editable, unique personalities.
- **Text-to-Speech (TTS)** – Voice output using Windows SAPI voices.
- **Image Generation** – Create images from text prompts using xAI image APIs.
- **Auto-Update** – One-command update pulls the latest script version from GitHub.
- **Secure Configuration** – API keys and config stored securely (using DPAPI).
- **Conversation History** – Logs are kept per persona and can be easily cleared.

---

## Requirements

- **Windows 10/11**
- **PowerShell 5.1+**
- **Internet connection**
- **xAI API key**

---

## Getting Started

1. **Clone the Repository**
    ```powershell
    git clone https://github.com/GingerDev0/Grok.git
    cd Grok
    ```

2. **Run the Script**
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\chat.ps1
    ```
    The script will guide you through initial setup (username, API key, persona/model selection).

---

## Usage

- **Start Chat** – Conversate with the AI using the selected persona and model.
- **Clear History** – Remove all conversation logs.
- **Select/Manage Personas** – Add, remove, or edit personas via menu or by editing `personas.json`.
- **Change Model** – Switch between available Grok models.
- **TTS Options** – Enable/disable TTS and choose from installed voices.
- **Image Generation** – Create and view AI-generated images from text prompts.
- **Update Script** – Get notified and auto-update to the latest version from GitHub.

Configuration and logs are stored in local files:  
- `config.json` – Settings and API key (encrypted)  
- `personas.json` – Persona definitions  
- `/logs` – Conversation logs  
- `/images` – Generated images

---

## Security

- API keys are encrypted with Windows DPAPI.
- You can update or remove your API key at any time from the settings menu.

---

## Customization

- **Personas** – Use the in-script menu or edit `personas.json` to add new personalities.
- **Models** – Choose from supported xAI Grok models.
- **Voices** – Any installed Windows SAPI voice is available for TTS.

---

## Troubleshooting

- **No Internet**: The script will notify you and exit.
- **TTS Issues**: Ensure you have SAPI voices installed.
- **API Errors**: Double-check your xAI API key and internet connection.

---

## License

MIT License

---

## Credits

- [xAI Grok API](https://x.ai/)
- Script by [GingerDev0](https://github.com/GingerDev0)

---

Enjoy chatting with Grok!
