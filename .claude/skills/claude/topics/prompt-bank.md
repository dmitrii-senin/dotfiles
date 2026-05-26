# Prompt Topic Bank
Updated: 2026-05-26

## beginner

### Specificity and precision
Write prompts that eliminate ambiguity — scope the task, name the file, specify the format.
**Tip:** Compare "fix this" vs "fix the null check on line 42 of auth.ts by adding an early return"
**Drill:** Rewrite 3 vague prompts into specific, actionable ones
**Tags:** specificity, clarity, basics

### Constraints and guardrails
Use negative constraints ("do not X"), output format specs, and length limits to control output.
**Tip:** "Do NOT add comments. Do NOT refactor surrounding code. Change only the return type."
**Drill:** Add constraints to an unconstrained prompt that produces too-broad output
**Tags:** constraints, negative-constraints, format, length

### One task per prompt
Break compound requests into sequential single-task prompts for better results.
**Tip:** "Fix the bug AND refactor AND add tests" → 3 separate prompts, each building on the last
**Drill:** Decompose a compound prompt into 3 focused prompts
**Tags:** decomposition, focus, sequential

### Naming things for Claude
Use descriptive file names, function names, and variable names in your prompts — Claude uses them.
**Tip:** "Update the handler" vs "Update the `processPayment` handler in `src/api/payments.ts`"
**Drill:** Rewrite a prompt that uses pronouns/vague references to use specific identifiers
**Tags:** naming, identifiers, clarity

### Stating the output format
Tell Claude exactly what format you want: diff, bullet list, table, JSON, code block, etc.
**Tip:** "Respond with ONLY the modified function, no explanation" vs letting Claude decide
**Drill:** Write format constraints for 3 different output types
**Tags:** format, output, structure

### Giving context about your codebase
Front-load essential context: language, framework, architecture pattern, file structure.
**Tip:** CLAUDE.md is where persistent context lives — don't repeat it every prompt
**Drill:** Write a CLAUDE.md section that gives Claude the right codebase context in under 10 lines
**Tags:** context, CLAUDE.md, codebase

### Asking for explanations at the right level
Calibrate explanation depth: "explain like I'm a senior engineer" vs "explain the concept from scratch."
**Tip:** Claude defaults to verbose. "One paragraph max" or "answer in one sentence" is powerful.
**Drill:** Write 3 versions of the same question at different expertise levels
**Tags:** explanation, depth, calibration

### Prompting for code review
Frame review requests with specific criteria: security, performance, correctness, style.
**Tip:** "Review for SQL injection vulnerabilities only" beats "review this code"
**Drill:** Write a code review prompt with 3 specific criteria and an output format
**Tags:** review, criteria, focus

## intermediate

### Role-framing and persona
When and how to use role instructions — and when they hurt more than help.
**Tip:** "You are a security auditor" focuses attention; "You are a helpful assistant" wastes tokens
**Drill:** Write role frames for 3 different tasks and evaluate which ones actually improve output
**Tags:** role, persona, framing

### Few-shot examples
Provide input/output examples to calibrate Claude's style, format, and edge-case handling.
**Tip:** One good example > 10 lines of description. Show the shape of what you want.
**Drill:** Add a few-shot example to a prompt that's producing inconsistent output format
**Tags:** few-shot, examples, calibration

### Chain-of-thought elicitation
When and how to ask Claude to think step-by-step — and when it's unnecessary overhead.
**Tip:** "Think through this step by step before answering" helps for logic; wastes tokens for simple lookups
**Drill:** Identify which of 5 prompts would benefit from chain-of-thought and which wouldn't
**Tags:** chain-of-thought, reasoning, thinking

### Iterative refinement
Use follow-up prompts to steer Claude's output rather than trying to get it perfect in one shot.
**Tip:** "Good, but make the error messages more specific" is faster than rewriting the whole prompt
**Drill:** Start with a basic prompt, then write 3 refinement follow-ups
**Tags:** iteration, refinement, follow-up

### Context window awareness
Structure prompts knowing that context has limits — put important info early, trim irrelevant content.
**Tip:** Claude reads your whole conversation. A 50-turn session with old irrelevant context degrades quality.
**Drill:** Audit a long prompt and identify what can be trimmed without losing meaning
**Tags:** context, window, efficiency

### Prompting for multi-file changes
Structure requests that span multiple files: be explicit about which files and what changes in each.
**Tip:** "In `auth.ts`, change X. In `types.ts`, add Y. In `test.ts`, add a test for Z."
**Drill:** Write a multi-file change prompt for a feature that touches 3 files
**Tags:** multi-file, structure, changes

### Negative examples (what NOT to do)
Show Claude examples of bad output to steer it away from common failure modes.
**Tip:** "Do NOT generate output like this: [bad example]. Instead: [good example]."
**Drill:** Write a prompt with a negative example that prevents a specific failure mode
**Tags:** negative-examples, anti-patterns, steering

### Prompting for debugging
Give Claude the right signals: error message, stack trace, what you already tried, expected vs actual.
**Tip:** "Here's the error, here's what I tried, here's what I expected" — this triple is golden
**Drill:** Write a debugging prompt with all 3 signals for a hypothetical bug
**Tags:** debugging, error, diagnosis

### Using Claude Code's plan mode effectively
When to enter plan mode vs just asking — and how to frame the planning request.
**Tip:** Plan mode for architecture decisions; direct prompts for implementation. Don't plan trivial changes.
**Drill:** Decide plan-or-direct for 5 different tasks and explain why
**Tags:** plan-mode, planning, strategy

## advanced

### Multi-turn context steering
Manage a long conversation's context to keep Claude focused as the topic evolves.
**Tip:** Periodically restate the goal: "Remember, we're trying to X. Now let's handle Y."
**Drill:** Write 3 context-steering interjections for a drifting conversation
**Tags:** multi-turn, context, steering

### Prompting for architectural decisions
Frame "should we use X or Y?" questions with constraints, tradeoffs, and decision criteria.
**Tip:** "Given our constraints (team of 3, ship in 2 weeks, 10k users), which approach is better and why?"
**Drill:** Write an architecture-decision prompt with 3 explicit constraints
**Tags:** architecture, decisions, tradeoffs

### Meta-prompting: prompts that generate prompts
Use Claude to help you write better prompts — bootstrapping prompt quality.
**Tip:** "I want to prompt Claude to do X. Write me a prompt that would produce the best result."
**Drill:** Write a meta-prompt, evaluate the generated prompt, then improve it
**Tags:** meta-prompting, bootstrapping, quality

### Prompting across model tiers
Adjust prompt style for Opus vs Sonnet vs Haiku — different models need different levels of detail.
**Tip:** Opus handles ambiguity well; Haiku needs explicit, structured prompts with clear constraints
**Drill:** Adapt one prompt for Opus (loose) and Haiku (tight) and explain the differences
**Tags:** models, tiers, adaptation

### Prompt compression
Achieve the same result with fewer tokens — every token costs money and context space.
**Tip:** "List files modified in the last commit" is better than "Can you please show me which files were..."
**Drill:** Compress 3 verbose prompts to half their length without losing meaning
**Tags:** compression, tokens, efficiency

### Recovering from bad outputs
When Claude goes off track: techniques for redirecting without starting over.
**Tip:** "Stop. Discard the above. Let me restate: ..." is better than arguing with wrong output
**Drill:** Write 3 recovery prompts for common failure modes (wrong file, wrong approach, too verbose)
**Tags:** recovery, redirect, failure-modes

### Prompting for test generation
Get Claude to write tests that actually test behavior, not just assert that code runs.
**Tip:** "Write tests that verify the BEHAVIOR, not the implementation. Test edge cases: empty input, null, max size."
**Drill:** Write a test-generation prompt that produces meaningful tests for a given function signature
**Tags:** testing, test-generation, behavior

### System prompt design for CLAUDE.md
Design CLAUDE.md content that maximizes Claude's effectiveness without wasting context.
**Tip:** Rules that apply always go in CLAUDE.md. One-off instructions go in the prompt. Don't mix them.
**Drill:** Audit a CLAUDE.md and separate always-rules from one-off-instructions
**Tags:** CLAUDE.md, system-prompt, design

### Prompting for refactoring
Frame refactoring requests with explicit scope, constraints, and success criteria.
**Tip:** "Refactor for readability" is vague. "Extract the validation logic into a `validateInput()` function" is actionable.
**Drill:** Write a refactoring prompt with scope boundary, constraint, and success criterion
**Tags:** refactoring, scope, constraints
