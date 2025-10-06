# Global Claude Configuration

## Personal Development Environment

- **Shell**: Zsh with oh-my-zsh
- **Terminal**: Ghostty
- **Editor**: VSCode
- **Package Manager**: Homebrew

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
- **Markdown**:
  - Use ATX-style headers (#)

## Workflow Preferences

- **Agents**: Always check if a subagent is more appropriate to do a task
- **Git**: Use conventional commits format
- **Documentation**: Keep README files concise and practical
- Commit after every task, but with meaningful messages
- Push your code after every commit
- Use branches for features/bugfix
- follow feature branch workflows
- Fast forward merge only

## Role-Based Responsibilities

### For Development Work (coding tasks):
- **Testing**: Run tests before commits
- **Linting**: Always run linters/formatters before commits
- **Code Quality**: Follow established patterns and conventions

### For Specification/Documentation Work:
- **No Testing Required**: Specs and docs don't need code testing
- **No Linting Required**: Focus on content quality, not code style
- **Commit Immediately**: Push specifications and documentation when complete
- **Quality Focus**: Ensure completeness, clarity, and alignment with requirements

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
- ALways use work-completion subagent
