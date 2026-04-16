# Pi Extension Templates

Ready-to-use TypeScript extension templates for Pi Coding Agent. Save to `~/.pi/agent/extensions/` or `.pi/extensions/`.

## Agent Team Dispatcher

Orchestrate multiple specialist agents via a dispatch tool. Based on the agent-team.ts pattern.

```typescript
// agent-team.ts — Dispatcher pattern with grid dashboard
// Save to: ~/.pi/agent/extensions/agent-team.ts

import type { PiExtension } from "@mariozechner/pi-coding-agent";

const TEAMS: Record<string, string[]> = {
    "full":       ["planner", "builder", "reviewer", "scout"],
    "plan-build": ["planner", "builder"],
    "frontend":   ["planner", "builder", "stylist"],
    "review":     ["reviewer", "security"],
};

export default function agentTeam(pi: PiExtension) {
    const dispatched: Map<string, { agent: string; status: string; result?: string }> = new Map();

    // Register dispatch tool callable by LLM
    pi.registerTool({
        name: "dispatch_agent",
        description: "Dispatch a task to a specialist agent from the active team",
        parameters: Type.Object({
            agent: Type.String({ description: "Agent name from active team" }),
            task: Type.String({ description: "Task description" }),
            model: Type.Optional(Type.String({ description: "Model override" })),
        }),
        async execute(args) {
            const id = `${args.agent}-${Date.now()}`;
            dispatched.set(id, { agent: args.agent, status: "running" });
            updateDashboard();

            // Load agent prompt from .pi/agents/<name>.md
            const agentPrompt = await loadAgentPrompt(args.agent);

            // Spawn via bash (pi in print mode)
            const result = await pi.bash(
                `pi -p --json "${agentPrompt}\n\nTask: ${args.task}"`,
                { timeout: 300000 }
            );

            dispatched.set(id, { agent: args.agent, status: "done", result });
            updateDashboard();
            return { content: [{ type: "text", text: result }] };
        },
    });

    // Register team selection command
    pi.registerCommand({
        name: "team",
        description: "Select active agent team",
        async handler(args) {
            const teamName = args[0] || "full";
            const team = TEAMS[teamName];
            if (!team) {
                return `Unknown team. Available: ${Object.keys(TEAMS).join(", ")}`;
            }
            return `Active team: ${teamName} — ${team.join(", ")}`;
        },
    });

    // Grid dashboard widget
    function updateDashboard() {
        const rows = [...dispatched.values()].map(
            (d) => `${d.agent.padEnd(12)} ${d.status.padEnd(8)}`
        );
        pi.ui.setWidget("team-grid", rows.join("\n"), { position: "above" });
    }
}
```

## Sequential Pipeline (Agent Chain)

Chain agents in sequence where each step's output feeds the next.

```typescript
// agent-chain.ts — Sequential pipeline orchestrator
// Save to: ~/.pi/agent/extensions/agent-chain.ts

import type { PiExtension } from "@mariozechner/pi-coding-agent";

interface ChainStep {
    agent: string;
    model?: string;
    prompt?: string;
}

const WORKFLOWS: Record<string, ChainStep[]> = {
    "plan-build-review": [
        { agent: "planner", model: "anthropic/claude-opus-4-6" },
        { agent: "builder", model: "anthropic/claude-sonnet-4-6" },
        { agent: "reviewer", model: "anthropic/claude-sonnet-4-6" },
    ],
    "scout-flow": [
        { agent: "scout", model: "anthropic/claude-haiku-4-5" },
        { agent: "planner" },
        { agent: "builder" },
    ],
    "full-review": [
        { agent: "planner" },
        { agent: "builder" },
        { agent: "reviewer" },
        { agent: "security" },
    ],
};

export default function agentChain(pi: PiExtension) {
    pi.registerCommand({
        name: "chain",
        description: "Run a sequential agent pipeline",
        async handler(args) {
            const workflowName = args[0] || "plan-build-review";
            const originalPrompt = args.slice(1).join(" ");
            const workflow = WORKFLOWS[workflowName];

            if (!workflow) {
                return `Unknown workflow. Available: ${Object.keys(WORKFLOWS).join(", ")}`;
            }

            let input = originalPrompt;
            const results: string[] = [];

            for (const step of workflow) {
                pi.ui.setStatus(`Chain: ${step.agent}...`);

                const agentPrompt = await loadAgentPrompt(step.agent);
                const fullPrompt = agentPrompt
                    .replace("$INPUT", input)
                    .replace("$ORIGINAL", originalPrompt);

                const modelFlag = step.model ? `--model ${step.model}` : "";
                const result = await pi.bash(
                    `pi -p ${modelFlag} "${fullPrompt}"`,
                    { timeout: 300000 }
                );

                results.push(`## ${step.agent}\n${result}`);
                input = result; // Feed output to next step
            }

            pi.ui.setStatus("Chain complete");
            return results.join("\n\n---\n\n");
        },
    });
}
```

## Damage Control (Safety Auditor)

Intercept tool calls and enforce security rules.

```typescript
// damage-control.ts — Safety auditing via tool_call interception
// Save to: ~/.pi/agent/extensions/damage-control.ts

import type { PiExtension } from "@mariozechner/pi-coding-agent";

const DESTRUCTIVE_PATTERNS = [
    /rm\s+(-rf?|--recursive)\s/,
    /git\s+(reset\s+--hard|clean\s+-f|checkout\s+\.)/,
    /chmod\s+777/,
    /dd\s+.*of=/,
    /mkfs\./,
    />\s*\/dev\//,
];

const ASK_PATTERNS = [
    /git\s+(push|branch\s+-D|stash\s+drop)/,
    /npm\s+publish/,
    /docker\s+(rm|rmi|system\s+prune)/,
];

const ZERO_ACCESS_PATHS = [
    /\.ssh\//,
    /\.gnupg\//,
    /\.aws\//,
    /\.kube\//,
    /\.(pem|key|p12)$/,
];

export default function damageControl(pi: PiExtension) {
    pi.on("tool_call", async (event) => {
        if (event.tool !== "bash") return;

        const cmd = event.args?.command || "";

        // Block destructive commands
        for (const pattern of DESTRUCTIVE_PATTERNS) {
            if (pattern.test(cmd)) {
                pi.ui.notify(`BLOCKED: ${cmd}`, { type: "error" });
                pi.appendEntry({ type: "custom", data: { violation: cmd, action: "block" } });
                return { block: true, reason: `Destructive command blocked: ${cmd}` };
            }
        }

        // Ask for confirmation
        for (const pattern of ASK_PATTERNS) {
            if (pattern.test(cmd)) {
                const confirmed = await pi.ui.confirm(
                    `Allow potentially dangerous command?\n${cmd}`,
                    { timeout: 30000 }
                );
                if (!confirmed) {
                    return { block: true, reason: "User denied" };
                }
            }
        }
    });

    // Block file access to sensitive paths
    pi.on("tool_call", async (event) => {
        if (!["read", "write", "edit"].includes(event.tool)) return;

        const path = event.args?.path || event.args?.file_path || "";
        for (const pattern of ZERO_ACCESS_PATHS) {
            if (pattern.test(path)) {
                return { block: true, reason: `Access denied: ${path} (sensitive path)` };
            }
        }
    });
}
```

## Purpose Gate

Block all prompts until user declares session intent.

```typescript
// purpose-gate.ts — Force session intent declaration
// Save to: ~/.pi/agent/extensions/purpose-gate.ts

import type { PiExtension } from "@mariozechner/pi-coding-agent";

export default function purposeGate(pi: PiExtension) {
    let purpose: string | null = null;

    // Block input until purpose is set
    pi.on("input", async (event) => {
        if (purpose) return; // Already set

        // Check if this is the purpose declaration
        if (event.text.startsWith("/purpose ")) {
            purpose = event.text.replace("/purpose ", "").trim();
            pi.ui.setWidget("purpose", `Session: ${purpose}`, { position: "above" });
            pi.ui.notify(`Purpose set: ${purpose}`);
            return { block: true }; // Consume the command
        }

        // Block with instructions
        pi.ui.notify("Set session purpose first: /purpose <description>");
        return { block: true };
    });

    // Inject purpose into system prompt
    pi.on("before_agent_start", (event) => {
        if (purpose) {
            event.systemPrompt += `\n\nSession purpose: ${purpose}\nAll work must align with this purpose.`;
        }
    });

    pi.registerCommand({
        name: "purpose",
        description: "Set or change session purpose",
        async handler(args) {
            purpose = args.join(" ");
            pi.ui.setWidget("purpose", `Session: ${purpose}`, { position: "above" });
            return `Purpose updated: ${purpose}`;
        },
    });
}
```

## Meta-Agent (Pi Pi)

An agent that builds other agents using parallel research experts.

```typescript
// meta-agent.ts — Agent that generates agents
// Save to: ~/.pi/agent/extensions/meta-agent.ts

import type { PiExtension } from "@mariozechner/pi-coding-agent";

const EXPERTS = ["ext-expert", "skill-expert", "config-expert", "prompt-expert"];

export default function metaAgent(pi: PiExtension) {
    pi.registerCommand({
        name: "build-agent",
        description: "Build a new Pi agent using parallel research experts",
        async handler(args) {
            const description = args.join(" ");
            if (!description) return "Usage: /build-agent <description of agent to build>";

            pi.ui.setStatus("Researching...");
            const research: Record<string, string> = {};

            // Launch parallel research
            const promises = EXPERTS.map(async (expert) => {
                const prompt = `Research what a Pi agent for "${description}" needs from your expertise area.`;
                const result = await pi.bash(
                    `pi -p --model anthropic/claude-haiku-4-5 "${prompt}"`,
                    { timeout: 120000 }
                );
                research[expert] = result;
                pi.ui.setWidget(
                    "meta-progress",
                    EXPERTS.map((e) =>
                        `${e.padEnd(16)} ${research[e] ? "done" : "..."}`
                    ).join("\n"),
                    { position: "above" }
                );
            });

            await Promise.all(promises);
            pi.ui.setStatus("Generating agent...");

            // Return research for the main agent to synthesize into an agent file
            return [
                `## Research Results for: ${description}`,
                ...Object.entries(research).map(
                    ([expert, result]) => `### ${expert}\n${result}`
                ),
                "",
                "## Instructions",
                "Based on the research above, generate a complete agent markdown file with:",
                "- YAML frontmatter (name, description, tools)",
                "- Purpose section",
                "- Instructions section",
                "- Output format section",
                `Save to .pi/agents/<name>.md`,
            ].join("\n\n");
        },
    });
}
```
