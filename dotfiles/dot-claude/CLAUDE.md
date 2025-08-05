# Global Claude Configuration

## Personal Development Environment

- **OS**: macOS
- **Shell**: Zsh with oh-my-zsh
- **Terminal**: WezTerm
- **Editor**: Neovim with Lua configuration
- **Package Manager**: Homebrew
- **Theme**: Catppuccin (Macchiato variant)

## Code Style Preferences

- **Indentation**: 4 spaces for JS/TS/JSON, 2 spaces for YAML
- **JavaScript/TypeScript**:
  - Prefer `const` over `let` when possible
  - Use semicolons
  - Prefer arrow functions for inline callbacks
  - Use TypeScript strict mode
  - Use bun as package manager for every command
- **Python**:
  - Follow PEP 8
  - always use uv as package manager
- **Markdown**: Use ATX-style headers (#)

## Workflow Preferences

- **Agents**: Always check if an agent is more appropriate to do a task
- **Git**: Use conventional commits format
- **Testing**: Run tests before commits
- **Linting**: Always run linters/formatters before commits
- **Documentation**: Keep README files concise and practical
- Commit often, but with meaningful messages
- Use branches for features/bugfix
- follow feature branch workflows

## Common Commands & Tools

- **Package Management**: `brew bundle` for system packages
- **Development**: `npm run dev`, `cargo run`, `python -m pytest`
- **Git**: Use `lazygit` for terminal Git UI
- **File Management**: Use `eza` instead of `ls`
- **Navigation**: Use `zoxide` for smart directory jumping

## Security & Best Practices

- Never commit secrets or API keys
- Use environment variables for sensitive data
- Always review changes before committing
- Prefer explicit imports over wildcards

## Communication Style

- Be concise and direct
- Focus on practical solutions
- Minimize unnecessary explanations
- Use examples when helpful
- Do not repeat information unnecessarily
- Do not repeat the question or prompt
- Do not gratitude or apologies unless specifically requested

## Tool Preferences

- **Terminal multiplexer**: tmux with TPM plugins
- **File searching**: ripgrep (`rg`) over grep
- **Process monitoring**: htop, btop
- **JSON processing**: jq
- **HTTP requests**: curl, httpie
