# Learning Pedagogy Reference

Methodologies and techniques for designing effective learning plans. Read this file during Phase 3 (Plan Design) to choose appropriate module structures and exercise types.

## Learning Phases

### Foundation Phase (~30% of plan)

**Goal**: Build mental models, vocabulary, and conceptual understanding.

**Methods**:
- Reading official documentation and introductory material
- Watching explanatory videos or demonstrations
- Annotating and summarizing key concepts
- Drawing concept maps to visualize relationships

**Exercise types**: Recall Quiz, Concept Map, Explain-It (Feynman)

**Feynman check**: Can the learner explain this concept simply, without jargon?

### Development Phase (~50% of plan)

**Goal**: Apply knowledge to guided problems, build practical skills.

**Methods**:
- Following tutorials with modifications
- Guided projects with increasing autonomy
- Pair-style learning (agent demonstrates, user reproduces)
- Problem-solving with progressive hints

**Exercise types**: Code-Along, Mini-Project, Debug Challenge

**Feynman check**: Can the learner solve a novel problem using these concepts?

### Mastery Phase (~20% of plan)

**Goal**: Synthesize knowledge, create independently, and teach others.

**Methods**:
- Capstone projects (build from scratch)
- Teaching (write a tutorial, explain to someone)
- Contributing to real projects (open source, community)
- Exploring edge cases and advanced patterns

**Exercise types**: Capstone Project, Teach-Back, Code Review

**Feynman check**: Can the learner teach someone else this topic effectively?

## Exercise Taxonomy

| Type | Phase | Interactive Format | Duration |
|------|-------|--------------------|----------|
| Recall Quiz | Foundation | Agent asks questions, user answers in chat. Agent scores and explains. | 5-10 min |
| Concept Map | Foundation | User describes relationships between concepts. Agent validates and fills gaps. | 10-15 min |
| Explain-It (Feynman) | Foundation | User explains a concept in their own words. Agent evaluates clarity and corrects misconceptions. | 5-10 min |
| Code-Along | Development | Agent shows code/example, user reproduces then modifies. Agent reviews modifications. | 20-40 min |
| Mini-Project | Development | Agent gives a brief (requirements + constraints). User builds it. Agent reviews and suggests improvements. | 30-60 min |
| Debug Challenge | Development | Agent provides broken code/setup. User finds and fixes bugs. Agent gives progressive hints if stuck. | 15-30 min |
| Capstone Project | Mastery | User designs and implements a real project. Agent acts as mentor (reviews, suggests, unblocks). | 2-4 hours |
| Teach-Back | Mastery | User writes a mini-tutorial or explains a concept as if teaching. Agent evaluates completeness and clarity. | 20-30 min |
| Code Review | Mastery | Agent provides real-world code. User reviews for quality, patterns, and improvements. Agent discusses trade-offs. | 15-30 min |

## Adaptive Difficulty

After each module, assess performance:

| Success Rate | Action |
|-------------|--------|
| > 90% | Suggest skipping ahead or adding complexity to next module |
| 70-90% | On track — continue to next module normally |
| 50-70% | Add reinforcement exercises before advancing |
| < 50% | Revisit previous module concepts, add scaffolding |

**Signals to monitor**:
- Exercise completion rate
- Quality of Feynman explanations (can they teach it?)
- Time taken vs estimated time
- User's self-reported confidence

## Spaced Repetition Schedule

After completing a module, schedule reviews at these intervals:

| Interval | Review Type | Duration |
|----------|-------------|----------|
| Day 1 | Quick recall — summarize from memory | 5 min |
| Day 3 | Practice exercise — solve a new problem | 15 min |
| Day 7 | Explain from memory — Feynman technique | 10 min |
| Day 14 | Apply to new context — transfer learning | 20 min |
| Day 30 | Teach someone — deepest processing | 30 min |

## SMART Objectives Template

Each module objective must be:

- **S**pecific: "Implement JWT authentication in a REST API" not "learn auth"
- **M**easurable: "Build a working CRUD app" not "understand databases"
- **A**chievable: Within the estimated time for the module
- **R**elevant: Builds on previous module, leads to next
- **T**ime-bound: "Complete in ~2 hours"

**Template**: "By the end of this module, the learner will be able to [verb] [specific outcome] as demonstrated by [measurable evidence]."

## The 10-Step Learning Process

Based on proven meta-learning research, structure plans around these cycles:

1. **Get the big picture** — Understand the full landscape before diving in
2. **Determine scope** — Time-box the learning to match available commitment
3. **Define success** — Create measurable, evaluable criteria upfront
4. **Find resources** — Gather official docs, tutorials, courses, community content
5. **Create a learning plan** — Map sequential progression A → B → Z
6. **Filter resources** — Keep only the most relevant to the plan
7. **Learn enough to get started** — Minimal theory before first hands-on
8. **Play around** — Experiment, break things, generate questions
9. **Learn enough to do something useful** — Deepen based on questions from step 8
10. **Teach** — Explain to others to reveal gaps and solidify understanding

## Non-Tech Adaptations

For non-technical topics, adapt exercise types:

| Tech Exercise | Non-Tech Equivalent |
|---------------|---------------------|
| Code-Along | Follow a demonstration step-by-step (recipe, technique, process) |
| Mini-Project | Create something small (a photo series, a short essay, a simple dish) |
| Debug Challenge | Find and fix errors in provided examples (bad composition, logical fallacy, recipe mistake) |
| Code Review | Critique existing work (analyze a photograph, review an argument, taste and evaluate) |
| Capstone Project | Create a complete work (portfolio piece, full essay, multi-course meal) |
