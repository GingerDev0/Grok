# PowerShell AI Chat Interface

![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful, feature-rich PowerShell script that provides a command-line interface for interacting with the x.ai API (Grok). It includes robust features like automatic updates, persona management, model selection, secure key storage, text-to-speech (TTS), and image generation, all within a user-friendly, interactive menu.

## Features

-   **Automatic Updates**: The script automatically checks for new versions on GitHub and prompts you to update, ensuring you always have the latest features.
-   **Secure API Key Storage**: All configuration, including your encrypted API key, is stored securely in a single `config.json` file using the Windows Data Protection API (DPAPI).
-   **Model Selection**: Easily switch between different available Grok models (`grok-3`, `grok-3-mini`, etc.).
-   **Persona Management**:
    -   Create and save custom system prompts as named "personas".
    -   Select from a list of saved personas to start a chat.
    -   Add, remove, and modify personas through a dedicated management menu.
-   **Conversation Logging**: Chat history for each persona is automatically saved to a text file in the `logs` directory.
-   **Text-to-Speech (TTS)**: Enable or disable TTS to have the AI's responses read aloud using native Windows voices.
-   **Image Generation**: Generate images from text prompts using the `grok-2-image` model.
-   **User-Friendly Menu**: A colorful, well-organized menu for easy navigation and configuration.
-   **Centralized Configuration**: All settings and personas are stored in easy-to-read `json` files.
-   **Initial Setup Wizard**: A guided setup process on the first run to configure your username, API key, and initial settings.

## Prerequisites

-   Windows operating system
-   PowerShell 5.1 or later
-   An API key from **x.ai**.

## Installation & Setup

1.  **Download the script**: Place the `chat.ps1` script in a dedicated folder.
2.  **Run the script**: Open a PowerShell terminal, navigate to the script's directory, and run it:
    ```powershell
    .\chat.ps1
    ```
3.  **First-Time Setup**:
    -   The script will detect that it's the first run and guide you through a detailed setup process.
    -   **Configuration Migration**: If you used a previous version of the script, it will automatically migrate your old `username.dat` and `apikey.dat` settings into the new `config.json` file.
    -   You will be prompted to enter your **API Key** and **username**.
    -   You can configure the AI model, select a starting persona, and enable/disable TTS.

## Usage

Run the script from your PowerShell terminal. You will be greeted with the main menu.

```powershell
.\chat.ps1
```

### Main Menu

The main menu provides access to all the script's features:

-   **Start Chat**: Begin a conversation with the currently selected persona. Inside the chat, type `menu` to return to the main menu or `exit` to close the script.
-   **Clear History**: Permanently delete all conversation log files from the `logs` directory.
-   **Select Persona**: Choose a persona for your next chat from a list of saved personas.
-   **Manage Personas**: Add, remove, or modify existing personas.
-   **Select Model**: Change the AI model used for generating responses.
-   **Toggle TTS**: Enable or disable Text-to-Speech for AI replies.
-   **Change TTS Voice**: Select a different installed Windows voice for TTS.
-   **Change User Name**: Update the username stored in `config.json`.
-   **Change API Key**: Update and save a new encrypted API key in `config.json`.
-   **Generate Image**: Enter the image generation menu to create an image from a text prompt.

## File Structure

The script will create and manage the following files and directories in its location:

-   `chat.ps1`: The main executable script.
-   **`config.json`**: A single file that stores all your settings, including the current model, persona, TTS status, username, and encrypted API key.
    ```json
    {
        "currentModel": "grok-3",
        "ttsEnabled": false,
        "currentVoice": "Microsoft David Desktop",
        "currentPersona": {
            "name": "Agent",
            "prompt": "You are a helpful AI agent. You are called Agent. Your user is called User."
        },
        "commitSha": "latest_commit_hash_here",
        "username": "YourUsername",
        "apiKey": "your_encrypted_api_key_here"
    }
    ```
-   **`personas.json`**: Stores the list of all your custom personas and their system prompts.
    ```json
    [
      {
        "name": "Agent",
        "prompt": "You are a helpful AI agent. You are called Agent. Your user is called User."
      },
      {
        "name": "Code Helper",
        "prompt": "You are an expert programmer who provides clear, concise code examples."
      }
    ]
    ```
-   **`/logs/`**: A directory where conversation history files are stored. Each persona gets its own `.txt` log file.
-   **`/images/`**: A directory where generated images are saved.

## License

This project is licensed under the GPL-3.0 license & The MIT License.
