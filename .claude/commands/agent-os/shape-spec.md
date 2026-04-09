# Shape Spec

Gather context and structure planning for significant work. **Run this command while in plan mode.**

## Important Guidelines

- **Always use AskUserQuestion tool** when asking the user anything
- **Offer suggestions** — Present options the user can confirm, adjust, or correct
- **Keep it lightweight** — This is shaping, not exhaustive documentation
- **Commit after each task** — Once a task is successfully completed, commit. One commit per task. Single line: task title + key files touched, e.g. `Set up Introduction module infrastructure: MODULE.md, index.yml and CLAUDE.md update`.

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

### Step 7: Structure the Plan

Now build the plan with **Task 1 always being "Save spec documentation"**.

Present this structure to the user:

```
Here's the plan structure. Task 1 saves all our shaping work before implementation begins.

---

## Task 1: Save Spec Documentation

Create `agent-os/specs/{folder-name}/` with:

- **plan.md** — This full plan (including BDD requirements and acceptance criteria per task)
- **shape.md** — Shaping notes (scope, decisions, context from our conversation)
- **standards.md** — Relevant standards that apply to this work
- **references.md** — Pointers to reference implementations studied
- **visuals/** — Any mockups or screenshots provided

## Task 2: [First implementation task]

[Description based on the feature]

## Task 3: [Next task]

...

---

Does this plan structure look right? I'll define BDD requirements and acceptance criteria for each task next.
```

### Step 8: Define BDD Requirements & Acceptance Criteria

**This step is mandatory. Every implementation task (Task 2 onward) MUST have BDD requirements and acceptance criteria before the plan is considered complete.**

For each implementation task, draft the BDD requirements and acceptance criteria directly in the plan. Do not stop to ask the user for confirmation task-by-task. The user will review and edit the finalized plan afterward if needed.

If a task cannot be specified confidently because the behavior, constraint, or expected outcome is unclear, do not interrupt the flow to ask immediately. Instead, mark the relevant BDD requirement or acceptance criterion with `[NEEDS CLARIFICATION]` so the user can review those exact points in the finalized plan.

#### 8a. Write BDD Requirements

Use **Given / When / Then** format. Focus on the core behaviors that define the user or business outcome this task must deliver.

```gherkin
### Requirement: [Behavior Name]

Given [precondition or initial state]
When [action the user or system takes]
Then [expected observable outcome]
```

**Rules for BDD requirements:**
- Start with the **primary user outcome** this task must deliver
- Add **key boundary conditions** only where they materially affect behavior, scope, or UX
- Add **failure handling** only where it materially affects trust, correctness, or delivery risk
- Use domain language and observable outcomes, not implementation details ("the user sees a loading indicator" not "isLoading state is set to true")
- Keep each requirement focused on one behavior — don't combine unrelated behaviors
- Do not try to model every edge case in BDD; capture the scenarios that shape the solution
- If an important behavior is ambiguous, mark that requirement with `[NEEDS CLARIFICATION]` instead of guessing

#### 8b. Write Acceptance Criteria

A checklist of specific, testable conditions that must ALL be true for the task to be considered complete.

```markdown
### Acceptance Criteria

- [ ] [Specific, observable, testable criterion]
- [ ] [Another criterion]
- [ ] [Boundary condition, if material]
- [ ] [Failure handling, if material]
```

**Rules for acceptance criteria:**
- Write only the criteria needed to make the task unambiguous and testable
- Most tasks will need **3-7 criteria**; use fewer for narrowly scoped tasks and more for high-risk or user-facing flows
- Every criterion must describe an observable outcome for a user, operator, or dependent system
- Include boundary conditions and failure handling when they materially affect behavior, trust, or delivery risk
- Each criterion must be independently verifiable
- Criteria should map naturally to test cases (unit, integration, or UI)
- Do NOT include implementation details — describe WHAT must be true, not HOW it is built
- Avoid padding the list with obvious or low-value checks just to reach a count
- If a criterion would not change design, implementation, or testing decisions, leave it out
- If a criterion depends on unresolved product or UX decisions, mark it with `[NEEDS CLARIFICATION]`

#### 8c. Complete each task definition before moving on

For each task, finish the full BDD + AC definition before starting the next one.

**IMPORTANT:** Do NOT ask the user for confirmation after each task. Do NOT batch unfinished placeholders across all tasks. Each task should be fully written with:
- A short task description
- Complete BDD requirements covering the primary outcome plus any material boundary conditions or failure handling
- A complete acceptance criteria checklist

The review loop happens only after the entire plan is assembled.

Use `[NEEDS CLARIFICATION]` inline anywhere the plan cannot be completed confidently without product input.

#### 8d. Example — Full task with BDD and AC

```markdown
## Task 3: Implement Songs Screen Search

Build the search bar and paginated results list on the Home screen.

### Requirement: Search by text input

Given the user is on the Songs Screen
When they type a search term and submit
Then a paginated list of matching songs is displayed

### Requirement: Paginated loading

Given search results are displayed
When the user scrolls to the bottom of the current results
Then the next page of results is fetched and appended

### Requirement: Empty search results

Given the user is on the Songs Screen
When they search for a term with no matching results
Then an empty state message is displayed

### Requirement: Search network failure

Given the user is on the Songs Screen
When they search and the network request fails
Then an error state is displayed with a retry option

### Requirement: Search result ranking [NEEDS CLARIFICATION]

Given the user submits a search
When matching songs are returned
Then results are ordered according to the agreed ranking logic [NEEDS CLARIFICATION: relevance, popularity, or exact match first]

### Acceptance Criteria

- [ ] A submitted search shows results that match the entered term
- [ ] Results display song name, artist, and album artwork
- [ ] Pagination loads the next batch when scrolling near the bottom
- [ ] Empty state is shown when API returns zero results
- [ ] Error state is shown on network failure with a retry action
- [ ] Loading indicator is visible during the first search request
- [ ] If the user submits a new search before the previous one completes, the screen updates to the latest submitted search results
- [ ] Long song and artist names remain readable without breaking the layout
- [ ] [NEEDS CLARIFICATION] Search results are ordered according to the agreed ranking logic
```

### Step 9: Complete the Plan

After all tasks have defined BDD requirements and acceptance criteria, assemble the full plan.

The plan should include:
- All tasks with their descriptions
- All BDD requirements per task
- All acceptance criteria per task
- Notes from reference implementations (Step 3)
- Notes from standards (Step 5)

Each task should be specific and actionable.

### Step 10: Ready for Execution

When the full plan is ready:

```
Plan complete with BDD requirements and acceptance criteria for all tasks.

When you approve and execute:

1. Task 1 will save all spec documentation first
2. Then all implementation tasks will proceed, following their acceptance criteria
3. After the production code for those acceptance criteria is ready, test the behavior defined by the same plan
4. Testing must cover the primary case and the relevant error cases
5. Each task's acceptance criteria define "done"

Ready to start? (approve / adjust)
```

## Output Structure

The spec folder will contain:

```
agent-os/specs/{YYYY-MM-DD-HHMM-feature-slug}/
├── plan.md           # Full plan with BDD requirements and AC per task
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

## Task 1: Save Spec Documentation

[Standard task 1 content]

## Task 2: {Task Name}

{Description}

### Requirement: {Behavior Name}

Given {precondition}
When {action}
Then {outcome}

### Requirement: {Behavior Name}

Given {precondition}
When {action}
Then {outcome}

### Acceptance Criteria

- [ ] {Criterion}
- [ ] {Criterion}
- [ ] {Boundary condition, if material}
- [ ] {Failure handling, if material}

## Task 3: {Task Name}

[Same structure as Task 2]

...
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
- **BDD covers behavior, not implementation** — Write requirements in user/domain language. How to implement and test is governed by standards.
- **Tests stay in the same plan, but come after implementation** — First implement all planned production code to satisfy the acceptance criteria. Then test the defined behavior, covering the primary case and the relevant error cases.
