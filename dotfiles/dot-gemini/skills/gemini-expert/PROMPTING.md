# Prompting Strategies for Gemini

Optimizing prompts for Gemini 1.5/2.0+ models.

## Core Principles
1.  **Clear Instructions:** Be explicit about *what* to do and *how* to output it.
2.  **Context:** Provide sufficient background information.
3.  **Examples (Few-Shot):** Show 1-3 examples of input -> desired output.
4.  **Structure:** Use Markdown or XML tags to separate instruction, context, and data.

## Structural Pattern (The "Sandwich" or "Component" Method)

```markdown
# Role
You are a senior Python engineer...

# Context
We are migrating a Flask app to FastAPI.
<files>
...
</files>

# Task
Refactor the `auth.py` file to use `FastAPI.Depends`.

# Constraints
*   Do not change the database schema.
*   Use Pydantic v2.

# Output Format
Return only the code block.
```

## Advanced Techniques

### Chain of Thought (CoT)
Ask the model to "think step-by-step" or "explain your reasoning before coding."
> "First, analyze the dependency tree. Then, propose a plan. Finally, generate the code."

### XML Tagging
Use XML tags to clearly delimit parts of the prompt, especially for data processing.
> "Extract email addresses from the text wrapped in `<text>` tags and output them in `<emails>` tags."

### Role Prompting
Assign a specific persona to narrow the search space and style.
> "Act as a security auditor." vs "Act as a junior developer."

## Gemini-Specific Tips
*   **Long Context:** Gemini handles massive context (1M+ tokens). Don't be afraid to dump entire documentation sets or codebases into the context (using `@dir/`).
*   **Multimodal:** Gemini understands images and video. Use screenshots of UI bugs directly in the prompt.
