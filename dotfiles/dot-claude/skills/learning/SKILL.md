---
name: learning
description: >
  Generates personalized learning plans for any topic (tech or non-tech).
  Assesses current knowledge, researches official documentation and resources,
  creates structured learning paths with theory and practice modules.
  Stores the plan in Obsidian for interactive follow-up with the learning-tutor agent.
  Use when: learn, study plan, learning path, curriculum, teach me,
  how to learn, formation, apprendre, study, training.
user-invocable: true
argument-hint: [topic]
version: 1.1.0
model: opus
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch,
  AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskOutput, TaskStop, TaskUpdate,
  mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Learning Plan Generator

Create personalized, structured learning plans for any topic and store them in Obsidian for interactive tutoring sessions.

## Quick Reference

| File | Content | When to Read |
|------|---------|--------------|
| PEDAGOGY.md | Learning methodology, exercise taxonomy, spaced repetition | Designing module structure (Phase 3) |
| ASSESSMENT.md | Knowledge assessment rubrics, calibration questions | Running assessment (Phase 1) |
| PLAN-FORMAT.md | Obsidian templates for plan, modules, progress tracker | Writing output files (Phase 4) |

## Variables

- **TOPIC**: $ARGUMENTS
- **SKILL_DIR**: directory containing this SKILL.md
- **ENV_FILE**: SKILL_DIR/.env
- **CWD**: the current working directory (where Claude was launched)
- **COURSE_ROOT**: where this course lives — resolved per the rule below (defaults to CWD)
- **LEARNING_PATH**: optional central fallback root, loaded from ENV_FILE (see Bootstrap below)

### Course location (COURSE_ROOT)

`COURSE_ROOT` is the folder holding the course's `00-Plan.md`, `00-Progress.md` and `Modules/`.

- **Default — `COURSE_ROOT = CWD`.** The course is created in the folder where Claude was launched.
  - **Non-code subjects** → only the markdown tree is written there (run it from your notes vault
    and it lands in your notes vault, so you can revisit it anytime).
  - **Code subjects** (a programming language with runnable exercises: TS, JS, Rust, Go, Python,
    C, C++, Java, …) → the markdown tree **plus** a scaffolded language project (config +
    `Workspace/` + git) right next to it, so the course and its code are self-contained.
    Recommended flow: create a dedicated folder, `cd` into it, then run `/learning <language>`.
- **Fallback — `LEARNING_PATH/Learning - {TOPIC}`.** Used only when the user prefers central
  storage, or when resuming a course that already lives there.

## Bootstrap: Load Configuration

`COURSE_ROOT` defaults to `CWD` (see "Course location" above) — no configuration is required to
create a course in the current folder. `LEARNING_PATH` is only the **optional central fallback**
used for the Phase 0 listing and for users who want a single shared location.

Resolve `LEARNING_PATH` (non-blocking):

1. **Read** `ENV_FILE` (i.e., `SKILL_DIR/.env`)
2. **If** it contains a non-empty `LEARNING_PATH=` value → set `LEARNING_PATH` (strip quotes).
3. **If absent/empty** → leave `LEARNING_PATH` unset. Do **not** prompt for it here; only ask
   (and offer to persist it to `ENV_FILE`) if the user explicitly chooses central storage over
   the current folder in Phase 1.

**`.env` format example:**
```
LEARNING_PATH=~/Documents/obsidian-vault/Projects
```

## Argument Routing

| Argument | Action |
|----------|--------|
| *(empty / no argument)* | List active learning plans and let the user pick one to resume |
| `self-update` | Read cookbook/self-update.md and execute |
| *any topic* | Run the full learning plan workflow below |

**If $ARGUMENTS is empty or not provided**: Jump to **Phase 0: List & Resume** below. Skip all other phases.

If $ARGUMENTS is "self-update", read **cookbook/self-update.md** and follow its instructions. Stop here.

## Instructions

- **CRITICAL**: Always run the assessment phase first — never skip it
- **CRITICAL**: All output files must be Obsidian-compatible markdown with YAML frontmatter
- **CRITICAL**: Present the plan and wait for user confirmation before writing to Obsidian
- **NEVER**: Generate more than 15 modules (completion drops significantly above 15)
- **NEVER**: Write full module content — modules contain outlines only (the tutor agent delivers content interactively)
- **ALWAYS**: Include estimated time per module
- **ALWAYS**: Use progressive difficulty (Foundation → Development → Mastery)
- **ALWAYS**: Detect tech vs non-tech automatically (try context7 first)

## Workflow

> Execute phases top to bottom. Pause for user confirmation at Phase 3.

---

### Phase 0: List & Resume (when no argument provided)

Scan for existing learning plans and let the user choose one to continue.

0. **Local course first**: if `CWD/00-Plan.md` exists, this folder *is* a course → set
   `COURSE_ROOT = CWD` and **start tutoring directly** (read `SKILL_DIR/TUTOR.md`, read
   `CWD/00-Progress.md` to find the next uncompleted module, teach it). **Stop here** — skip the
   central scan below.

1. **Scan** for all `Learning - *` directories in LEARNING_PATH/ (only if `LEARNING_PATH` is set):
   ```
   # Primary: find plans with 00-Plan.md
   Glob pattern: LEARNING_PATH/Learning - */00-Plan.md
   # Fallback: also find directories matching the naming pattern (may lack 00-Plan.md)
   Bash: ls -d LEARNING_PATH/Learning\ -\ */
   ```
   Use the union of both results to catch incomplete plans too.

2. **For each plan found**, read its `00-Progress.md` to extract:
   - Topic name (from frontmatter or folder name)
   - Status (Not Started / In Progress / Completed)
   - Completion count (e.g., "3/10 modules")
   - Last session date
   - If `00-Progress.md` does not exist, mark as **Not Started** with 0 modules completed

3. **Filter**: Only show plans with Status != "Completed" (unless there are no active plans, then show all)

4. **Present** the list via `AskUserQuestion`:
   - Each option shows: `{Topic} — {completion} modules — last session: {date}`
   - Add a final option: "Créer un nouveau plan" / "Create a new plan"

5. **Based on user choice**:
   - If they pick an existing plan → **start tutoring directly**:
     1. Set `COURSE_ROOT` to the selected plan's directory
     2. Read `SKILL_DIR/TUTOR.md` for tutor instructions
     3. Read the selected plan's `00-Progress.md` to find the next uncompleted module
     4. Read the module outline from `Modules/{NN}-{slug}.md`
     5. Follow the tutor instructions to teach the module interactively
     6. **Stop here** — do NOT continue to Phase 1
   - If they pick "Create a new plan" → ask for a topic via `AskUserQuestion`, set TOPIC, then continue to Phase 1

---

### Phase 1: Assessment (Interactive)

Read `ASSESSMENT.md` for rubric templates and calibration questions.

1. Determine the **domain type** of TOPIC:
   - Try context7 `resolve-library-id` for TOPIC
   - If found → **tech** domain (language, framework, tool, library)
   - If not found → **non-tech** domain (creative, theoretical, practical)
   - Store as DOMAIN_TYPE

1b. **Classify course type and confirm location**:
   - **Code course?** If DOMAIN_TYPE is tech AND TOPIC is a programming language / runtime whose
     exercises produce runnable code (TS, JS, Rust, Go, Python, C, C++, Java, Kotlin, Swift, …)
     → `CODE_COURSE = true`; otherwise `CODE_COURSE = false`.
   - **Confirm `COURSE_ROOT`** via `AskUserQuestion`:
     - If `CODE_COURSE`: "Set up this course as a self-contained project in the current folder
       `{CWD}`? (recommended) — or store it centrally?" If `CWD` already contains unrelated files,
       warn and offer a subfolder (e.g. `{CWD}/learn-{slug}`).
     - If not a code course: default `COURSE_ROOT = CWD` silently (markdown lands where Claude was
       launched); only ask if the current folder seems wrong.
   - If the user picks central storage and `LEARNING_PATH` is unset, ask for it now, persist it to
     `ENV_FILE` as `LEARNING_PATH=<answer>`, and set `COURSE_ROOT = LEARNING_PATH/Learning - {TOPIC}`.
   - For code courses, set `LANGUAGE` (the topic) and `WORKSPACE` (default `src`). The concrete
     toolchain — init command, config files, idiomatic layout, run command, type-check/build
     command, `.gitignore` essentials — is **not assumed here**; it is gathered in Phase 2 research
     and applied in Phase 4. The skill stays language-agnostic.

2. Ask the user 3-5 calibration questions via `AskUserQuestion`:
   - **Q1**: Self-assessment on a 0-10 scale (with level descriptions from ASSESSMENT.md)
   - **Q2-Q3**: 2 targeted knowledge-check questions specific to the topic and domain type (from ASSESSMENT.md domain templates)
   - **Q4**: Learning goal — "What do you want to be able to DO with this knowledge?"
   - **Q5**: Time commitment — "How many hours per week can you dedicate?"

3. Score responses against the rubric in ASSESSMENT.md:
   - Normalize to 0-10 scale
   - Classify: Novice (0-2), Beginner (3-4), Intermediate (5-6), Advanced (7-8), Expert (9-10)
   - Store: LEVEL, GOALS, WEEKLY_HOURS

4. Categorize the goal:
   - "Get a job" → Portfolio projects, interview prep, breadth
   - "Build a project" → Depth in relevant areas, skip unnecessary theory
   - "Understand deeply" → Theory-heavy, papers, internals
   - "Quick start" → Minimal theory, maximum practice
   - "Fill gaps" → Targeted modules only, skip known areas

---

### Phase 2: Research (3 Parallel Subagents)

Launch 3 parallel Task subagents to research TOPIC. Each receives: TOPIC, LEVEL, GOALS, DOMAIN_TYPE.

**Agent 1 — Official Documentation** (read `prompts/research-docs.md`):
- If tech: use context7 MCP to query documentation (getting-started, core concepts, API reference)
- If non-tech: WebFetch the most authoritative reference site for the topic
- Fallback: WebSearch for "{TOPIC} official documentation"

**Agent 2 — Web Resources** (read `prompts/research-web.md`):
- WebSearch for best learning resources, tutorials, courses, videos, books
- Filter by recency (2025-2026 preferred) and authority
- Collect free and paid options

**Agent 3 — Learning Paths & Practice** (read `prompts/research-roadmap.md`):
- WebFetch learn-anything.xyz for curated learning paths
- WebSearch for exercises, project ideas, common mistakes, best practices
- Collect practice resources ranked by difficulty

**For code courses, also gather project-setup facts** (add to Agent 1's brief, or ask context7 /
WebSearch directly): the standard way to initialise a project in this language, its config
file(s), the idiomatic source layout, the command to run a single source file, the command to
type-check or build, the source file extension, and `.gitignore` essentials. These feed the
Phase 4 scaffolding so no language details are hard-coded in the skill.

Collect all results. Merge and deduplicate resources.

---

### Phase 3: Plan Design (User Confirmation Gate)

Read `PEDAGOGY.md` for methodology reference.

1. Based on LEVEL and GOALS, determine:
   - **Starting point** — skip what user already knows
   - **Module count** — 6 to 15, adjusted by topic scope and WEEKLY_HOURS
   - **Phase breakdown**:
     - **Foundation** (~30%): Core concepts, mental models, vocabulary
     - **Development** (~50%): Applied skills, guided practice
     - **Mastery** (~20%): Projects, teaching others (Feynman)

2. For each module, define:
   - Title and SMART objective
   - Phase (Foundation / Development / Mastery)
   - Estimated hours
   - Exercise type (from PEDAGOGY.md taxonomy)
   - Key resources (from Phase 2 research)
   - Theory points to cover (bullet list)
   - Interactive exercise description (what the tutor will do, not the full exercise content)

3. Present the plan to the user as a formatted table:

   ```
   ## Proposed Learning Plan: {TOPIC}

   **Level**: {LEVEL} | **Goal**: {GOALS} | **Pace**: {WEEKLY_HOURS}h/week
   **Estimated duration**: {total_hours}h over {weeks} weeks

   | # | Phase | Module | Objective | Hours | Exercise Type |
   |---|-------|--------|-----------|-------|---------------|
   | 1 | Foundation | ... | ... | 2h | Recall Quiz |
   | 2 | Foundation | ... | ... | 3h | Concept Map |
   | ... | | | | | |
   ```

4. **GATE**: Ask user for confirmation or adjustments via `AskUserQuestion`:
   - "Does this plan look good? Any modules to add, remove, or reorder?"
   - Apply requested changes

---

### Phase 4: Save the Course

Read `PLAN-FORMAT.md` for file templates.

1. Create the markdown tree at `COURSE_ROOT`:
   ```
   {COURSE_ROOT}/
   ├── 00-Plan.md
   ├── 00-Progress.md
   ├── Resources.md
   └── Modules/
       ├── 01-{slug}.md
       ├── 02-{slug}.md
       └── ...
   ```
   (For central storage, `COURSE_ROOT = LEARNING_PATH/Learning - {TOPIC}`.)

2. Write `00-Plan.md` — full plan with metadata (topic, level, goals, hours, module list).
   **For code courses**, also set the frontmatter fields: `Code-Course: true`, `Language`,
   `Workspace`, `Run-Command`, `Check-Command`.
3. Write `00-Progress.md` — progress tracker with checkboxes for each module and spaced repetition dates.
4. Write `Resources.md` — curated links organized by type (docs, tutorials, courses, exercises).
5. Write module outlines — one file per module with: objective, theory points, exercise
   description, resources. **For code courses**, include the "Exercise Workspace" section
   (see PLAN-FORMAT.md) pointing at `{WORKSPACE}/{NN}-{slug}/`.

6. **Code courses only — scaffold the project** in `COURSE_ROOT` (this runs here, on the skill's
   Opus session — the tutor never has to do the heavy setup). Use **only** the project-setup facts
   gathered in Phase 2 for this language — the skill itself stays language-agnostic:
   - Initialise the project with the language's standard tooling/init command and write its config
     file(s), as discovered in research. Prefer the user's package managers when relevant
     (their global preferences may favour one toolchain over another).
   - Create `{WORKSPACE}/` (default `src`) with one folder per module: `{WORKSPACE}/{NN}-{slug}/`,
     each containing a placeholder `exercise.{ext}` (a stub comment — the tutor fills the real
     exercise content when that module's exercise begins). Use the file extension from research.
   - `git init` if `COURSE_ROOT` is not already a git repo; add a `.gitignore` with the language's
     standard ignores (from research).
   - Write `README.md`: course title, how to resume (`cd {COURSE_ROOT} && claude`, then
     `@learning-tutor`), and the run/check commands.
   - Record the resolved `Language`, `Workspace`, `Run-Command`, `Check-Command` in `00-Plan.md`
     frontmatter so the tutor can compile/run the learner's work without re-researching.

---

### Phase 5: Launch Tutor

1. Report what was created:
   ```
   ## Learning Plan Created

   **Topic**: {TOPIC} | **Level**: {LEVEL}
   **Modules**: {N} across 3 phases | **Est. Duration**: {hours}h over {weeks} weeks
   **Files**: {COURSE_ROOT}/

   | Phase | Modules | Hours |
   |-------|---------|-------|
   | Foundation | N | Xh |
   | Development | N | Xh |
   | Mastery | N | Xh |
   ```

2. Ask the user: "Do you want to start learning now?"
   - If yes → **start tutoring directly in the current conversation** (do NOT spawn a subagent):
     1. Read the tutor instructions from `SKILL_DIR/TUTOR.md`
     2. Read `COURSE_ROOT/00-Progress.md` to find the next uncompleted module
     3. Read the module outline from `COURSE_ROOT/Modules/{NN}-{slug}.md`
     4. Follow the tutor instructions to teach the module interactively
     5. Use `AskUserQuestion` for comprehension checks and exercises
     6. Update progress files after each module
   - If no → tell user: "To resume later, use: `@learning-tutor {TOPIC}`"
