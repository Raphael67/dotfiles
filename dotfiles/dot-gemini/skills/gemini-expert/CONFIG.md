# Configuration & Context

Gemini CLI uses a layered configuration system and hierarchical context loading.

## Settings Hierarchy
Precedence (lowest to highest):
1.  Default Values
2.  User Settings (`~/.gemini/settings.json`)
3.  Project Settings (`<project>/.gemini/settings.json`)
4.  Environment Variables
5.  Command Flags

## GEMINI.md (Context)
Files named `GEMINI.md` provide context and instructions to the model.
*   **Global:** `~/.gemini/GEMINI.md` (General persona, user facts).
*   **Project:** `<project>/GEMINI.md` (Project overview, conventions).
*   **Subdirectories:** `<project>/src/GEMINI.md` (Module-specific details).

**Loading:** When you work in a directory, Gemini loads the `GEMINI.md` from that directory and all parent directories up to the root, concatenating them. Specific instructions (closer to current dir) override general ones.

## Environment Variables (`.env`)
Gemini loads `.env` files from the current and parent directories.
*   `GEMINI_API_KEY`: Google AI Studio Key.
*   `GEMINI_MODEL`: Default model (e.g., `gemini-2.0-flash-exp`).
*   `GEMINI_SYSTEM_MD`: Path to a markdown file to completely override the system prompt (Advanced).

## Settings.json

Key configurations:

*   `experimental.skills`: `true` (Enable skills).

*   `tools.sandbox`: `true` (Enable Docker/Seatbelt sandbox).

*   `telemetry.enabled`: `false` (Disable analytics).

*   `mcp.servers`: Configure Model Context Protocol servers. You can now enable/disable them via commands.

*   `approval.persistent`: `true` (Retain tool approval choices across sessions).



## GEMINI.md (Context)


