# Universal Multi-Agent Orchestration Patterns

Harness-agnostic patterns for designing, decomposing, and running multi-agent systems. Applies to Claude Code, Pi, OpenCode, and custom frameworks.

---

## When to Use Multi-Agent

Anthropic's three canonical scenarios where multi-agent outperforms a single agent:

### 1. Context Protection
Information from one subtask pollutes context for others. Keeping subtasks in isolated agents prevents cross-contamination.

- Example: researching five competing libraries independently before synthesis
- Example: running security audit in isolation so vulnerability details don't bias the implementation agent

### 2. Parallelization
Explore a larger search space by running multiple agents simultaneously.

- Example: testing three different architectural approaches at once
- Example: scraping 20 documentation sources in parallel

### 3. Specialization
When a single agent has 20+ tools, performance degrades. Focused toolsets outperform generalist configurations.

- Example: a research agent with only web/read tools, a build agent with only bash/file tools
- Example: a validator agent with read-only access to prevent accidental writes

**Default to single agent.** Multi-agent adds 3-10x token overhead due to context passing, system prompt repetition, and coordination messages. Use it only when one of the three scenarios above applies clearly.

---

## Decomposition Principle

**Group work by what context it requires, not by what kind of work it is.**

This is the most common decomposition mistake. Phase-based decomposition (plan → build → test → deploy) is intuitive but often wrong. Component-based decomposition that follows clean interface boundaries is almost always better.

### Good Decomposition Boundaries

- Independent research paths with no shared intermediate state
- Components with well-defined interfaces (API contract, file format, message schema)
- Tasks that need different tool access (read-only vs read-write, web vs file system)
- Work that is embarrassingly parallel (same operation on different inputs)

### Bad Decomposition Boundaries

- Sequential phases where each phase depends tightly on the previous one's internals
- Tightly coupled components that share mutable state
- Tasks that require constant back-and-forth clarification between agents
- Work that is faster done by one agent than by coordinating two

### Decomposition Checklist

Before spawning a sub-agent, answer:
1. Can I describe this agent's inputs and outputs precisely?
2. Will this agent's work contaminate my context if done inline?
3. Is there genuinely parallel work to be done?
4. Does this agent need a different tool set than the parent?

If you answer "no" to all four, keep it in the current agent.

---

## Orchestration Patterns

### Lead/Worker (Fan-out)

The most common multi-agent pattern. The lead coordinates without doing primary research. Workers run in parallel with focused, non-overlapping tasks. The lead synthesizes results.

**Structure:**
```
Lead (coordinator)
  |-- Worker A (topic/component A)
  |-- Worker B (topic/component B)
  |-- Worker C (topic/component C)
  |
  +-- Synthesize results from A, B, C
```

**Rules:**
- Lead never does primary research or implementation directly
- Workers have no awareness of each other
- Lead writes synthesis after all workers complete
- Hard cap: never spawn more than 20 sub-agents

**Harness mapping:**
- Claude Code: Agent teams with a coordinator agent
- Pi: `agent-team` extension with dispatcher
- OpenCode: custom subagent definitions, orchestrated by main agent

**When to use:** Research synthesis, parallel code review, multi-file refactors with independent components.

---

### Builder/Validator

The most consistently effective pattern for code quality. Two agents with different access levels and roles.

**Structure:**
```
Builder (read-write access)
  --> implements feature
  --> signals completion

Validator (read-only access)
  --> runs full test suite
  --> verifies requirements
  --> exits 2 if incomplete (CC) or signals feedback (Pi)
```

**Key rules:**
- Builder has write access; validator has read-only access (enforced at tool level)
- Tell the validator explicitly to "run the full test suite" — this prevents it from declaring success after a partial check
- Validator uses exit code 2 (Claude Code) or an event signal (Pi) to send feedback back to the builder
- Loop continues until validator exits 0 (Claude Code) or sends approval signal

**Why read-only for validator:** Validators with write access tend to fix the tests rather than fix the code. Read-only forces honest evaluation.

**Harness mapping:**
- Claude Code: SubagentStop hook with exit 2 for feedback loop
- Pi: on_tool_use hook to intercept write attempts by validator role
- OpenCode: tool permission config per subagent

---

### Evaluator/Optimizer Loop

Iterative refinement between a generator and an evaluator. Continues until a quality threshold is met.

**Structure:**
```
Generator --> produces artifact
Evaluator --> scores artifact (0-100)
  if score >= threshold: done
  else: Generator receives feedback, produces next iteration
```

**Loop control:**
- Set a maximum iteration count (e.g., 10) as a safety net
- Include the score and specific failure reasons in feedback to the generator
- Do not let the evaluator rewrite the artifact — evaluation only

**Threshold guidance:**
- 80+ for code correctness (tests pass, no obvious bugs)
- 90+ for documentation quality
- 95+ for security-sensitive outputs

**Variables to pass between iterations:**
```
$ITERATION    # current loop count
$SCORE        # evaluator's numeric score
$FEEDBACK     # evaluator's specific failure reasons
$ARTIFACT     # current artifact (file path or inline)
```

---

### Dispatcher (Pi-specific pattern)

A central orchestrator with a team roster manages dynamic task assignment. Particularly powerful in Pi where the dispatcher extension provides a grid dashboard.

**Team roster definition (YAML):**
```yaml
team:
  - id: researcher
    role: "Research and information gathering"
    model: claude-opus-4-5
    tools: [web, read]

  - id: builder
    role: "Implementation and code generation"
    model: claude-sonnet-4-5
    tools: [read, write, bash]

  - id: reviewer
    role: "Code review and quality gates"
    model: claude-haiku-4-5
    tools: [read, bash]
```

**Dispatcher behavior:**
1. Receives task from user
2. Selects appropriate specialist(s) based on task type
3. Assigns task to specialist(s)
4. Monitors completion via grid dashboard
5. Routes results back or to next specialist

**Unique to Pi:** The dispatcher can intercept input via `on_input` hook to pre-classify tasks before they reach the LLM, reducing unnecessary tokens.

---

### Sequential Pipeline (Agent Chain)

Each agent's output becomes the next agent's input. Useful for workflows with mandatory sequential dependencies.

**Structure:**
```
Step 1 (Scout/Planner)
  output --> Step 2 input

Step 2 (Builder/Implementer)
  output --> Step 3 input

Step 3 (Reviewer/Validator)
  output --> final result
```

**Variable passing conventions:**
- `$INPUT` — output from the previous step
- `$ORIGINAL` — the original user prompt (preserved across all steps)
- `$STEP_N_OUTPUT` — explicit reference to a specific step's output

**Common pipeline workflows:**

| Workflow | Step 1 | Step 2 | Step 3 |
|----------|--------|--------|--------|
| Plan-Build-Review | Architect → plan.md | Builder → implementation | Reviewer → sign-off |
| Scout-Flow | Scout → findings.md | Specialist → deep work | Synthesizer → report |
| Full-Review | Code reader → summary | Security analyst → vulns | Performance analyst → metrics |

**When not to use:** If steps require back-and-forth, use Builder/Validator loop instead. Sequential pipelines are one-directional.

---

### Meta-Agent (Agent Builder)

A specialized orchestrator that generates other agents dynamically. The meta-agent is given a high-level goal and produces a set of agent definitions, then spawns and coordinates those agents.

**Structure:**
```
Meta-Agent
  |-- Research experts gather context (parallel)
  |-- Meta-Agent generates agent definitions
  |-- Spawned agents execute their tasks
  |-- Meta-Agent synthesizes results
```

**Use cases:**
- Dynamic team composition based on task analysis
- Generating task-specific agents at runtime
- Self-modifying pipelines where the task structure is not known in advance

**Risk:** Meta-agents are complex to debug and can spawn agents with conflicting assumptions. Use only when the task structure is genuinely unknown at design time.

---

## Team Topologies

### Fan-out Research
2-5 parallel investigators on different angles of the same question.

```
Lead: "Research X from these 4 angles"
  --> Agent 1: angle A
  --> Agent 2: angle B
  --> Agent 3: angle C
  --> Agent 4: angle D
Lead: synthesize into single report
```

Best for: literature review, competitive analysis, multi-source fact-checking.

### Layered Architecture
Each layer of the stack owned by a dedicated agent.

```
Frontend Agent: UI components, styles
Backend Agent: API routes, business logic
Database Agent: schema, migrations, queries
Tests Agent: unit/integration/e2e tests
```

Best for: full-stack features where layers have clean interfaces.

### Competitive Hypothesis
Multiple agents test different approaches in parallel. Lead picks the winner.

```
Lead: "Solve X using 3 different approaches"
  --> Agent 1: approach A (greedy)
  --> Agent 2: approach B (dynamic programming)
  --> Agent 3: approach C (heuristic)
Lead: benchmark all three, keep the best
```

Best for: algorithm design, architecture decisions, performance optimization.

### Review Panel
Multiple reviewers with different areas of focus, each with read-only access.

```
Code Review Agent: correctness, patterns
Security Agent: vulnerabilities, injection
Performance Agent: bottlenecks, complexity
Accessibility Agent: WCAG, semantic HTML
Lead: merge all findings into review comment
```

Best for: high-stakes code review, compliance checks, multi-dimension quality gates.

---

## Communication Patterns

### Parent-Child (Structured Context Passing)

The parent passes structured context to the child at spawn time. The child returns structured output.

**Context to pass at spawn:**
```
- sandbox_id or workflow_id (unique per run)
- plan_path (path to shared plan file)
- task_description (specific, bounded)
- tool_access (explicit list of permitted tools)
- output_format (schema or format string)
```

**Child output to return:**
```
- status: success | failure | partial
- result: (the actual output)
- errors: (any errors encountered)
- confidence: 0-100
```

### Peer-to-Peer

Teammates message each other without going through the parent.

- Claude Code: agent teams allow direct teammate messaging
- Pi: `pi.events` bus for inter-extension and inter-agent messaging
- OpenCode: not natively supported; use shared file or parent as relay

### Shared Task List (Claude Code native)

Coordinate via TodoWrite/TodoRead. Each agent updates task status; others react.

```
Lead: TodoWrite([{task: "implement auth", status: "pending"}])
Builder: TodoRead() --> picks up "implement auth"
Builder: TodoWrite([{task: "implement auth", status: "in_progress"}])
Builder: TodoWrite([{task: "implement auth", status: "completed"}])
Lead: TodoRead() --> sees "completed", proceeds to next phase
```

### Event Bus (Pi native)

Pi's `pi.events` system allows any extension or agent to publish and subscribe to named events.

```
builder.emit("build:complete", { files: [...], errors: [] })
validator.on("build:complete", (payload) => { ... })
```

---

## Safety Patterns

### ID Management

Every multi-agent workflow needs a unique identifier to prevent resource collisions.

- Store the workflow ID in agent context, not shell variables
- Never use shared files as the ID store (race conditions)
- Generate IDs before spawning any agents: `WORKFLOW_ID=$(uuidgen)`
- Pass the ID explicitly to every sub-agent at spawn time

### Port Isolation

When agents need to run local servers or services:

- Pre-assign a unique port range per agent before launching
- Validate port availability before starting the agent's service
- Include the port in the structured context passed at spawn
- Never let agents pick their own ports (collisions are hard to debug)

### Directory Isolation

Each workflow runs in its own working directory.

```
temp/
  <WORKFLOW_ID>/
    agent-a/
    agent-b/
    shared/   (read-only after written by lead)
    results/
```

- Each agent only reads/writes its own subdirectory
- Shared input goes in `shared/` and is written once by the lead before agents start
- Results go in `results/` using the agent's ID as filename

### Explicit Cleanup

Each agent is responsible for cleaning up only its own resources.

- The lead does not clean up sub-agents' resources
- Sub-agents do not clean up each other's resources
- Cleanup runs even on failure (use finally blocks or cleanup hooks)
- Log cleanup actions explicitly for debugging

### Conflict Prevention

Use unique identifiers in all resource names to prevent collisions.

```
# Bad
db_name: "test_db"

# Good
db_name: "test_db_${WORKFLOW_ID}"
```

Applies to: database names, file paths, port numbers, API resource names, container names.

---

## Scaling Guidelines

| Query Type | Strategy | Recommended Agent Count |
|------------|----------|------------------------|
| Depth-first | Multiple angles on one focused topic | 2-5 |
| Breadth-first | Decompose into independent subtopics | 3-10 |
| Straightforward | Single focused investigation | 1 |
| Validation loop | Builder + Validator | 2 |
| Full-stack feature | Layered architecture | 3-5 |
| Competitive hypothesis | Parallel approaches | 2-4 |
| Large codebase audit | Fan-out by module | 5-15 |

**Diminishing returns** appear after 5-7 agents. Beyond 10, coordination overhead typically exceeds the parallelization benefit. Hard cap at 20 in all cases.

---

## Quality Gates

### Confidence-Based Filtering

Each sub-agent returns a confidence score (0-100) with its result.

```
threshold = 80
results = [r for r in agent_results if r.confidence >= threshold]
low_confidence = [r for r in agent_results if r.confidence < threshold]
# retry low_confidence agents or flag for human review
```

### TeammateIdle Hook (Claude Code)

Fires when a teammate has no pending tasks. Exit 2 to send a feedback message and reassign work.

```python
# TeammateIdle hook
if teammate.output_quality < threshold:
    print(f"Feedback: {generate_feedback(teammate.output)}")
    sys.exit(2)  # re-queues the teammate with feedback
```

### TaskCompleted Hook (Claude Code)

Fires when a task is marked done. Exit 2 to prevent completion and send feedback.

```python
# TaskCompleted hook
if not all_acceptance_criteria_met(task):
    print(f"Task incomplete: {missing_criteria}")
    sys.exit(2)  # task stays open, builder receives feedback
```

### Stop Hook Iterative Loop (Ralph Pattern)

Feed the same prompt back into the same agent using the Stop hook. Creates a self-correcting loop without spawning a new agent.

```python
# Stop hook
result = read_agent_output()
if not meets_criteria(result):
    # Write new prompt incorporating the result and feedback
    write_next_prompt(f"Previous attempt: {result}\nFeedback: {feedback}\nTry again.")
    sys.exit(2)  # agent continues with new prompt
```

Use this for single-agent refinement before escalating to multi-agent.

---

## Result Aggregation

Standard pattern for collecting, validating, and reporting multi-agent results.

```python
def aggregate_results(agent_results):
    # 1. Parse each result for status
    successes = [r for r in agent_results if r.status == "success"]
    failures  = [r for r in agent_results if r.status == "failure"]
    partials  = [r for r in agent_results if r.status == "partial"]

    # 2. Aggregate metrics
    total_confidence = sum(r.confidence for r in successes) / len(successes)
    coverage = len(successes) / len(agent_results)

    # 3. Handle failures
    for f in failures:
        if f.retryable:
            retry_queue.append(f)
        else:
            escalate_to_human(f)

    # 4. Generate consolidated report
    return {
        "summary_table": build_table(agent_results),
        "metrics": {"coverage": coverage, "avg_confidence": total_confidence},
        "failures": failures,
        "output": merge_outputs(successes),
    }
```

**Consolidated report format:**

```markdown
## Agent Results

| Agent | Status | Confidence | Key Finding |
|-------|--------|------------|-------------|
| A     | ok     | 92         | ... |
| B     | ok     | 87         | ... |
| C     | fail   | n/a        | timeout |

## Merged Output
...

## Failures
- Agent C: timed out after 300s. Retrying.
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Spawning agents for each file | Coordination overhead exceeds benefit | Batch files into groups of 5-10 per agent |
| Agents with 20+ tools | Tool selection quality degrades | Split into specialized agents with 5-8 tools each |
| Shared mutable state | Race conditions, unpredictable order | Use directory isolation and read-only shared inputs |
| Agents that spawn agents recursively | Exponential token overhead | Set max depth of 2 (lead -> worker only) |
| Sequential agents for parallel work | No speedup over single agent | Fan-out to parallel workers |
| Parallel agents for sequential work | Context transfer errors | Use sequential pipeline pattern |
| Validator with write access | Fixes tests instead of code | Enforce read-only tool access for validator role |
