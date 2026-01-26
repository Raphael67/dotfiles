# Claude Prompting Reference

## Fundamental Principles

### Clarity Over Brevity
```
BAD:  "Summarize this report."
GOOD: "Summarize this report in 5 bullet points, focusing on Q3 financial performance."
```

### Format Begets Format
The style and format of your prompt influences the response. A formal prompt generates a formal response. Markdown in prompts encourages markdown output.

### Positive Instructions
Tell what TO do, not what NOT to do:
```
BAD:  "Don't make the response too long"
GOOD: "Respond in maximum 3 sentences."

BAD:  "Don't use technical jargon"
GOOD: "Explain as if speaking to a high school student."
```

## Prompt Structure Template

```xml
<role>
You are a [expert in X] with [Y years of experience].
</role>

<context>
Background information relevant to the task.
</context>

<instructions>
Clear, specific task description.
</instructions>

<constraints>
- Constraint 1
- Constraint 2
- Maximum length: X words
</constraints>

<format>
Expected output structure (JSON, list, table, etc.)
</format>

<examples>
<example>
  <input>Example input</input>
  <output>Expected output</output>
</example>
</examples>

<data>
Content to process
</data>
```

## XML Tags for Claude

Claude is **specifically trained** to recognize and respect XML tags. This is its distinctive strength.

### Semantic Tag Names
Use descriptive, consistent tag names:
- `<context>` - Background information
- `<instructions>` - Main task
- `<constraints>` - Limitations and rules
- `<examples>` - Input/output pairs
- `<data>` - Content to process
- `<thinking>` - Chain of thought reasoning
- `<answer>` - Final response

### Nesting for Hierarchy
```xml
<examples>
  <example>
    <input>User question</input>
    <output>Expected response</output>
  </example>
</examples>
```

### Reference Tags in Instructions
```
Using the content in <data>, extract all dates and format them as ISO 8601.
```

## Core Techniques

### 1. Few-Shot Prompting
Provide 2-5 input/output pairs to guide behavior:

```xml
<task>Classify sentiment</task>

<examples>
<example>
  <input>"This product is excellent, highly recommend!"</input>
  <output>positive</output>
</example>
<example>
  <input>"Disappointed, doesn't work as expected."</input>
  <output>negative</output>
</example>
</examples>

<classify>
<input>"It's okay, nothing special."</input>
</classify>
```

### 2. Chain of Thought (CoT)
Ask for step-by-step reasoning:

```xml
<instructions>
Solve this problem step by step.
Show your reasoning before giving the final answer.
</instructions>
```

With separation:
```xml
<instructions>
Think through this in <thinking> tags, then provide your final answer in <answer> tags.
</instructions>
```

### 3. Role Prompting
Assign expertise and perspective:

```xml
<role>
You are a senior software architect with 15 years of experience in distributed systems.
</role>

<task>
Review this architecture and identify potential weaknesses.
</task>
```

### 4. Structured Output
Request explicit formats:

```xml
<format>
Return as JSON:
{
  "name": string,
  "date": string (ISO 8601),
  "amount": number
}
</format>
```

### 5. Prefilling (API)
Start Claude's response to guide format:

```json
{
  "messages": [
    {"role": "user", "content": "Analyze this code and list bugs."},
    {"role": "assistant", "content": "## Identified Bugs\n\n1."}
  ]
}
```

## Claude 4+ Specifics

### Literal Instruction Following
Claude 4 models follow instructions more literally. Be explicit about thoroughness:

```
BAD:  "Create an analytics dashboard"
GOOD: "Create a complete analytics dashboard. Include as many relevant features
      and interactions as possible. Go beyond basics to create a full implementation."
```

### Explain the Why
Adding reasoning improves adherence:
```
Format the output as JSON because it will be parsed by an automated system.
```

### Parallel Tool Use
Maximize efficiency:
```xml
<instructions>
For maximum efficiency, when performing multiple independent operations,
invoke all relevant tools simultaneously rather than sequentially.
</instructions>
```

### Extended Thinking with "ultrathink"
Include "ultrathink" in prompts for extended thinking mode:
```xml
<instructions>
ultrathink

Analyze this complex problem thoroughly, considering multiple approaches
before providing your solution.
</instructions>
```

Extended thinking is ideal for:
- Complex multi-step reasoning
- Deep analysis and consideration
- Problems with multiple valid approaches
- Debugging and architectural analysis

## Advanced Patterns

### Self-Critique
```xml
<instructions>
After generating your response, evaluate it:
- Completeness (0-10)
- Clarity (0-10)
- Relevance (0-10)

If any score is below 7, revise your response.
</instructions>
```

### Tree of Thoughts
```xml
<instructions>
To solve this problem:
1. Generate 3 different approaches
2. Evaluate pros/cons of each
3. Choose the best and develop the solution
</instructions>
```

### State Tracking
For long tasks:
```xml
<instructions>
Track test state using JSON:
{
  "tests": [
    {"name": "test1", "status": "pass"},
    {"name": "test2", "status": "fail", "error": "..."}
  ]
}
Use free-form notes for context and progress.
</instructions>
```

## Common Mistakes to Avoid

| Mistake | Problem | Fix |
|---------|---------|-----|
| Vague terms | "Make it better" | Specify criteria |
| Negative instructions | "Don't be verbose" | "Maximum 200 words" |
| Asking to count | LLMs can't count chars | Provide char counts |
| Contradictions | Conflicting rules | Clear decision tree |
| No format spec | Random output format | Explicit format block |

## Checklist

### Before Writing
- [ ] Objective clearly defined?
- [ ] Success criteria measurable?
- [ ] Output format identified?

### While Writing
- [ ] Main instruction clear and specific?
- [ ] Necessary context provided?
- [ ] Constraints explicit (length, format, tone)?
- [ ] Examples useful for this task?
- [ ] Instructions say what TO do (not what NOT to)?
- [ ] Structure appropriate (XML for Claude)?

### After Testing
- [ ] Output matches expectations?
- [ ] Any ambiguities to clarify?
- [ ] Additional examples needed?
- [ ] Constraints respected?
