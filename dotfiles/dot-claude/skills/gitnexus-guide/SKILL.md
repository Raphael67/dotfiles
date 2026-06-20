---
name: gitnexus-guide
description: "Use when the user asks what GitNexus is, when to use it (vs sem), what the web UI offers, or how the index/embeddings work. Conceptual reference for the manual human GitNexus setup. Examples: \"what is gitnexus for?\", \"should I use gitnexus or sem?\", \"what can the gitnexus UI show me?\"."
---

# GitNexus Guide — what it is and when to use it

GitNexus indexes a repository into a **knowledge graph** (symbols, call edges, execution
flows, Leiden clusters) and surfaces it through a **web UI, a wiki generator, and
architecture maps**. In this environment it is a **manual human tool**: there is no MCP
server, no autonomous agent use, and no "must run before editing" mandates. To *run* it, see
the `gitnexus-cli` skill (the `gnx` commands).

## When to use GitNexus vs `sem`

| Need | Use | Why |
| ---- | --- | --- |
| "What does *this change* break? What depends on this symbol?" | **`sem`** | Always-fresh (no index), zero-footprint, git-native, already in the pre-commit hook. |
| "Help me *understand / document* this codebase — search flows, browse the call graph, generate a wiki." | **GitNexus** (`gnx`) | Whole-repo graph, execution-flow tracing, a browsable UI, and wiki/architecture output `sem` doesn't have. |

Rule of thumb: **`sem` for per-change impact (agentic, fast), GitNexus for whole-system
exploration (manual, visual).**

## What the web UI gives you (`gnx serve` → http://127.0.0.1:4747)

- **Semantic + keyword search** across the graph — find execution flows by concept.
- **Symbol 360° view** — callers, callees, types, and which flows a symbol participates in.
- **Execution flows ("processes")** — step-by-step multi-file traces.
- **Clusters** — functional areas (Leiden community detection) with cohesion scores.
- **Architecture maps** — Mermaid diagrams of the structure.

## Advanced: terminal exploration (alternative to the UI)

The underlying `gitnexus` binary still exposes graph queries directly, if you prefer the
terminal over the web UI:

```bash
gitnexus query "auth flow"          # execution flows related to a concept
gitnexus context <symbolName>       # 360° view of a symbol
gitnexus impact <symbolName>        # blast radius of a symbol
gitnexus cypher '<query>'           # raw graph query (see graph schema below)
```

## How the index works

- **Storage:** one file per repo — `<repo>/.gitnexus/lbug` (LadybugDB: graph + full-text
  search + vector embeddings), gitignored. Plus parse caches for fast re-index.
- **Global state:** `~/.gitnexus/registry.json` (which repos are indexed) and
  `~/.config/gitnexus/config.json` (settings). No global embedding store.
- **Freshness:** indexes go stale as the repo changes — re-run `gnx index <path>` before
  browsing (idempotent; skips repos already current with git HEAD).
- **Embeddings:** local ONNX backend (384-dim), free, no API key. Pure shell/Terraform repos
  build structure-only (no embeddable content); `gnx index` handles that automatically.
- **Semantic search mode — exact-scan, not HNSW (known limitation):** GitNexus 1.6.7 cannot
  build the HNSW vector index — the `VECTOR` extension installs and loads fine, but
  `CREATE_VECTOR_INDEX(... metric := 'cosine')` throws an opaque native error, so semantic
  search always falls back to **exact-scan** (brute-force cosine, full accuracy). Exact-scan
  is capped at 10k chunks by default; `gnx` raises it to **50k** via
  `GITNEXUS_SEMANTIC_EXACT_SCAN_LIMIT` so even large repos (e.g. large repos with 20-30k symbols) get
  complete coverage. `doctor` shows `VECTOR index: available` / `Semantic mode: vector-index`,
  but that only means the *platform* is supported — not that HNSW actually builds. Revisit
  HNSW on a future GitNexus release; until then exact-scan is the working path.

## Graph schema (for `gitnexus cypher`)

**Nodes:** File, Function, Class, Interface, Method, Community, Process
**Edges (via `CodeRelation.type`):** CALLS, IMPORTS, EXTENDS, IMPLEMENTS, DEFINES, MEMBER_OF, STEP_IN_PROCESS

```cypher
MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f:Function {name: "myFunc"})
RETURN caller.name, caller.filePath
```
