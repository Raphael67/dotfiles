# Knowledge Assessment Reference

Read this file during Phase 1 (Assessment) to calibrate the user's knowledge level and categorize their learning goals.

## Self-Assessment Scale

Ask the user to rate themselves on this scale:

| Score | Level | Description |
|-------|-------|-------------|
| 0-1 | Novice | Never heard of it, or only know the name |
| 2-3 | Beginner | Read about it, maybe watched a video or tried a basic tutorial |
| 4-5 | Intermediate | Built something small, comfortable with core concepts |
| 6-7 | Advanced | Used in real projects, understands trade-offs and alternatives |
| 8-9 | Expert | Deep knowledge, could teach it, knows internals and edge cases |
| 10 | Master | Industry authority, contributes to the field |

## Calibration Questions by Domain

### Tech: Programming Language

1. "Can you write a function that takes arguments and returns a value in {TOPIC}?"
2. "What's one key feature or concept that makes {TOPIC} different from other languages?"
3. "Have you built anything with {TOPIC}? If so, describe the most complex thing you've made."

### Tech: Framework / Library

1. "Do you know what core problem {TOPIC} solves?"
2. "Can you describe its main architectural pattern or philosophy?"
3. "Have you built a project with it? How complex was it (toy project, side project, production)?"

### Tech: Tool / Platform

1. "Have you installed and configured {TOPIC}?"
2. "Describe your typical workflow with {TOPIC} — what commands or features do you use most?"
3. "Do you know its main alternatives and when you'd choose {TOPIC} over them?"

### Tech: Concept / Architecture

1. "Can you explain {TOPIC} in one sentence?"
2. "Give a real-world example where {TOPIC} applies."
3. "Do you know when {TOPIC} is NOT the right approach?"

### Non-Tech: Creative (photo, music, design, writing)

1. "What tools or equipment do you currently use for {TOPIC}?"
2. "Can you describe your current skill level — what can you create today?"
3. "Show or describe something you've made that you're proud of (or wish you could make)."

### Non-Tech: Theoretical (math, physics, philosophy, finance)

1. "Can you explain the core concept of {TOPIC} in simple terms?"
2. "Can you solve a basic problem in this domain? (Provide an example problem.)"
3. "What aspects of {TOPIC} do you already feel comfortable with?"

### Non-Tech: Practical (cooking, gardening, fitness, crafts)

1. "What's your current practice with {TOPIC}? How often do you do it?"
2. "What tools or materials do you currently work with?"
3. "What results do you typically get? What frustrates you?"

## Scoring Rubric

For each calibration question response:

| Response Quality | Points |
|-----------------|--------|
| No answer / "I don't know" | 0 |
| Vague or partially correct | 1 |
| Correct with gaps | 2 |
| Correct and specific | 3 |
| Correct with nuance, examples, and trade-offs | 4 |

**Normalized score**: Total points / (number of questions x 4) x 10

Combine with self-assessment: **Final level = (self-assessment + normalized score) / 2**

## Goal Categorization

| Goal Type | Indicator Phrases | Plan Emphasis |
|-----------|-------------------|---------------|
| Career | "get a job", "interview", "resume" | Portfolio projects, breadth, interview prep modules |
| Project | "build X", "create X", "make X" | Depth in relevant areas, skip unneeded theory |
| Deep Understanding | "understand how", "how does X work", "internals" | Theory-heavy, academic resources, papers |
| Quick Start | "get started", "basics", "enough to use" | Minimal theory, maximum hands-on, skip advanced |
| Fill Gaps | "already know X but not Y", "improve at" | Targeted modules only, skip known areas |
| Hobby | "for fun", "interested in", "curious about" | Balanced theory/practice, fun projects, no pressure |

## Assessment Output

After assessment, produce this summary for use in later phases:

```
LEVEL: {Novice|Beginner|Intermediate|Advanced|Expert}
LEVEL_SCORE: {0-10}
DOMAIN_TYPE: {tech|non-tech}
GOALS: {free text from user}
GOAL_TYPE: {Career|Project|Deep Understanding|Quick Start|Fill Gaps|Hobby}
WEEKLY_HOURS: {N}
KNOWN_AREAS: {list of concepts/skills user already knows}
GAP_AREAS: {list of concepts/skills user needs to learn}
```
