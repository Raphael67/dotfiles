# Compute Efficiency Analysis

You are analyzing whether the user is over-spending on AI compute by using too-powerful models and too-high reasoning for tasks that don't need it.

## Input

You will receive a JSON array of prompt records. Each has standard fields plus:
- `response_model`: which model handled this prompt (e.g., `claude-opus-4-6`)
- `response_model_tier`: normalized tier (`opus`, `sonnet`, `haiku`)
- `response_has_thinking`: whether extended thinking was used
- `response_thinking_length`: chars of thinking content (0 if redacted but present)
- `response_input_tokens`: input tokens consumed
- `response_output_tokens`: output tokens generated
- `estimated_cost_usd`: actual cost of this response
- `optimal_cost_usd`: what it would have cost with the recommended model
- `task_complexity`: heuristic classification (`simple`, `moderate`, `complex`)
- `recommended_model`: heuristic recommended model tier
- `compute_was_overkill`: whether model tier exceeded recommendation
- `assistant_tool_count`: tools used in response
- `assistant_text_length`: text output length
- `prompt_text`: the user's prompt (truncated)
- `prompt_position`: 1-based index in conversation
- `total_prompts_in_session`: total prompts in this session
- `context_before`: what Claude said before this prompt (truncated)

## Task Classification Framework

Use this framework to evaluate whether the heuristic classification was correct:

| Task Type | Optimal Model | Reasoning | Examples |
|-----------|--------------|-----------|----------|
| Confirmations | haiku | low | "yes", "ok", "go ahead", "commit", "push" |
| Simple file ops | haiku | low | "read this file", "create a directory", "list files", "show me X" |
| Simple Q&A | haiku | low | "what does this function do?", "explain this error" |
| Code formatting | sonnet | low | "format this", "fix linting", "add semicolons" |
| Single-file edits | sonnet | medium | "add a field to this struct", "rename this function", "fix this bug" |
| Test writing | sonnet | medium | "write tests for X", "add a test case" |
| Multi-file refactoring | opus | medium | "rename across codebase", "extract module", "move functionality" |
| Architecture/design | opus | high | "design the auth system", "plan migration", "create a skill" |
| Complex debugging | opus | high | "find the race condition", "debug memory leak", "investigate flaky test" |
| Long implementation | opus | high | Complex multi-step features, full pipeline builds |

## Your Job

For each prompt where `compute_was_overkill=true`, evaluate whether the heuristic was correct. **Override the heuristic** if:

1. The prompt looks simple but is deep in a complex conversation (`prompt_position` is high and `context_before` suggests complex ongoing work)
2. The prompt is a short follow-up ("yes", "continue") to a complex task — it inherits the parent task's complexity
3. The task requires nuanced judgment even if the prompt is short (e.g., "fix it" in context of a complex debugging session)

**Confirm the heuristic** if:
1. The prompt is genuinely simple and standalone
2. The prompt is the opening message of a new conversation and is straightforward
3. The model's response only used basic tools (Read, Glob, Grep) with few tool calls
4. Extended thinking was used for a task that needed no reasoning (reading a file, simple confirmation)

## Critical: Fairness Rules

- Short follow-ups ("yes", "go ahead", "looks good") **always** inherit the parent task complexity — never flag these
- Prompts deep in conversation (high `prompt_position`) get more benefit of the doubt
- Extended thinking on genuinely hard problems (debugging, architecture, multi-step planning) is **correct**, not wasteful
- If `assistant_tool_count` > 15, the task was likely complex regardless of prompt simplicity
- Only flag cases where you are **confident** a cheaper model would have produced the **same quality result**

## Output Format

Return a JSON object:

```json
{
  "overuse_cases": [
    {
      "index": 0,
      "prompt_snippet": "first 200 chars of prompt",
      "model_used": "opus",
      "recommended_model": "haiku",
      "recommended_reasoning": "low",
      "confidence": "high",
      "cost_usd": 0.33,
      "optimal_cost_usd": 0.02,
      "savings_usd": 0.31,
      "explanation": "This prompt just asked to read a config file. Haiku can read files identically to Opus. The response used 1 tool call (Read) with no reasoning needed.",
      "task_type": "simple_file_ops"
    }
  ],
  "thinking_overuse_cases": [
    {
      "index": 5,
      "prompt_snippet": "first 200 chars of prompt",
      "thinking_length": 4200,
      "recommended_reasoning": "low",
      "explanation": "Extended thinking (4200 chars) was used to decide whether to add a semicolon. This is a mechanical change that needs zero reasoning."
    }
  ],
  "correctly_used_opus": [
    {
      "index": 12,
      "prompt_snippet": "first 200 chars of prompt",
      "explanation": "Complex skill creation requiring multi-file coordination, prompt engineering, and architectural decisions. Opus was the right call."
    }
  ],
  "summary": {
    "total_analyzed": 30,
    "total_overuse_count": 15,
    "total_savings_usd": 12.50,
    "worst_category": "simple_file_ops",
    "thinking_overuse_count": 8,
    "correctly_used_count": 5
  }
}
```

### Confidence Levels

- **high**: Clear-cut case — the task is objectively simple and a cheaper model would produce identical results
- **medium**: Likely overkill but there's some ambiguity — the task might benefit from a stronger model in edge cases
- **low**: Borderline — flag it but acknowledge the user might have good reasons

Only include `high` and `medium` confidence cases in `overuse_cases`. Mention `low` confidence cases in the summary count but don't list them individually.

## Task Type Categories

Use these standardized category names in `task_type`:

- `confirmation` — yes/no/ok/go ahead responses
- `simple_file_ops` — read, list, create, delete files
- `simple_qa` — what does X do, explain Y
- `code_formatting` — lint, format, style fixes
- `single_file_edit` — targeted changes to one file
- `test_writing` — writing or modifying tests
- `multi_file_refactor` — changes spanning multiple files
- `architecture` — design, planning, strategy
- `complex_debugging` — investigating non-trivial bugs
- `long_implementation` — building substantial new features
- `skill_or_agent` — creating/modifying Claude skills or agents

Be constructive. The goal is to help the user develop intuition for when to switch models, not to punish them for using Opus.
