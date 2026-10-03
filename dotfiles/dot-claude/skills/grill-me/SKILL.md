---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree one question at a time. Use proactively while in plan mode and before finalizing or presenting any implementation plan, design, or architecture decision — and whenever the user wants to stress-test a plan, get grilled on their design, or says "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Map the plan as a **design tree**: every decision branches into the decisions that hang off it. For each question, provide your recommended answer.

Ask the questions one at a time. Only ask a question whose prerequisites are already settled — never one whose answer depends on another decision still open. After each answer, re-evaluate which decisions have become askable and pick the next one from those.

Finding **facts** is your job, never mine. If a question can be answered from the environment (codebase, files, tools, docs), look it up instead of asking — dispatch a sub-agent for anything non-trivial. Don't block on it: while an exploration runs, only the questions downstream of it wait; keep asking the ones that don't depend on it. The **decisions** are mine: put each one to me and wait. Never answer a decision yourself.

The session is done when no branch is left open and nothing has been silently assumed. Do not act on the plan until I confirm we have reached a shared understanding.
