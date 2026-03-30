# Plan Format Reference

Templates for the Obsidian files generated in Phase 4. All files use YAML frontmatter and Obsidian wiki-links.

## Directory Structure

```
Learning - {TOPIC}/
├── 00-Plan.md              # Full plan with metadata
├── 00-Progress.md          # Progress tracker with checkboxes
├── Resources.md            # Curated links from research
└── Modules/
    ├── 01-{slug}.md        # Module outlines (NOT full content)
    ├── 02-{slug}.md
    └── ...
```

## 00-Plan.md Template

```markdown
---
Type: Learning Plan
Topic: {TOPIC}
Level: {LEVEL}
Level-Score: {0-10}
Domain: {tech|non-tech}
Goals: {GOALS}
Goal-Type: {Career|Project|Deep Understanding|Quick Start|Fill Gaps|Hobby}
Weekly-Hours: {N}
Total-Hours: {estimated total}
Total-Modules: {N}
Created: {YYYY-MM-DD}
Status: Not Started
tags: [learning, {topic-slug}]
---

# Learning Plan: {TOPIC}

**Level**: {LEVEL} ({LEVEL_SCORE}/10) | **Goal**: {GOALS}
**Pace**: {WEEKLY_HOURS}h/week | **Duration**: ~{total_hours}h over {weeks} weeks

## Assessment Summary

- **Known areas**: {list}
- **Gap areas**: {list}
- **Starting point**: Module {N}

## Plan Overview

### Phase 1: Foundation ({N} modules, {X}h)

| # | Module | Objective | Hours | Exercise |
|---|--------|-----------|-------|----------|
| 1 | [[Modules/01-{slug}|{title}]] | {SMART objective} | {N}h | {type} |
| 2 | [[Modules/02-{slug}|{title}]] | {SMART objective} | {N}h | {type} |

### Phase 2: Development ({N} modules, {X}h)

| # | Module | Objective | Hours | Exercise |
|---|--------|-----------|-------|----------|
| 3 | [[Modules/03-{slug}|{title}]] | {SMART objective} | {N}h | {type} |
| ... | | | | |

### Phase 3: Mastery ({N} modules, {X}h)

| # | Module | Objective | Hours | Exercise |
|---|--------|-----------|-------|----------|
| N | [[Modules/{N}-{slug}|{title}]] | {SMART objective} | {N}h | {type} |

## How to Use This Plan

1. Start the interactive tutor: `@learning-tutor {TOPIC}`
2. The tutor reads this plan and guides you through each module
3. Progress is tracked in [[00-Progress]]
4. You can resume at any time — the tutor picks up where you left off
```

## 00-Progress.md Template

```markdown
---
Type: Progress Tracker
Topic: {TOPIC}
Created: {YYYY-MM-DD}
Last-Updated: {YYYY-MM-DD}
Status: Not Started
tags: [learning, {topic-slug}, progress]
---

# Progress: {TOPIC}

**Started**: — | **Last Session**: — | **Completion**: 0/{N} modules

## Module Progress

### Foundation
- [ ] Module 01: {title} — ⏱ {N}h — Score: —/10 — Date: —
- [ ] Module 02: {title} — ⏱ {N}h — Score: —/10 — Date: —

### Development
- [ ] Module 03: {title} — ⏱ {N}h — Score: —/10 — Date: —
- [ ] ...

### Mastery
- [ ] Module {N}: {title} — ⏱ {N}h — Score: —/10 — Date: —

## Spaced Repetition Schedule

| Module | Completed | Day 1 | Day 3 | Day 7 | Day 14 | Day 30 |
|--------|-----------|-------|-------|-------|--------|--------|
| 01 | — | — | — | — | — | — |
| 02 | — | — | — | — | — | — |
| ... | | | | | | |

## Session Log

| Date | Module | Duration | Score | Notes |
|------|--------|----------|-------|-------|
| — | — | — | — | — |
```

## Module Outline Template (Modules/{NN}-{slug}.md)

```markdown
---
Type: Learning Module
Topic: {TOPIC}
Phase: {Foundation|Development|Mastery}
Module: {N} of {Total}
Created: {YYYY-MM-DD}
Status: Not Started
Estimated-Hours: {N}
Exercise-Type: {type}
tags: [learning, {topic-slug}, {phase-slug}]
---

# Module {N}: {Title}

## Objective

{SMART objective — specific, measurable, achievable, relevant, time-bound}

**Estimated time**: {N}h
**Prerequisites**: [[{previous-module}]] (or "None" for first module)

## Theory Points

Key concepts the tutor should cover interactively:

1. **{Concept 1}**: {Brief description of what to explain}
2. **{Concept 2}**: {Brief description}
3. **{Concept 3}**: {Brief description}

## Key Resources

- {Resource 1 — title + URL}
- {Resource 2 — title + URL}
- {Resource 3 — title + URL}

## Interactive Exercise

**Type**: {Exercise type from taxonomy}
**Estimated duration**: {N} min

**Description**: {What the exercise involves — the tutor will deliver this interactively}

**Success criteria**: {How to know the exercise is completed successfully}

## Reflection Checklist

- [ ] I can explain {concept 1} in my own words
- [ ] I can explain {concept 2} in my own words
- [ ] I completed the exercise successfully
- [ ] I can apply this without looking at notes

## Session Notes

_(Filled by the tutor agent after interactive session)_
```

## Resources.md Template

```markdown
---
Type: Resource List
Topic: {TOPIC}
Created: {YYYY-MM-DD}
tags: [learning, {topic-slug}, resources]
---

# Resources: {TOPIC}

## Official Documentation
- {title} — {URL}

## Tutorials & Guides
- {title} — {URL} — {level} — {format: article/video/course}

## Books
- {title} — {author} — {level}

## Courses
- {title} — {platform} — {URL} — {free/paid}

## Practice & Exercises
- {title} — {URL} — {type: exercises/projects/challenges}

## Community
- {title} — {URL} — {type: subreddit/discord/forum}
```
