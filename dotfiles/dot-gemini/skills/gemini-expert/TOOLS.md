# Tools & Memory

## Built-in Tools
*   **File System:** `ls`, `read_file`, `write_file`, `replace`, `search_file_content` (grep), `glob`.
*   **Execution:** `run_shell_command`.
*   **Web:** `web_fetch` (content), `google_web_search`.
*   **Interaction:**
    *   `AskUser`: Request explicit input or choices from the user via UI components.
    *   `communicate`: Used specifically in planning mode to interact with the user or other agents.
*   **Memory:** `save_memory` (Long-term facts).

## Task Management (`write_todos`)
Agents use this tool to manage complex workflows.
*   **Usage:** Create a list of subtasks (`pending`, `in_progress`, `completed`).
*   **Benefit:** Keeps the agent on track and provides user visibility.

## Memory Imports (`@`)
Modularize your `GEMINI.md` or prompt context using the import syntax.
*   `@path/to/file.md`: Injects content of file.
*   `@path/to/dir/`: Lists directory content (or reads files if configured).

**Recursive Loading:**
If `main.md` contains `@sub.md`, and `sub.md` contains `@data.txt`, Gemini resolves the full tree.

## Tools API (Developers)
Extensions can provide new tools.
*   **Schema:** Defined in JSON.
*   **Execution:** The CLI handles the "tool loop" (Model -> Call -> Execute -> Result -> Model).
