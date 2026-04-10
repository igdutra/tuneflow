# Shape Spec

Gather context and structure planning for significant work. **Run this command while in plan mode.**

## Important Guidelines

- **Always use AskUserQuestion tool** when asking the user anything
- **Offer suggestions** — Present options the user can confirm, adjust, or correct
- **Keep it lightweight** — This is shaping, not exhaustive documentation

## Prerequisites

This command **must be run in plan mode**.

**Before proceeding, check if you are currently in plan mode.**

If NOT in plan mode, **stop immediately** and tell the user:

```
Shape-spec must be run in plan mode. Please enter plan mode first, then run /shape-spec again.
```

Do not proceed with any steps below until confirmed to be in plan mode.

## Process

### Step 1: Clarify What We're Building

Use AskUserQuestion to understand the scope:

```
What are we building? Please describe the feature or change.

(Be as specific as you like — I'll ask follow-up questions if needed)
```

Based on their response, ask 1-2 clarifying questions if the scope is unclear. Examples:
- "Is this a new feature or a change to existing functionality?"
- "What's the expected outcome when this is done?"
- "Are there any constraints or requirements I should know about?"

### Step 2: Gather Visuals

Use AskUserQuestion:

```
Do you have any visuals to reference?

- Mockups or wireframes
- Screenshots of similar features
- Examples from other apps

(Paste images, share file paths, or say "none")
```

If visuals are provided, note them for inclusion in the spec folder.

### Step 3: Identify Reference Implementations

Use AskUserQuestion:

```
Is there similar code in this codebase I should reference?

Examples:
- "The comments feature is similar to what we're building"
- "Look at how src/features/notifications/ handles real-time updates"
- "No existing references"

(Point me to files, folders, or features to study)
```

If references are provided, read and analyze them to inform the plan.

### Step 4: Check Product Context

Check if `agent-os/product/` exists and contains files.

If it exists, read key files (like `mission.md`, `roadmap.md`, `tech-stack.md`) and use AskUserQuestion:

```
I found product context in agent-os/product/. Should this feature align with any specific product goals or constraints?

Key points from your product docs:
- [summarize relevant points]

(Confirm alignment or note any adjustments)
```

If no product folder exists, skip this step.

### Step 5: Surface Relevant Standards

Read `agent-os/standards/index.yml` to identify relevant standards based on the feature being built.

Use AskUserQuestion to confirm:

```
Based on what we're building, these standards may apply:

1. **api/response-format** — API response envelope structure
2. **api/error-handling** — Error codes and exception handling
3. **database/migrations** — Migration patterns

Should I include these in the spec? (yes / adjust: remove 3, add frontend/forms)
```

Read the confirmed standards files to include their content in the plan context.

### Step 6: Generate Spec Folder Name

Create a folder name using this format:
```
YYYY-MM-DD-HHMM-{feature-slug}/
```

Where:
- Date/time is current timestamp
- Feature slug is derived from the feature description (lowercase, hyphens, max 40 chars)

Example: `2026-01-15-1430-user-comment-system/`

**Note:** If `agent-os/specs/` doesn't exist, create it when saving the spec folder.

### Step 7: Write User-Facing Stories

**Before thinking about tasks or implementation, write ALL user-facing stories for the feature.**

Stories use **Given / When / Then** BDD format. They describe **what the user or system experiences** — never how the code implements it.

#### The discipline: stay at the user/domain level

Stories describe observable behavior. If you catch yourself writing type names, JSON shapes, error enum cases, protocol names, or implementation patterns in a story — STOP. That detail belongs in the Acceptance Criteria (Step 8), not here.

**Good story — user/domain language:**
```gherkin
### Story: Network failure on search

Given the user searches for songs
When the network is unavailable
Then the app shows an error with a retry option
```

**Bad story — leaked into tech spec:**
```gherkin
### Story: Handle invalid JSON

Given the API returns 200 with malformed JSON
When the response is decoded
Then `invalidData` is thrown
```

The bad example is a test case disguised as a story. The real story is "search fails gracefully." The JSON/decoding detail is an AC.

#### How to write stories

1. Start with the **primary user outcome** for this feature
2. Add **key user-facing variations**: empty states, error states, edge cases the user would notice
3. Add **system-level behaviors** only when they affect the user experience (e.g., "cached results are shown when offline")
4. Mark ambiguous stories with `[NEEDS CLARIFICATION]`

Number every story for cross-referencing in tasks:

```markdown
## Stories

### S1: Search songs by text

Given the user is on the Songs Screen
When they type a search term and submit
Then a list of matching songs is displayed

### S2: Paginated search results

Given search results are displayed
When the user scrolls to the bottom of the current results
Then the next page of results loads and appends

### S3: No results found

Given the user searches for a term
When no matching songs exist
Then an empty state message is displayed

### S4: Search fails due to network error

Given the user searches for songs
When the network is unavailable
Then an error state is shown with a retry option
```

**Rules:**
- Every story must describe something a user, QA tester, or product manager would recognize
- Infrastructure work (protocols, abstractions, mappers) does NOT get its own story — it exists to serve a story
- Keep the list focused. 4-10 stories per feature is typical. If you have 20+, the feature scope is too big — split it.

### Step 8: Write Acceptance Criteria

**After all stories are written, write the full Acceptance Criteria checklist for the feature.**

ACs are the technical contract. Unlike stories, ACs CAN and SHOULD include implementation details — type names, specific behaviors, boundary conditions, error cases. This is where "empty results returns `[]`, not an error" belongs.

#### How to write ACs

ACs are a flat checklist for the entire feature. They cover everything needed to consider the feature **done**: the happy paths from the stories, plus all the technical edge cases, boundary conditions, and infrastructure requirements that stories intentionally skip.

```markdown
## Acceptance Criteria

### Search & Pagination
- [ ] Search sends a request with query, limit, and offset parameters
- [ ] Results display song name, artist name, and album artwork
- [ ] Pagination appends the next batch when scrolling near the bottom
- [ ] Empty results returns an empty array, not an error
- [ ] A new search cancels any in-flight previous search

### Error Handling
- [ ] Network failure surfaces a connectivity error to the caller
- [ ] Non-200 HTTP status surfaces an invalid data error
- [ ] Malformed response body surfaces an invalid data error

### Infrastructure
- [ ] HTTP client abstraction is protocol-based and replaceable
- [ ] JSON-to-domain mapping happens at the network boundary
- [ ] Response DTOs are internal — never exposed to other modules
- [ ] Package compiles independently with `swift build`
```

**Rules:**
- Group ACs by theme for readability, but they are a single flat checklist
- Every AC must be independently verifiable
- ACs can be technical — they are the implementation contract
- Most features need **8-20 ACs**. Fewer means you're missing edge cases. More means the scope is too big.
- Tag each AC with `[NEEDS CLARIFICATION]` if it depends on unresolved decisions

### Step 9: Break Into Tasks

**Now that stories and ACs are defined, break the work into implementation tasks.**

Each task references which stories and ACs it delivers. Tasks are the execution plan — they define the order of work and what "done" looks like for each chunk.

#### Task structure

```markdown
## Tasks

### Task 1: Save Spec Documentation

Create `agent-os/specs/{folder-name}/` with:

- **plan.md** — This full plan
- **shape.md** — Shaping notes
- **standards.md** — Relevant standards
- **references.md** — Pointers to reference implementations
- **visuals/** — Any mockups or screenshots provided

### Task 2: {Task Name}

{Short description of what this task builds}

**Stories:** S1, S3
**ACs:** [list the specific ACs this task must satisfy]

### Task 3: {Task Name}

{Short description}

**Stories:** S2
**ACs:** [list ACs]

...

### Task N: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Flag any gaps.

**ACs:** All
```

**Rules:**
- Task 1 is always "Save Spec Documentation"
- The **last task** is always "Validate All ACs" — a dedicated pass to confirm nothing was missed
- Every story must be covered by at least one task
- Every AC must be covered by at least one task
- Tasks should be ordered by dependency (build foundations before features)
- Tests are NOT a separate task — each implementation task includes its tests
- Keep tasks focused: each task should be completable in one session

**IMPORTANT:** Do NOT duplicate the stories or ACs inside each task. Just reference them by number/name. The stories and ACs sections are the single source of truth. Tasks point to them.

#### How many tasks?

- Very small features: 3 tasks (save spec + 1 implementation + validate)
- Typical features: 4-7 tasks
- Large features: 7-10 tasks. If you need more, the feature should be split into multiple specs.

### Step 10: Assemble the Plan

After stories, ACs, and tasks are all written, assemble the full plan for review.

The plan should include:
- All stories (Step 7)
- All acceptance criteria (Step 8)
- All tasks with story/AC references (Step 9)
- Notes from reference implementations (Step 3)
- Notes from standards (Step 5)
- Add the important note at the top of the plan: "Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched, e.g. `Set up Introduction module infrastructure: MODULE.md, index.yml and CLAUDE.md update`."

Present the complete plan to the user for review.

### Step 11: Ready for Execution

When the full plan is ready:

```
Plan complete with stories, acceptance criteria, and tasks.

When you approve and execute:

1. Task 1 saves all spec documentation
2. Implementation tasks proceed in order, following their referenced ACs
3. Each task includes tests for the behaviors it implements
4. The final task validates that ALL acceptance criteria have been met
5. A story is "done" when all its referenced ACs pass

Ready to start? (approve / adjust)
```

## Output Structure

The spec folder will contain:

```
agent-os/specs/{YYYY-MM-DD-HHMM-feature-slug}/
├── plan.md           # Full plan: stories, ACs, tasks
├── shape.md          # Shaping decisions and context
├── standards.md      # Which standards apply and key points
├── references.md     # Pointers to similar code
└── visuals/          # Mockups, screenshots (if any)
```

## plan.md Content

The plan.md MUST follow this structure:

```markdown
# {Feature Name} — Plan

## Overview

[Brief description of what this plan covers]

**Standards applied:**

[References to applied standards]

---

## Stories

### S1: {Story Name}

Given {precondition}
When {action}
Then {observable outcome}

### S2: {Story Name}

Given {precondition}
When {action}
Then {observable outcome}

...

---

## Acceptance Criteria

### {Theme}
- [ ] {Criterion}
- [ ] {Criterion}

### {Theme}
- [ ] {Criterion}
- [ ] {Criterion}

---

## Tasks

### Task 1: Save Spec Documentation

Create `agent-os/specs/{folder-name}/` with plan.md, shape.md, standards.md, references.md.

### Task 2: {Task Name}

{Description}

**Stories:** S1, S3
**ACs:** {list}

### Task 3: {Task Name}

{Description}

**Stories:** S2
**ACs:** {list}

...

### Task N: Validate All ACs

Walk through every acceptance criterion and verify it has been implemented and tested. Flag any gaps.

**ACs:** All
```

## shape.md Content

The shape.md file should capture:

```markdown
# {Feature Name} — Shaping Notes

## Scope

[What we're building, from Step 1]

## Decisions

- [Key decisions made during shaping]
- [Constraints or requirements noted]

## Context

- **Visuals:** [List of visuals provided, or "None"]
- **References:** [Code references studied]
- **Product alignment:** [Notes from product context, or "N/A"]

## Standards Applied

- api/response-format — [why it applies]
- api/error-handling — [why it applies]
```

## standards.md Content

Include the full content of each relevant standard:

```markdown
# Standards for {Feature Name}

The following standards apply to this work.

---

## api/response-format

[Full content of the standard file]

---

## api/error-handling

[Full content of the standard file]
```

## references.md Content

```markdown
# References for {Feature Name}

## Similar Implementations

### {Reference 1 name}

- **Location:** `src/features/comments/`
- **Relevance:** [Why this is relevant]
- **Key patterns:** [What to borrow from this]

### {Reference 2 name}

...
```

## Tips

- **Keep shaping fast** — Don't over-document. Capture enough to start, refine as you build.
- **Visuals are optional** — Not every feature needs mockups.
- **Standards guide, not dictate** — They inform the plan but aren't always mandatory.
- **Specs are discoverable** — Months later, someone can find this spec and understand what was built and why.
- **Stories are for humans, ACs are the contract** — A PM reads stories. A developer reads ACs. Both are needed, and they serve different audiences.
- **Never duplicate** — Stories and ACs are written once. Tasks reference them. If you're copy-pasting a story into a task, you're doing it wrong.
- **Tests stay in the same task** — First implement production code to satisfy the ACs, then test the behavior. There is no separate "testing task."
- **The validation task catches drift** — By the time you reach the last task, some ACs may have been forgotten or partially implemented. The validation pass exists to catch that.
