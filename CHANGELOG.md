# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### chat.ps1

- v1.0.1: General update and version bump.
  - Added or enhanced script versioning metadata.
  - Improved self-update and script validation logic:
    - Added `Test-ScriptValidity` function for validating downloaded updates:
      - Checks for file presence and non-emptiness.
      - Performs basic PowerShell syntax validation using the parser.
      - Verifies updated script version is newer before allowing replacement.
      - Prints clear error messages for invalid or old script downloads.
  - Improved `Check-ForUpdate` function and commit retrieval logic.
  - Expanded and clarified script introduction and about section.
  - Ongoing code and comment improvements for clarity and maintainability.

### README.md

- Added license badges: MIT, GPLv3, and PowerShell 7+ compatibility.
- Expanded feature list:
  - **Text-to-Speech (TTS):** Voice output using Windows SAPI.
  - **Image Generation:** Create images from text prompts.
  - **Secure Configuration:** API keys and config stored securely.
  - **Persona Management:** Manage multiple AI personas and conversation histories.
  - **Auto-Update:** One-command update to pull the latest script version.
- Clarified requirements and setup instructions:
  - **Requirements:** Windows 10/11, PowerShell 7.0+ (recommended), xAI API key, internet connection.
  - Improved "Getting Started" section and code samples.
  - Documented new commands: history management, persona management, model switching, TTS options, image generation, and update mechanisms.
- Noted configuration and log file storage locations.

---

For more details and a complete commit history, see:  
https://github.com/GingerDev0/Grok/commits?sort=updated&direction=desc
