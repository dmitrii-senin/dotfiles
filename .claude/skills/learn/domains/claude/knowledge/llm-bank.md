# Mental Model Topic Bank
Updated: 2026-05-26

## beginner

### What is a token?
Understand tokenization — how text becomes numbers, why "4 characters ≠ 1 token."
**Tip:** "function" is 1 token. "processPaymentTransaction" might be 3-4. Code is denser than prose.
**Drill:** Estimate token counts for 5 different text snippets and check your intuition
**Tags:** tokens, tokenization, basics, counting

### The context window explained
What fits in a context window, what happens when it fills up, and why it matters.
**Tip:** Claude's context is like RAM — everything in the conversation is loaded. More context = slower, costlier.
**Drill:** Calculate whether a 2000-line file + 50 turns of conversation fits in a 200k-token window
**Tags:** context-window, capacity, limits, conversation

### How Claude reads your conversation
Understand the conversation structure: system prompt, user messages, assistant messages, tool results.
**Tip:** Claude sees EVERYTHING in the conversation — CLAUDE.md, skill content, all tool outputs, all your messages
**Drill:** Draw the message flow for a typical Claude Code interaction with 2 tool calls
**Tags:** conversation, structure, messages, flow

### What Claude can and cannot do
Mental model for Claude's capabilities: great at code, pattern matching, analysis. Bad at math, counting, real-time info.
**Tip:** Claude doesn't "run" code — it predicts output. For exact results, use the Bash tool.
**Drill:** Classify 5 tasks as "Claude alone" vs "Claude + tool" vs "tool alone"
**Tags:** capabilities, limitations, tools, mental-model

### Temperature and randomness
What temperature does and why Claude Code uses low temperature for code tasks.
**Tip:** Low temp = deterministic, consistent. High temp = creative, varied. Code wants low temp.
**Drill:** Decide the right temperature setting for 4 different tasks
**Tags:** temperature, randomness, determinism, creativity

### Models: Opus vs Sonnet vs Haiku
When to use each model — capability, speed, and cost tradeoffs.
**Tip:** Opus: complex reasoning, architecture. Sonnet: balanced everyday work. Haiku: simple tasks, fast iteration.
**Drill:** Match 5 tasks to the right model and explain the tradeoff
**Tags:** models, opus, sonnet, haiku, selection

## intermediate

### How attention works (practical version)
Enough about attention to make better decisions — not the math, the implications.
**Tip:** Claude pays more attention to recent messages and strongly worded instructions. Position matters.
**Drill:** Reorder a prompt to put critical instructions where Claude will weight them most
**Tags:** attention, positioning, weight, instructions

### Prompt caching and cost optimization
Understand how prompt caching works — cache hits reduce cost and latency.
**Tip:** Stable prefixes (CLAUDE.md, skill content) get cached. Changing the first message busts the cache.
**Drill:** Identify which parts of a Claude Code session are cache-friendly vs cache-busting
**Tags:** caching, cost, optimization, prefix

### Extended thinking
When Claude "thinks before responding" — how it improves complex reasoning and when to enable it.
**Tip:** Extended thinking helps for multi-step logic, debugging, and architecture. Overhead for simple tasks.
**Drill:** Identify 3 tasks that benefit from extended thinking and 3 that don't
**Tags:** thinking, reasoning, extended, complex

### How compaction works
What happens when context fills up — Claude summarizes prior messages to make room.
**Tip:** Skill content is re-attached after compaction (first 5000 tokens preserved). Conversation details may be lost.
**Drill:** Design a session structure that preserves critical info through compaction
**Tags:** compaction, summary, preservation, context

### Token economics: understanding costs
How much different operations cost — input vs output tokens, model pricing, batch vs real-time.
**Tip:** Output tokens cost 5x more than input tokens. Verbose Claude = expensive Claude.
**Drill:** Estimate the cost of 3 different Claude Code workflows (simple fix, code review, architecture session)
**Tags:** cost, pricing, tokens, economics

### Why Claude sometimes "hallucinates"
Understand confabulation — when Claude generates plausible but wrong information and how to mitigate it.
**Tip:** Claude confabulates most about: specific API signatures, file paths, recent events, numerical facts
**Drill:** Identify 3 prompts likely to cause confabulation and rewrite them to reduce risk
**Tags:** hallucination, confabulation, accuracy, mitigation

### Training data and knowledge cutoff
What Claude knows vs doesn't — training cutoff, code patterns, real-time information.
**Tip:** Claude knows patterns, not your specific codebase. It needs to READ your files to be accurate.
**Drill:** Classify 5 questions as "Claude knows from training" vs "needs to read files" vs "needs web search"
**Tags:** training, cutoff, knowledge, limitations

## advanced

### The system prompt hierarchy
How CLAUDE.md, skill content, tool instructions, and conversation interact — priority and override rules.
**Tip:** User instructions in CLAUDE.md override default behavior. Skill instructions override for the skill's scope.
**Drill:** Trace the instruction precedence for a conflicting rule in CLAUDE.md vs a skill
**Tags:** system-prompt, hierarchy, priority, override

### Designing for context efficiency
Minimize token usage while maximizing output quality — advanced prompt engineering.
**Tip:** Shorter CLAUDE.md + targeted skills > long CLAUDE.md that loads everything every session
**Drill:** Audit a CLAUDE.md and skill set for context efficiency, propose reductions
**Tags:** efficiency, context, optimization, token-budget

### How Claude processes code
Understanding how Claude "reads" code — pattern matching, AST-like understanding, limitations.
**Tip:** Claude understands code structure (functions, classes, types) better than raw text. Well-structured code = better responses.
**Drill:** Compare Claude's effectiveness on well-structured vs poorly-structured code samples
**Tags:** code-processing, patterns, structure, understanding

### Multimodal inputs: images and PDFs
When and how to use Claude's vision capabilities in Claude Code — screenshots, diagrams, PDFs.
**Tip:** Claude can read screenshots of UIs, diagrams, error messages. Use Read tool on image files.
**Drill:** Identify 3 development tasks where sending a screenshot is more effective than describing the issue
**Tags:** multimodal, images, pdf, vision, screenshots

### Fine-tuning your mental model over time
Build intuition for when Claude will struggle vs excel — a meta-skill.
**Tip:** Track your "surprise rate" — when Claude's output surprises you, update your mental model
**Drill:** Reflect on 3 recent Claude Code sessions and identify where your expectations were wrong
**Tags:** meta, intuition, mental-model, learning, calibration
