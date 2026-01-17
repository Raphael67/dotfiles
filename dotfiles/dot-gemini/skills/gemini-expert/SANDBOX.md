# Sandboxing

Sandboxing isolates the Gemini CLI's execution environment to prevent accidental or malicious damage to the host system.

## Modes
1.  **Docker / Podman (Recommended):**
    *   Runs execution tools (`run_shell_command`) inside a container.
    *   Mounts the project directory.
    *   Provides strong isolation.
2.  **macOS Seatbelt:**
    *   Uses the native macOS `sandbox-exec`.
    *   Restricts file access to specific paths.
    *   Lightweight but less isolated than Docker.

## Enabling Sandbox
*   **Flag:** `gemini -s` or `gemini --sandbox`
*   **Env:** `GEMINI_SANDBOX=true`
*   **Settings:** `"tools": { "sandbox": true }`

## Configuration
Customize allowed paths and network access in `settings.json` or `.gemini/sandbox.json` (depending on implementation).

## Safety First
Even with a sandbox, always review the commands Gemini proposes, especially `run_shell_command` and `write_file`.
