Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# === Script Version ===
$scriptVersion = "1.0.0"

# === TTS Setup ===
Add-Type -AssemblyName System.Speech
$speechSynthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

# === Config and Persona Files ===
$configFile = "config.json"
$personasFile = "personas.json"

# === Image Directory ===
$imageDir = "images"
if (-not (Test-Path $imageDir)) {
    New-Item -ItemType Directory -Path $imageDir | Out-Null
}

function Check-ForUpdate {
    $config = Get-Config
    $repoApiUrl = "https://api.github.com/repos/GingerDev0/Grok/commits?path=chat.ps1"
    try {
        $headers = @{
            "Accept" = "application/vnd.github.v3+json"
            "User-Agent" = "PowerShell-Script-Updater"
        }
        $commits = Invoke-RestMethod -Uri $repoApiUrl -Headers $headers -Method Get -TimeoutSec 10
        if ($commits -and $commits.Count -gt 0) {
            $latestCommitSha = $commits[0].sha
            if ($config.commitSha -eq "initial" -or $config.commitSha -ne $latestCommitSha) {
                Write-Host "A new version of the script is available (Commit: $latestCommitSha)." -ForegroundColor Cyan
                $choice = Read-Host "Would you like to update? (y/n)"
                if ($choice.ToLower() -eq 'y') {
                    Update-Script -commitSha $latestCommitSha
                }
                else {
                    Write-Host "Update skipped." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Script is up to date." -ForegroundColor Green
            }
        }
        else {
            Write-Host "No commits found in the repository." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error checking for updates: $_" -ForegroundColor Red
    }
}

function Update-Script {
    param([string]$commitSha)
    $scriptUrl = "https://raw.githubusercontent.com/GingerDev0/Grok/main/chat.ps1"
    $tempScriptPath = Join-Path $env:TEMP "chat_temp.ps1"
    try {
        Invoke-WebRequest -Uri $scriptUrl -OutFile $tempScriptPath
        # Update the commit SHA in config.json
        $config = Get-Config
        $config.commitSha = $commitSha
        Save-Config $config
        # Replace the current script
        $currentScriptPath = $PSCommandPath
        Move-Item -Path $tempScriptPath -Destination $currentScriptPath -Force
        Write-Host "Script updated successfully to commit $commitSha. Please restart the script." -ForegroundColor Green
        Read-Host "Press Enter to exit..."
        exit
    }
    catch {
        Write-Host "Error updating script: $_" -ForegroundColor Red
        if (Test-Path $tempScriptPath) {
            Remove-Item $tempScriptPath -Force
        }
    }
}

function Get-Config {
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
            # Ensure commitSha exists
            if (-not $config.PSObject.Properties.Name -contains "commitSha") {
                $config | Add-Member -MemberType NoteProperty -Name commitSha -Value "initial"
            }
            return $config
        }
        catch {
            Write-Host "Failed to read config file. Using default settings." -ForegroundColor Yellow
            return @{
                currentModel = "grok-3"
                ttsEnabled = $false
                currentVoice = $null
                currentPersona = $null
                commitSha = "initial"
            }
        }
    }
    else {
        return @{
            currentModel = "grok-3"
            ttsEnabled = $false
            currentVoice = $null
            currentPersona = $null
            commitSha = "initial"
        }
    }
}

function Save-Config {
    param($config)
    $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configFile -Encoding UTF8
}

function Get-Personas {
    if (Test-Path $personasFile) {
        try {
            $personas = Get-Content $personasFile -Raw | ConvertFrom-Json
            return $personas
        }
        catch {
            Write-Host "Failed to read personas file. Using default personas." -ForegroundColor Yellow
            return Get-DefaultPersonas
        }
    }
    else {
        return Get-DefaultPersonas
    }
}

function Save-Personas {
    param($personas)
    $personas | ConvertTo-Json -Depth 3 | Set-Content -Path $personasFile -Encoding UTF8
}

function Get-DefaultPersonas {
    return @(
        @{ name = "Agent"; prompt = "You are a helpful AI agent. You are called Agent. Your user is called $userName." }
    )
}

function Run-Setup {
    Clear-Host
    Write-Host "=== Initial Setup ===" -ForegroundColor Cyan
    Write-Host "Welcome to the AI Chat setup. Let's configure your settings.`n"

    # Configure Username
    $userName = Read-Host "Please enter your name"
    if ([string]::IsNullOrWhiteSpace($userName)) {
        $userName = "User"
        Write-Host "No name provided. Using default name 'User'." -ForegroundColor Yellow
    }
    Set-Content -Path $userFile -Value $userName -Encoding UTF8 -NoNewline

    # Initialize Personas
    if (-not (Test-Path $personasFile)) {
        $personas = Get-DefaultPersonas
        Save-Personas $personas
        Write-Host "Default personas initialized in personas.json." -ForegroundColor Green
    }

    # Configure Model
    $selectedModel = Show-ModelMenu
    if (-not $selectedModel) {
        $selectedModel = "grok-3"
        Write-Host "No model selected. Using default model 'grok-3'." -ForegroundColor Yellow
    }

    # Configure Persona
    $selectedPersona = Show-PersonaMenu
    if (-not $selectedPersona) {
        $selectedPersona = $null
        Write-Host "No persona selected." -ForegroundColor Yellow
    }

    # Configure TTS
    $ttsChoice = Read-Host "`nEnable Text-to-Speech (TTS)? (y/n)"
    $ttsEnabled = $ttsChoice.ToLower() -eq 'y'

    # Configure TTS Voice
    $currentVoice = $null
    if ($ttsEnabled) {
        $currentVoice = Show-VoiceMenu
        if (-not $currentVoice) {
            $voices = $speechSynthesizer.GetInstalledVoices() | Where-Object { $_.Enabled } | Select-Object -ExpandProperty VoiceInfo
            if ($voices.Count -gt 0) {
                $currentVoice = $voices[0].name
                Write-Host "No voice selected. Using default voice '$currentVoice'." -ForegroundColor Yellow
            }
            else {
                $ttsEnabled = $false
                Write-Host "No TTS voices available. Disabling TTS." -ForegroundColor Yellow
            }
        }
    }

    $config = @{
        currentModel = $selectedModel
        ttsEnabled = $ttsEnabled
        currentVoice = $currentVoice
        currentPersona = $selectedPersona
        commitSha = "initial"
    }
    Save-Config $config
    Write-Host "`nSetup complete! Configuration saved." -ForegroundColor Green
    Read-Host "Press Enter to continue..."
    return $userName
}

function Speak-Text {
    param([string]$text)
    $config = Get-Config
    if ($config.ttsEnabled) {
        try {
            if ($config.currentVoice) {
                $speechSynthesizer.SelectVoice($config.currentVoice)
            }
            $speechSynthesizer.SpeakAsync($text) | Out-Null
        }
        catch {
            Write-Host "TTS error: $_" -ForegroundColor Red
        }
    }
}

function Show-VoiceMenu {
    Clear-Host
    Write-Host "=== TTS Voice Selection ===" -ForegroundColor Cyan
    $voices = $speechSynthesizer.GetInstalledVoices() | Where-Object { $_.Enabled } | Select-Object -ExpandProperty VoiceInfo
    if ($voices.Count -eq 0) {
        Write-Host "No TTS voices installed on this system." -ForegroundColor Red
        Read-Host "Press Enter to return to the main menu"
        return $null
    }

    Write-Host "Available voices:"
    for ($i = 0; $i -lt $voices.Count; $i++) {
        Write-Host "$($i + 1). $($voices[$i].name) ($($voices[$i].Culture))"
    }
    Write-Host "$($voices.Count + 1). Back to Main Menu"
    
    $choice = Read-Host "`nChoose a voice (1-$($voices.Count + 1))"
    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $voices.Count) {
        return $voices[$choice - 1].name
    }
    elseif ($choice -eq ($voices.Count + 1)) {
        return $null
    }
    else {
        Write-Host "Invalid choice." -ForegroundColor Red
        Read-Host "Press Enter to try again..."
        return Show-VoiceMenu
    }
}

# === Model Selection ===
function Get-AvailableModels {
    return @("grok-3", "grok-3-mini", "grok-3-fast", "grok-3-mini-fast", "grok-2-1212")
}

function Show-ModelMenu {
    Clear-Host
    $config = Get-Config
    Write-Host "=== Model Selection ===" -ForegroundColor Cyan
    $models = Get-AvailableModels
    if ($models.Count -eq 0) {
        Write-Host "No text models available. Using default model." -ForegroundColor Red
        Read-Host "Press Enter to return to the main menu"
        return $config.currentModel
    }

    Write-Host "Available text models:"
    for ($i = 0; $i -lt $models.Count; $i++) {
        Write-Host "$($i + 1). $($models[$i])" -ForegroundColor ($models[$i] -eq $config.currentModel ? 'Green' : 'White')
    }
    Write-Host "$($models.Count + 1). Back to Main Menu"
    
    $choice = Read-Host "`nChoose a model (1-$($models.Count + 1))"
    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $models.Count) {
        return $models[$choice - 1]
    }
    elseif ($choice -eq ($models.Count + 1)) {
        return $config.currentModel
    }
    else {
        Write-Host "Invalid choice." -ForegroundColor Red
        Read-Host "Press Enter to try again..."
        return Show-ModelMenu
    }
}

# === Image Generation ===
function Generate-Image {
    param($prompt)
    $imageApiUrl = "https://api.x.ai/v1/images/generations"
    $body = @{
        model = "grok-2-image"
        prompt = $prompt
    } | ConvertTo-Json -Depth 3
    try {
        $response = Invoke-RestMethod -Uri $imageApiUrl -Headers $headers -Method Post -Body $body -TimeoutSec 60
        $imageUrl = $response.data[0].url
        $imageName = "image_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        $imagePath = Join-Path $imageDir $imageName
        Invoke-WebRequest -Uri $imageUrl -OutFile $imagePath
        Write-Host "Image generated and saved to $imagePath" -ForegroundColor Green
        return $imagePath
    }
    catch {
        Write-Host "Error generating image: $_" -ForegroundColor Red
        return $null
    }
}

function Show-ImageGenerationMenu {
    Clear-Host
    Write-Host "=== Image Generation ===" -ForegroundColor Cyan
    while ($true) {
        Write-Host "Enter a description for the image you want to generate."
        Write-Host "Type 'cancel' to return to the main menu.`n"
        $prompt = Read-Host "Image description"
        if ($prompt.ToLower() -eq "cancel") {
            return
        }
        elseif ([string]::IsNullOrWhiteSpace($prompt)) {
            Write-Host "No description provided." -ForegroundColor Yellow
            Read-Host "Press Enter to try again..."
            continue
        }
        $imagePath = Generate-Image -prompt $prompt
        if ($imagePath) {
            while ($true) {
                Clear-Host
                Write-Host "=== Image Generation Options ===" -ForegroundColor Cyan
                Write-Host "Image saved at: $imagePath" -ForegroundColor Green
                Write-Host "`n1. View Image"
                Write-Host "2. Generate New Image"
                Write-Host "3. Return to Main Menu"
                $choice = Read-Host "`nChoose an option (1-3)"
                switch ($choice) {
                    "1" {
                        try {
                            Start-Process $imagePath
                        }
                        catch {
                            Write-Host "Error opening image: $_" -ForegroundColor Red
                        }
                        Read-Host "Press Enter to continue..."
                    }
                    "2" { break }
                    "3" { return }
                    default {
                        Write-Host "Invalid choice." -ForegroundColor Red
                        Read-Host "Press Enter to try again..."
                    }
                }
            }
        }
        else {
            Read-Host "Press Enter to try again..."
        }
    }
}

# === Encryption using DPAPI ===
function Encrypt-DPAPI {
    param([string]$plainText)
    $bytes = [Text.Encoding]::UTF8.GetBytes($plainText)
    $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [Convert]::ToBase64String($encryptedBytes)
}

function Decrypt-DPAPI {
    param([string]$encryptedText)
    $encryptedBytes = [Convert]::FromBase64String($encryptedText)
    $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encryptedBytes,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [Text.Encoding]::UTF8.GetString($decryptedBytes)
}

# === Config & Paths ===
$apiFile = "apikey.dat"
$userFile = "username.dat"
$apiUrl = "https://api.x.ai/v1/chat/completions"
$logDir = "logs"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Test-ApiKey($key) {
    $config = Get-Config
    $headersTest = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $key"
    }
    $testBody = @{
        model = $config.currentModel
        messages = @(@{ role="system"; content="test" })
        temperature = 0
        stream = $false
    } | ConvertTo-Json -Depth 3

    try {
        Invoke-RestMethod -Uri $apiUrl -Headers $headersTest -Method Post -Body $testBody -TimeoutSec 10
        return $true
    }
    catch {
        return $false
    }
}

function Get-ApiKey {
    if (-not (Test-Path $apiFile)) {
        do {
            $key = Read-Host "Enter your API key"
            if (Test-ApiKey $key) {
                Write-Host "API key accepted." -ForegroundColor Green
                $encKeyStr = Encrypt-DPAPI $key
                Set-Content -Path $apiFile -Value $encKeyStr -Encoding ASCII -NoNewline
                return $key
            }
            else {
                Write-Host "Invalid API key or network error. Please try again." -ForegroundColor Red
            }
        } until ($false)
    }
    else {
        try {
            $encKeyStr = Get-Content -Path $apiFile -Raw
            return Decrypt-DPAPI $encKeyStr
        }
        catch {
            Write-Host "Failed to decrypt API key file, please enter your API key again." -ForegroundColor Yellow
            Remove-Item $apiFile -Force
            return Get-ApiKey
        }
    }
}

function Get-UserName {
    if (-not (Test-Path $userFile)) {
        return $null
    }
    else {
        return Get-Content -Path $userFile -Raw
    }
}

function Save-UserName($name) {
    Set-Content -Path $userFile -Value $name -Encoding UTF8 -NoNewline
}

function Save-ApiKey($key) {
    $encKeyStr = Encrypt-DPAPI $key
    Set-Content -Path $apiFile -Value $encKeyStr -Encoding ASCII -NoNewline
}

function Show-MainMenu {
    Clear-Host
    $config = Get-Config
    Write-Host "┌────────────────────────── AI Chat Interface ──────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ Welcome, $userName!" -ForegroundColor White
    Write-Host "├─ Current Settings ────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ Persona: $($config.currentPersona ? $config.currentPersona.name : 'None')" -ForegroundColor Green
    Write-Host "│ Model:   $($config.currentModel)" -ForegroundColor Green
    Write-Host "│ TTS:     $($config.ttsEnabled ? 'Enabled' : 'Disabled') ($($config.currentVoice ? $config.currentVoice : 'Default'))" -ForegroundColor Green
    Write-Host "├─ Menu Options ────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    
    $menuOptions = @(
        @{ Number = "1"; Category = "Chat"; Name = "Start Chat"; Description = "Begin conversation with selected persona"; Color = "Yellow" },
        @{ Number = "2"; Category = "Chat"; Name = "Clear History"; Description = "Delete all conversation logs"; Color = "Yellow" },
        @{ Number = "3"; Category = "Personas"; Name = "Select Persona"; Description = "Choose or create a persona"; Color = "Magenta" },
        @{ Number = "4"; Category = "Personas"; Name = "Manage Personas"; Description = "Add, remove, or modify personas"; Color = "Magenta" },
        @{ Number = "5"; Category = "Settings"; Name = "Select Model"; Description = "Change the AI model"; Color = "White" },
        @{ Number = "6"; Category = "Settings"; Name = "Toggle TTS"; Description = "Enable/disable text-to-speech"; Color = "White" },
        @{ Number = "7"; Category = "Settings"; Name = "Change TTS Voice"; Description = "Select a different TTS voice"; Color = "White" },
        @{ Number = "8"; Category = "Settings"; Name = "Change User Name"; Description = "Update your username"; Color = "White" },
        @{ Number = "9"; Category = "Settings"; Name = "Change API Key"; Description = "Update your API key"; Color = "White" },
        @{ Number = "10"; Category = "Image"; Name = "Generate Image"; Description = "Create an image from a text description"; Color = "Cyan" }
    )

    $currentCategory = ""
    foreach ($option in $menuOptions) {
        if ($option.Category -ne $currentCategory) {
            Write-Host "│ $($option.Category):" -ForegroundColor Cyan
            $currentCategory = $option.Category
        }
        Write-Host "│  $($option.Number). $($option.Name.PadRight(20)) - $($option.Description)" -ForegroundColor $option.Color
    }
    
    Write-Host "└───────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    $choice = Read-Host "`nEnter your choice (1-10)"

    switch ($choice) {
        "1" {
            if ($config.currentPersona) {
                return @{ action = "chat" }
            } else {
                Write-Host "`nNo persona selected. Redirecting to the persona selection menu." -ForegroundColor Yellow
                Read-Host "Press Enter to continue..."
                return @{ action = "selectPersona" }
            }
        }
        "2" { return @{ action = "clear" } }
        "3" { return @{ action = "selectPersona" } }
        "4" { return @{ action = "managePersonas" } }
        "5" { return @{ action = "selectModel" } }
        "6" {
            $config = Get-Config
            $config.ttsEnabled = -not $config.ttsEnabled
            Save-Config $config
            Write-Host "TTS is now $($config.ttsEnabled ? 'enabled' : 'disabled')." -ForegroundColor Magenta
            Read-Host "Press Enter to return to menu"
            return @{ action = "menu" }
        }
        "7" {
            $selectedVoice = Show-VoiceMenu
            if ($selectedVoice) {
                $config = Get-Config
                $config.currentVoice = $selectedVoice
                Save-Config $config
                Write-Host "Voice changed to $selectedVoice" -ForegroundColor Green
            }
            Read-Host "Press Enter to return to menu"
            return @{ action = "menu" }
        }
        "8" { return @{ action = "changeName" } }
        "9" { return @{ action = "changeKey" } }
        "10" { return @{ action = "generateImage" } }
        default {
            Write-Host "Invalid choice." -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            return @{ action = "menu" }
        }
    }
}

function Show-PersonaMenu {
    Clear-Host
    Write-Host "Hello, $userName!`n`n=== AI Chat Persona Menu ====" -ForegroundColor Cyan
    $personas = Get-Personas
    for ($i = 0; $i -lt $personas.Count; $i++) {
        Write-Host "$($i + 1). $($personas[$i].name)"
    }
    Write-Host "$($personas.Count + 1). Custom Persona"
    Write-Host "$($personas.Count + 2). Back to Main Menu"
    $choice = Read-Host "`nChoose an option (1-$($personas.Count + 2))"

    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $personas.Count) {
        return $personas[$choice - 1]
    }
    elseif ($choice -eq ($personas.Count + 1)) {
        $customPrompt = Read-Host "Enter your custom system prompt"
        $customName = Read-Host "Enter a name for this persona"
        if (![string]::IsNullOrWhiteSpace($customName) -and ![string]::IsNullOrWhiteSpace($customPrompt)) {
            $newPersona = @{ name = $customName; prompt = $customPrompt }
            $personas = @($personas) + @($newPersona)
            Save-Personas $personas
            return $newPersona
        }
        else {
            Write-Host "Invalid name or prompt. Persona not created." -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            return $null
        }
    }
    elseif ($choice -eq ($personas.Count + 2)) {
        return $null
    }
    else {
        Write-Host "Invalid choice." -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return $null
    }
}

function Show-ManagePersonasMenu {
    Clear-Host
    Write-Host "=== Manage Personas ===" -ForegroundColor Cyan
    Write-Host "`n1. Add Persona"
    Write-Host "2. Remove Persona"
    Write-Host "3. Modify Persona"
    Write-Host "4. Back to Main Menu"
    $choice = Read-Host "`nChoose an option (1-4)"

    switch ($choice) {
        "1" {
            $personas = Get-Personas
            $customPrompt = Read-Host "Enter the system prompt for the new persona"
            $customName = Read-Host "Enter a name for the new persona"
            if (![string]::IsNullOrWhiteSpace($customName) -and ![string]::IsNullOrWhiteSpace($customPrompt)) {
                $newPersona = @{ name = $customName; prompt = $customPrompt }
                $personas = @($personas) + @($newPersona)
                Save-Personas $personas
                Write-Host "Persona '$customName' added successfully." -ForegroundColor Green
            }
            else {
                Write-Host "Invalid name or prompt. Persona not added." -ForegroundColor Red
            }
            Read-Host "Press Enter to continue..."
            return
        }
        "2" {
            $personas = Get-Personas
            if ($personas.Count -eq 0) {
                Write-Host "No personas available to remove." -ForegroundColor Yellow
                Read-Host "Press Enter to continue..."
                return
            }
            Clear-Host
            Write-Host "=== Remove Persona ===" -ForegroundColor Cyan
            for ($i = 0; $i -lt $personas.Count; $i++) {
                Write-Host "$($i + 1). $($personas[$i].name)"
            }
            Write-Host "$($personas.Count + 1). Cancel"
            $choice = Read-Host "`nChoose a persona to remove (1-$($personas.Count + 1))"
            if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $personas.Count) {
                $config = Get-Config
                $removedPersona = $personas[$choice - 1].name
                if ($config.currentPersona -and $config.currentPersona.name -eq $removedPersona) {
                    $config.currentPersona = $null
                    Save-Config $config
                }
                $personas = @($personas | Where-Object { $_.name -ne $removedPersona })
                Save-Personas $personas
                Write-Host "Persona '$removedPersona' removed successfully." -ForegroundColor Green
            }
            elseif ($choice -eq ($personas.Count + 1)) {
                Write-Host "Removal cancelled." -ForegroundColor Yellow
            }
            else {
                Write-Host "Invalid choice." -ForegroundColor Red
            }
            Read-Host "Press Enter to continue..."
            return
        }
        "3" {
            $personas = Get-Personas
            if ($personas.Count -eq 0) {
                Write-Host "No personas available to modify." -ForegroundColor Yellow
                Read-Host "Press Enter to continue..."
                return
            }
            Clear-Host
            Write-Host "=== Modify Persona ===" -ForegroundColor Cyan
            for ($i = 0; $i -lt $personas.Count; $i++) {
                Write-Host "$($i + 1). $($personas[$i].name)"
            }
            Write-Host "$($personas.Count + 1). Cancel"
            $choice = Read-Host "`nChoose a persona to modify (1-$($personas.Count + 1))"
            if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $personas.Count) {
                $selectedPersona = $personas[$choice - 1]
                Write-Host "`nCurrent name: $($selectedPersona.name)"
                $newName = Read-Host "Enter new name (press Enter to keep current)"
                if ([string]::IsNullOrWhiteSpace($newName)) {
                    $newName = $selectedPersona.name
                }
                Write-Host "`nCurrent prompt: $($selectedPersona.prompt)"
                $newPrompt = Read-Host "Enter new prompt (press Enter to keep current)"
                if ([string]::IsNullOrWhiteSpace($newPrompt)) {
                    $newPrompt = $selectedPersona.prompt
                }
                if (![string]::IsNullOrWhiteSpace($newName) -and ![string]::IsNullOrWhiteSpace($newPrompt)) {
                    $personas[$choice - 1] = @{ name = $newName; prompt = $newPrompt }
                    Save-Personas $personas
                    $config = Get-Config
                    if ($config.currentPersona -and $config.currentPersona.name -eq $selectedPersona.name) {
                        $config.currentPersona = @{ name = $newName; prompt = $newPrompt }
                        Save-Config $config
                    }
                    Write-Host "Persona '$newName' modified successfully." -ForegroundColor Green
                }
                else {
                    Write-Host "Invalid name or prompt. Persona not modified." -ForegroundColor Red
                }
            }
            elseif ($choice -eq ($personas.Count + 1)) {
                Write-Host "Modification cancelled." -ForegroundColor Yellow
            }
            else {
                Write-Host "Invalid choice." -ForegroundColor Red
            }
            Read-Host "Press Enter to continue..."
            return
        }
        "4" {
            return
        }
        default {
            Write-Host "Invalid choice." -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            return
        }
    }
}

function Show-ClearMenu {
    Clear-Host
    Write-Host "=== Clear Conversation History ===" -ForegroundColor Red
    $logFiles = Get-ChildItem -Path $logDir -Filter "*.txt"
    if ($logFiles.Count -eq 0) {
        Write-Host "No conversation history files found to clear." -ForegroundColor Yellow
        Read-Host "Press Enter to return to the main menu"
        return
    }

    Write-Host "This will delete all $($logFiles.Count) conversation history files in the '$logDir' directory." -ForegroundColor Yellow
    Write-Host "1. Delete ALL conversation history"
    Write-Host "2. Cancel and return to main menu"
    $choice = Read-Host "`nChoose an option (1-2)"

    if ($choice -eq '1') {
        $confirmation = Read-Host "ARE YOU SURE you want to permanently delete all history? This cannot be undone. [y/n]"
        if ($confirmation.ToLower() -eq 'y') {
            Write-Host "`nDeleting all history files..." -ForegroundColor Red
            try {
                $filesToDelete = Get-ChildItem -Path $logDir -Filter "*.txt"
                Remove-Item -Path $filesToDelete.FullName -Force -ErrorAction Stop
                Write-Host "Success! All conversation history has been deleted." -ForegroundColor Green
            }
            catch {
                Write-Host "An error occurred while deleting files. ERROR: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "`nDeletion cancelled." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nCancelled. Returning to main menu." -ForegroundColor Yellow
    }
    Read-Host "Press Enter to return to the main menu"
}

function Load-MessageHistory($personaName, $systemPrompt) {
    $logFile = Join-Path $logDir "$personaName.txt"
    $messages = @()
    $messages += @{ role = "system"; content = $systemPrompt }
    if (Test-Path $logFile) {
        $lines = Get-Content $logFile
        foreach ($line in $lines) {
            if ($line -match "^You: (.+)") {
                $messages += @{ role = "user"; content = $Matches[1] }
            } elseif ($line -match "^AI: (.+)") {
                $messages += @{ role = "assistant"; content = $Matches[1] }
            }
        }
    }
    return @{ messages = $messages; logFile = $logFile }
}

function Start-Chat($persona) {
    $config = Get-Config
    $personaName = $persona.name
    $systemPrompt = $persona.prompt
    $history = Load-MessageHistory -personaName $personaName -systemPrompt $systemPrompt
    $messages = $history.messages
    $logFile = $history.logFile
    Clear-Host
    Write-Host "`n[Chat started with persona: $personaName, model: $($config.currentModel)]" -ForegroundColor Green
    Write-Host "Type 'exit' to end the script, or 'menu' to return to the main menu.`n" -ForegroundColor DarkGray
    while ($true) {
        $userInput = Read-Host "$userName"
        if ($userInput.ToLower() -eq "exit") {
            return "exit"
        }
        elseif ($userInput.ToLower() -eq "menu") {
            return
        }
        elseif ([string]::IsNullOrWhiteSpace($userInput)) {
            continue
        }
        $messages += @{ role = "user"; content = $userInput }
        $body = @{
            model = $config.currentModel
            messages = $messages
            temperature = 0.7
            stream = $false
        } | ConvertTo-Json -Depth 10
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body $body -TimeoutSec 60
            $aiReply = $response.choices[0].message.content.Trim()
            $messages += @{ role = "assistant"; content = $aiReply }
            $logEntryUser = "You: $userInput"
            $logEntryAI = "${personaName}: $aiReply"
            Add-Content -Path $logFile -Value $logEntryUser
            Add-Content -Path $logFile -Value $logEntryAI
            # Word-wrap output to prevent splitting words
            $consoleWidth = $Host.UI.RawUI.BufferSize.Width
            $prefix = "${personaName}: "
            $prefixLength = $prefix.Length
            $maxLineLength = $consoleWidth - 2 # Account for padding
            $words = $aiReply -split ' '
            $currentLine = $prefix
            $currentLength = $prefixLength
            Write-Host "`n" -NoNewline
            foreach ($word in $words) {
                $wordLength = $word.Length + 1 # Include space
                if ($currentLength + $wordLength -gt $maxLineLength) {
                    Write-Host $currentLine -ForegroundColor Yellow
                    $currentLine = " " * $prefixLength + $word + " "
                    $currentLength = $prefixLength + $wordLength
                } else {
                    $currentLine += $word + " "
                    $currentLength += $wordLength
                }
            }
            if ($currentLine.Trim().Length -gt $prefixLength) {
                Write-Host $currentLine -ForegroundColor Yellow
            }
            Write-Host "`n" -NoNewline
            Speak-Text -text $aiReply
        }
        catch {
            Write-Host "Error communicating with API: $_" -ForegroundColor Red
            $messages = $messages[0..($messages.Count - 2)]
        }
    }
}

# === Main script ===
Write-Host "Checking for updates..." -ForegroundColor Cyan
Check-ForUpdate

$apiKeyInput = Get-ApiKey
$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer $apiKeyInput"
}
$userName = Get-UserName
if (-not $userName -or -not (Test-Path $configFile)) {
    $userName = Run-Setup
}
while ($true) {
    $menuSelection = Show-MainMenu
    switch ($menuSelection.action) {
        "chat" {
            $config = Get-Config
            $result = Start-Chat -persona $config.currentPersona
            if ($result -eq "exit") { break }
        }
        "selectPersona" {
            $selectedPersona = Show-PersonaMenu
            if ($selectedPersona) {
                $config = Get-Config
                $config.currentPersona = $selectedPersona
                Save-Config $config
            }
        }
        "selectModel" {
            $selectedModel = Show-ModelMenu
            if ($selectedModel) {
                $config = Get-Config
                $config.currentModel = $selectedModel
                Save-Config $config
                Write-Host "Model changed to $selectedModel" -ForegroundColor Green
            }
            Read-Host "Press Enter to return to menu"
        }
        "clear" {
            Show-ClearMenu
        }
        "changeName" {
            $newName = Read-Host "Enter new user name"
            if (![string]::IsNullOrWhiteSpace($newName)) {
                Save-UserName $newName
                $userName = $newName
                Write-Host "User name changed to $userName" -ForegroundColor Green
            }
            else {
                Write-Host "Invalid name, user name not changed." -ForegroundColor Yellow
            }
            Read-Host "Press Enter to return to menu"
        }
        "changeKey" {
            do {
                $newKey = Read-Host "Enter your new API key"
                if (Test-ApiKey $newKey) {
                    Save-ApiKey $newKey
                    $apiKeyInput = $newKey
                    $headers["Authorization"] = "Bearer $apiKeyInput"
                    Write-Host "API key updated successfully." -ForegroundColor Green
                    break
                }
                else {
                    Write-Host "Invalid API key or network error. Please try again." -ForegroundColor Red
                }
            } until ($false)
            Read-Host "Press Enter to return to menu"
        }
        "managePersonas" {
            Show-ManagePersonasMenu
        }
        "generateImage" {
            Show-ImageGenerationMenu
        }
        "exit" {
            Write-Host "Goodbye!" -ForegroundColor Cyan
            $speechSynthesizer.Dispose()
            break
        }
        "menu" {
            # Loop back to main menu
        }
        default {
            Write-Host "Unknown action. Returning to menu." -ForegroundColor Yellow
        }
    }
}
